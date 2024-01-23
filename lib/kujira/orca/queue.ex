defmodule Kujira.Orca.Queue do
  @moduledoc """
  An individual Orca Liquidation Queue

  ## Fields
  * `:address` - The contract address

  * `:owner` - The account authorized to make changes to contract config

  * `:collateral_token` - The token that is being liquidated

  * `:bid_token` - The token that is used to buy the collateral

  * `:bid_pools` - The aggregate amounts of bids at each supported discount amount. The contract confug contains `max_slot` and `premium_rate_per_slot`, which define these pools

  * `:activation_threshold` - The total amount of bids, above which the activation_delay must pass before a bid can be activated. This is `bid_threshold` on the contract interfaace

  * `:activation_delay` - The time in seconds that must pass before a bid can be activated. This is `waiting_period` on the contract interface
  """

  alias Kujira.Token
  alias Kujira.Orca.Pool

  defstruct [
    :address,
    :owner,
    :collateral_token,
    :bid_token,
    :bid_pools,
    :activation_threshold,
    :activation_delay,
    :liquidation_fee,
    :withdrawal_fee
  ]

  @type t :: %__MODULE__{
          address: String.t(),
          owner: String.t(),
          bid_token: Token.t(),
          bid_pools: list(Pool.t()),
          collateral_token: Token.t(),
          activation_threshold: integer(),
          activation_delay: integer(),
          liquidation_fee: Decimal.t(),
          withdrawal_fee: Decimal.t()
        }

  @spec from_config(String.t(), map()) :: {:ok, __MODULE__.t()} | :error
  def from_config(address, %{
        "bid_denom" => bid_denom,
        "bid_threshold" => bid_threshold,
        "closed_slots" => _closed_slots,
        "collateral_denom" => collateral_denom,
        "fee_address" => _fee_address,
        "liquidation_fee" => liquidation_fee,
        "markets" => _markets,
        "max_slot" => max_slot,
        "owner" => owner,
        "premium_rate_per_slot" => premium_rate_per_slot,
        "waiting_period" => waiting_period,
        "withdrawal_fee" => withdrawal_fee
      }) do
    with {activation_threshold, ""} <- Integer.parse(bid_threshold),
         {liquidation_fee, ""} <- Decimal.parse(liquidation_fee),
         {premium_rate_per_slot, ""} <- Decimal.parse(premium_rate_per_slot),
         {withdrawal_fee, ""} <- Decimal.parse(withdrawal_fee) do
      {:ok,
       %__MODULE__{
         address: address,
         owner: owner,
         collateral_token: Token.from_denom(collateral_denom),
         bid_token: Token.from_denom(bid_denom),
         bid_pools: [],
         activation_threshold: activation_threshold,
         activation_delay: waiting_period,
         liquidation_fee: liquidation_fee,
         withdrawal_fee: withdrawal_fee
       }
       |> populate_pools(max_slot, premium_rate_per_slot)}
    else
      _ ->
        :error
    end
  end

  @spec populate_pools(__MODULE__.t(), integer(), Decimal.t()) :: __MODULE__.t()
  def populate_pools(queue, max_slot, premium_rate_per_slot) do
    %{
      queue
      | bid_pools:
          0..max_slot
          |> Enum.to_list()
          |> Enum.map(&Pool.calculate(premium_rate_per_slot, &1))
    }
  end

  @spec load_pools(list(map()), __MODULE__.t()) :: __MODULE__.t()
  def load_pools(pools, queue) do
    %{
      queue
      | bid_pools:
          Enum.map(queue.bid_pools, fn pool ->
            pools
            |> Enum.find(
              &(&1["premium_rate"]
                |> Decimal.parse()
                |> elem(0)
                |> Decimal.eq?(pool.premium))
            )
            |> Pool.load(pool)
          end)
    }
  end
end
