defmodule Kujira.Bow.Pool.Lsd.Adapter do
  defmodule Contract do
    @moduledoc """
    An on-chain LSD strategy adapter, where the redemption rate can be directly read and where the pool can re-balance itself via the configured LSD provider
    """

    defstruct [
      :address,
      :bonding_threshold,
      :bonding_target,
      :unbonding_threshold,
      :unbonding_target
    ]

    @type t :: %__MODULE__{
            address: String.t(),
            bonding_threshold: Decimal.t(),
            bonding_target: Decimal.t(),
            unbonding_threshold: Decimal.t(),
            unbonding_target: Decimal.t()
          }

    @spec from_config(map()) ::
            {:error, :invalid_config} | {:ok, __MODULE__.t()}
    def from_config(%{
          "address" => address,
          "bonding_threshold" => bonding_threshold,
          "bonding_target" => bonding_target,
          "unbonding_threshold" => unbonding_threshold,
          "unbonding_target" => unbonding_target
        }) do
      with {bonding_threshold, ""} <- Decimal.parse(bonding_threshold),
           {bonding_target, ""} <- Decimal.parse(bonding_target),
           {unbonding_threshold, ""} <- Decimal.parse(unbonding_threshold),
           {unbonding_target, ""} <- Decimal.parse(unbonding_target) do
        {:ok,
         %__MODULE__{
           address: address,
           bonding_threshold: bonding_threshold,
           bonding_target: bonding_target,
           unbonding_threshold: unbonding_threshold,
           unbonding_target: unbonding_target
         }}
      else
        :error ->
          {:error, :invalid_config}
      end
    end

    def from_config(_), do: {:error, :invalid_config}
  end

  defmodule Oracle do
    @moduledoc """
    An off-chain LSD strategy adapter. Where the redemption rate is calculated by oracle prices, and an arbitrage incentive can be offered on the ask side of the book to rebalance to the quote side
    """

    defstruct [:base_oracle, :base_decimals, :quote_oracle, :quote_decimals]

    @type t :: %__MODULE__{
            base_oracle: String.t(),
            base_decimals: non_neg_integer(),
            quote_oracle: String.t(),
            quote_decimals: non_neg_integer()
          }

    @spec from_config([map()]) ::
            {:error, :invalid_config} | {:ok, __MODULE__.t()}
    def from_config([
          %{"denom" => base_oracle, "decimals" => base_decimals},
          %{"denom" => quote_oracle, "decimals" => quote_decimals}
        ]) do
      {:ok,
       %__MODULE__{
         base_oracle: base_oracle,
         base_decimals: base_decimals,
         quote_oracle: quote_oracle,
         quote_decimals: quote_decimals
       }}
    end
  end

  @type t :: __MODULE__.Contract.t() | __MODULE__.Oracle.t()

  @spec from_config(map()) ::
          {:error, :invalid_config} | {:ok, __MODULE__.t()}
  def from_config(%{
        "contract" => contract
      }) do
    __MODULE__.Contract.from_config(contract)
  end

  def from_config(%{
        "oracle" => oracle
      }) do
    __MODULE__.Oracle.from_config(oracle)
  end

  def from_config(_), do: {:error, :invalid_config}
end
