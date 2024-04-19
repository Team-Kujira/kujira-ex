defmodule Kujira.Usk.Market do
  @moduledoc """
  A USK market taked deposits of collateral_token, and allows minting of USK, up to the maximum LTV as quoted by the oracle denoms

  ## Fields
  * `:address` - The address of the market

  * `:owner` - The owner of the market

  * `:stable_token` - The token that is minted

  * `:stable_token_admin` - The admin address of the stable_token

  * `:orca_address` - The address of the Orca Queue that is used to liquidate the collateral token

  * `:collateral_token` - The token used to back the loan

  * `:collateral_oracle_denom` - The denom string that is used to price the collateral token

  * `:max_ltv` - MAximum loan-to-value ratio of a position

  * `:full_liquidation_threshold` - The value of collateral (as priced by collateral oracle, 6dp), below which a position is 100% liquidated

  * `:liquidation_ratio` - The amount of a position liquidated when a position is partially liquidated

  * `:mint_fee` - The amount of the borrowed asset retained as a fee when borrow amount is increased

  * `:interest_rate` - The interest rate charged. Charged on the amount minted, paid in the collateral_token

  * `:max_debt` - Tha maximum amount of stable_token
  """

  defmodule Status do
    @moduledoc """
    The current mint total

    ## Fields
    * `:minted` - The amount of the stable_token minted
    """

    defstruct minted: 0

    @type t :: %__MODULE__{
            minted: integer()
          }

    @spec from_query(map()) :: :error | {:ok, __MODULE__.t()}
    def from_query(%{
          "debt_amount" => debt_amount
        }) do
      with {debt_amount, ""} <- Integer.parse(debt_amount) do
        {:ok, %__MODULE__{minted: debt_amount}}
      else
        _ ->
          :error
      end
    end
  end

  alias Kujira.Token
  alias Kujira.Orca.Queue

  defstruct [
    :address,
    :owner,
    :stable_token,
    :stable_token_admin,
    :orca_queue,
    :collateral_token,
    :collateral_oracle_denom,
    :max_ltv,
    :full_liquidation_threshold,
    :liquidation_ratio,
    :mint_fee,
    :max_debt,
    :interest_rate,
    :status
  ]

  @type t :: %__MODULE__{
          address: String.t(),
          owner: String.t(),
          stable_token: Token.t(),
          stable_token_admin: String.t(),
          orca_queue: {Queue, String.t()},
          collateral_token: Token.t(),
          collateral_oracle_denom: String.t(),
          max_ltv: Decimal.t(),
          full_liquidation_threshold: integer(),
          liquidation_ratio: Decimal.t(),
          mint_fee: Decimal.t(),
          interest_rate: Decimal.t(),
          max_debt: non_neg_integer(),
          status: :not_loaded | Status.t()
        }

  @spec from_config(String.t(), map()) :: {:ok, __MODULE__.t()} | :error
  def from_config(address, %{
        "owner" => owner,
        "stable_denom" => stable_token,
        "stable_denom_admin" => stable_token_admin,
        "orca_address" => orca_addr,
        "collateral_denom" => collateral_denom,
        "oracle_denom" => collateral_oracle_denom,
        "max_ratio" => max_ltv,
        "liquidation_threshold" => full_liquidation_threshold,
        "liquidation_ratio" => liquidation_ratio,
        "mint_fee" => mint_fee,
        "max_debt" => max_debt,
        "interest_rate" => interest_rate
      }) do
    with {full_liquidation_threshold, ""} <- Integer.parse(full_liquidation_threshold),
         {max_debt, ""} <- Integer.parse(max_debt),
         {max_ltv, ""} <- Decimal.parse(max_ltv),
         {interest_rate, ""} <- Decimal.parse(interest_rate),
         {mint_fee, ""} <- Decimal.parse(mint_fee),
         {liquidation_ratio, ""} <- Decimal.parse(liquidation_ratio) do
      {:ok,
       %__MODULE__{
         address: address,
         owner: owner,
         stable_token: Token.from_denom(stable_token),
         stable_token_admin: stable_token_admin,
         orca_queue: {Queue, orca_addr},
         collateral_token: Token.from_denom(collateral_denom),
         collateral_oracle_denom: collateral_oracle_denom,
         max_ltv: max_ltv,
         full_liquidation_threshold: full_liquidation_threshold,
         liquidation_ratio: liquidation_ratio,
         mint_fee: mint_fee,
         max_debt: max_debt,
         interest_rate: interest_rate,
         status: :not_loaded
       }}
    else
      _ ->
        :error
    end
  end
end
