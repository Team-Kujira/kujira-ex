defmodule Kujira.Ghost.Market do
  @moduledoc """
  We define a Market, as far as Orca is concerned, in order to be able to standardise
  and aggregate the health of the various markets that any given liquidation queue can liquidate

  ## Fields
  * `:address` - The address of the market

  * `:owner` - The owner of the market

  * `:vault_address` - The address of Vault that the Market draws from

  * `:orca_address` - The address of the Orca Queue that is used to liquidate the collateral token

  * `:collateral_token` - The token used to back the loan

  * `:collateral_oracle_denom` - The denom string that is used to price the collateral token

  * `:max_ltv` - MAximum loan-to-value ratio of a position

  * `:full_liquidation_threshold` - The value of collateral (as priced by collateral oracle, 6dp), below which a position is 100% liquidated

  * `:partial_liquidation_target` - The target LTV when a position is partially liquidated

  * `:borrow_fee` - The amount of the borrowed asset retained as a fee when borrow amount is increased
  """

  alias Kujira.Token

  defstruct [
    :address,
    :owner,
    :vault_address,
    :orca_address,
    :collateral_token,
    :collateral_oracle_denom,
    :max_ltv,
    :full_liquidation_threshold,
    :partial_liquidation_target,
    :borrow_fee
  ]

  @type t :: %__MODULE__{
          address: String.t(),
          owner: String.t(),
          vault_address: String.t(),
          orca_address: String.t(),
          collateral_token: Token.t(),
          collateral_oracle_denom: String.t(),
          max_ltv: Decimal.t(),
          full_liquidation_threshold: integer(),
          partial_liquidation_target: Decimal.t(),
          borrow_fee: Decimal.t()
        }

  @spec from_config(String.t(), map()) :: {:ok, __MODULE__.t()} | :error
  def from_config(address, %{
        "owner" => owner,
        "vault_addr" => vault_addr,
        "orca_addr" => orca_addr,
        "collateral_denom" => collateral_denom,
        "collateral_oracle_denom" => collateral_oracle_denom,
        "max_ltv" => max_ltv,
        "full_liquidation_threshold" => full_liquidation_threshold,
        "partial_liquidation_target" => partial_liquidation_target,
        "borrow_fee" => borrow_fee
      }) do
    with {full_liquidation_threshold, ""} <- Integer.parse(full_liquidation_threshold),
         {max_ltv, ""} <- Decimal.parse(max_ltv),
         {borrow_fee, ""} <- Decimal.parse(borrow_fee),
         {partial_liquidation_target, ""} <- Decimal.parse(partial_liquidation_target) do
      {:ok,
       %__MODULE__{
         address: address,
         owner: owner,
         vault_address: vault_addr,
         orca_address: orca_addr,
         collateral_token: Token.from_denom(collateral_denom),
         collateral_oracle_denom: collateral_oracle_denom,
         max_ltv: max_ltv,
         full_liquidation_threshold: full_liquidation_threshold,
         partial_liquidation_target: partial_liquidation_target,
         borrow_fee: borrow_fee
       }}
    else
      _ ->
        :error
    end
  end
end