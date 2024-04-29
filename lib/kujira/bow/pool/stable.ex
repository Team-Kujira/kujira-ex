defmodule Kujira.Bow.Pool.Stable do
  @moduledoc """
  A instance of the BOW Stable Market Making strategy.


  ## Fields
  * `:address` - The address of the contract

  * `:owner` - The owner of the contract

  * `:fin_pair` - The FIN Pair that this pool market-makes for

  * `:token_lp` - The receipt token minted when deposits are made to the pool

  * `:token_base` - The base token of the FIN Pair

  * `:token_quote` - The quote token of the FIN Pair

  * `:decimal_delta` - Base decimals - Quote decimals. Used to assert correct price_precision

  * `:price_precision` - Maximum number of decimal places of the human price when submitting orders
  """

  alias Kujira.Fin
  alias Kujira.Token
  alias Kujira.Bow.Status

  defstruct [
    :address,
    :owner,
    :fin_pair,
    :token_lp,
    :token_base,
    :token_quote,
    :decimal_delta,
    :price_precision,
    :strategy,
    :status
  ]

  @type t :: %__MODULE__{
          address: String.t(),
          owner: String.t(),
          fin_pair: {Fin.Pair, String.t()},
          token_lp: Token.t(),
          token_base: Token.t(),
          token_quote: Token.t(),
          decimal_delta: integer(),
          price_precision: integer(),
          strategy: __MODULE__.Strategy.t(),
          status: Status.t()
        }

  @spec from_config(GRPC.Channel.t(), String.t(), map()) ::
          {:error, GRPC.RPCError.t()} | {:error, :invalid_config} | {:ok, __MODULE__.t()}
  def from_config(channel, address, %{
        "owner" => owner,
        "denoms" => [
          denom_base,
          denom_quote
        ],
        "price_precision" => %{
          "decimal_places" => price_precision
        },
        "decimal_delta" => decimal_delta,
        "fin_contract" => fin_pair,
        "strategy" => strategy
      }) do
    with {:ok, token_base} <- Token.from_denom(channel, denom_base),
         {:ok, token_quote} <- Token.from_denom(channel, denom_quote),
         {:ok, token_lp} <- Token.from_denom(channel, "factory/#{address}/ulp"),
         {:ok, strategy} <- __MODULE__.Strategy.from_config(strategy) do
      {:ok,
       %__MODULE__{
         address: address,
         owner: owner,
         fin_pair: {Fin.Pair, fin_pair},
         token_lp: token_lp,
         token_base: token_base,
         token_quote: token_quote,
         decimal_delta: decimal_delta,
         price_precision: price_precision,
         strategy: strategy,
         status: :not_loaded
       }}
    else
      err ->
        err
    end
  end

  def from_config(_, _, _), do: {:error, :invalid_config}
end
