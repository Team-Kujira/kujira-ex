defmodule Kujira.Ghost.Market do
  @moduledoc """
  A Ghost market takes deposits of collateral_token, and allows borrowing of the vault.deposit_token, up to the maximum LTV as quoted by the oracle denoms

  ## Fields
  * `:address` - The address of the market

  * `:owner` - The owner of the market

  * `:vault` - The address of Vault that the Market draws from

  * `:orca_queue` - The address of the Orca Queue that is used to liquidate the collateral token

  * `:collateral_token` - The token used to back the loan

  * `:collateral_oracle_denom` - The denom string that is used to price the collateral token

  * `:max_ltv` - MAximum loan-to-value ratio of a position

  * `:full_liquidation_threshold` - The value of collateral (as priced by collateral oracle, 6dp), below which a position is 100% liquidated

  * `:partial_liquidation_target` - The target LTV when a position is partially liquidated

  * `:borrow_fee` - The amount of the borrowed asset retained as a fee when borrow amount is increased
  """

  defmodule Status do
    @moduledoc """
    The current deposit and borrow totals

    ## Fields
    * `:deposited` - The amount of collateral_token deposited

    * `:borrowed` - The amount of the Vault deposit_token borrowed


    """

    defstruct deposited: 0,
              borrowed: 0

    @type t :: %__MODULE__{
            deposited: integer(),
            borrowed: integer()
          }

    @spec from_query(map()) :: :error | {:ok, __MODULE__.t()}
    def from_query(%{
          "deposited" => deposited,
          "borrowed" => borrowed
        }) do
      with {deposited, ""} <- Integer.parse(deposited),
           {borrowed, ""} <- Integer.parse(borrowed) do
        {:ok, %__MODULE__{deposited: deposited, borrowed: borrowed}}
      else
        _ ->
          :error
      end
    end
  end

  alias Kujira.Token
  alias Kujira.Ghost.Vault
  alias Kujira.Orca.Queue

  defstruct [
    :address,
    :owner,
    :vault,
    :orca_queue,
    :collateral_token,
    :collateral_oracle_denom,
    :max_ltv,
    :full_liquidation_threshold,
    :partial_liquidation_target,
    :borrow_fee,
    :status
  ]

  @type t :: %__MODULE__{
          address: String.t(),
          owner: String.t(),
          vault: {Vault, String.t()},
          orca_queue: {Queue, String.t()},
          collateral_token: Token.t(),
          collateral_oracle_denom: String.t(),
          max_ltv: Decimal.t(),
          full_liquidation_threshold: integer(),
          partial_liquidation_target: Decimal.t(),
          borrow_fee: Decimal.t(),
          status: :not_loaded | Status.t()
        }

  @spec from_config(GRPC.Channel.t(), String.t(), map()) :: {:ok, __MODULE__.t()} | :error
  def from_config(channel, address, %{
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
         {partial_liquidation_target, ""} <- Decimal.parse(partial_liquidation_target),
         {:ok, collateral_token} <- Token.from_denom(channel, collateral_denom) do
      {:ok,
       %__MODULE__{
         address: address,
         owner: owner,
         vault: {Vault, vault_addr},
         orca_queue: {Queue, orca_addr},
         collateral_token: collateral_token,
         collateral_oracle_denom: collateral_oracle_denom,
         max_ltv: max_ltv,
         full_liquidation_threshold: full_liquidation_threshold,
         partial_liquidation_target: partial_liquidation_target,
         borrow_fee: borrow_fee,
         status: :not_loaded
       }}
    else
      _ ->
        :error
    end
  end
end
