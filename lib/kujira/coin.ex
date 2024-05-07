defmodule Kujira.Coin do
  @moduledoc """
  A Kujira.Token with an associated amount
  """
  alias Kujira.Token

  @regex ~r'([0-9]+)([a-zA-Z][a-zA-Z0-9/:._-]{2,127})'
  # @regex_decimal_amount     ~r/[[:digit:]]+(?:\.[[:digit:]]+)?|\.[[:digit:]]+/

  defstruct [:token, :amount]

  @type t :: %__MODULE__{token: Token.t(), amount: integer()}

  @spec parse_coins(GRPC.Channel.t(), binary()) ::
          {:ok, [__MODULE__.t()]}
          | {:error, :invalid_denom}
          | {:error, :invalid_integer_amount}
          | {:error, GRPC.RPCError.t()}
  @doc """
  Parses an SDK coins string eg 100ukuji,200ibc/FFA3D0E9C3CDE729559FB71A09E9E6CFA5A85AFABAC9F3CB5DD3942BFF935F9C
  """
  def parse_coins(channel, string) do
    case string
         |> String.split(",")
         |> Task.async_stream(&parse_coin(channel, &1), timeout: :infinity)
         |> Enum.reduce(
           {:ok, []},
           fn
             {:ok, {:ok, coin}}, {:ok, acc} ->
               {:ok, add_coin(coin, acc)}

             {:ok, err}, _ ->
               err

             _, err ->
               err
           end
         ) do
      {:ok, coins} -> {:ok, normalize(coins)}
      err -> err
    end
  end

  @doc """
  Parses a single SDK coin string eg 100ukuji
  """
  @spec parse_coin(GRPC.Channel.t(), binary()) ::
          {:ok, __MODULE__.t()}
          | {:error, :invalid_denom}
          | {:error, :invalid_integer_amount}
          | {:error, GRPC.RPCError.t()}
  def parse_coin(channel, string) do
    with [[_, amount, denom]] <- Regex.scan(@regex, string),
         {amount, ""} <- Integer.parse(amount),
         {:ok, token} <- Token.from_denom(channel, denom) do
      {:ok, %__MODULE__{amount: amount, token: token}}
    else
      [] ->
        {:error, :invalid_denom}

      {_, _} ->
        {:error, :invalid_integer_amount}

      err ->
        err
    end
  end

  @doc """
  Adds a single Coin to a list of Coins, increasing the `amount` value if already present
  """
  @spec add_coin(__MODULE__.t(), [__MODULE__.t()]) :: [__MODULE__.t()]
  def add_coin(coin, coins) do
    case Enum.split_with(coins, &(&1.token.denom == coin.token.denom)) do
      {[existing], rest} ->
        [%{existing | amount: existing.amount + coin.amount} | rest]

      {[], all} ->
        [coin | all]
    end
  end

  @doc """
  Sorts the coins alphabetically by denom string
  """
  @spec normalize([__MODULE__.t()]) :: [__MODULE__.t()]
  def normalize(coins) do
    Enum.sort_by(coins, & &1.token.denom)
  end
end
