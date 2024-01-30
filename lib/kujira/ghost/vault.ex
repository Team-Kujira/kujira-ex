defmodule Kujira.Ghost.Vault do
  @moduledoc """
  A central vault for deposits of a specific deposit_token, which is lent to the Vault's markets, and interest earned on deposits

  ## Fields
  * `:address` - The address of the market

  * `:owner` - The owner of the market

  * `:deposit_token` - The token deposited into the vault to be lent

  * `:oracle_denom` - The denom string that is used to price the deposit token

  * `:receipt_token` - The token minted on deposit, that represents ownership of that deposit

  * `:debt_token` - The token minted and sent to a Market when borrowing, use as an accounting tool to accrue interest on debt

  * `:markets` - The whitelisted markets that are allowed to borrow from the Vault
  """

  defmodule Status do
    @moduledoc """
    The current deposit and borrow totals

    ## Fields
    * `:deposited` - The amount of deposit_token deposited

    * `:borrowed` - The amount of the Vault deposit_token lent out

    * `:rate` - The current interest rate charged on lent tokens

    * `:deposit_ratio` - The ratio between deposit_token and receipt_token

    * `:debt_ratio` - The ratiop between the debt_token and the amount of deposit_token owed by the borrowing Market
    """

    defstruct deposited: 0,
              borrowed: 0,
              rate: Decimal.new(0),
              deposit_ratio: Decimal.new(0),
              debt_ratio: Decimal.new(0)

    @type t :: %__MODULE__{
            deposited: integer(),
            borrowed: integer(),
            rate: Decimal.t(),
            deposit_ratio: Decimal.t(),
            debt_ratio: Decimal.t()
          }

    @spec from_query(map()) :: :error | {:ok, __MODULE__.t()}
    def from_query(%{
          "deposited" => deposited,
          "borrowed" => borrowed,
          "rate" => rate,
          "deposit_redemption_ratio" => deposit_redemption_ratio,
          "debt_share_ratio" => debt_share_ratio
        }) do
      with {deposited, ""} <- Integer.parse(deposited),
           {borrowed, ""} <- Integer.parse(borrowed),
           {rate, ""} <- Decimal.parse(rate),
           {deposit_redemption_ratio, ""} <- Decimal.parse(deposit_redemption_ratio),
           {debt_share_ratio, ""} <- Decimal.parse(debt_share_ratio) do
        {:ok,
         %__MODULE__{
           deposited: deposited,
           borrowed: borrowed,
           rate: rate,
           deposit_ratio: deposit_redemption_ratio,
           debt_ratio: debt_share_ratio
         }}
      else
        _ ->
          :error
      end
    end
  end

  alias Kujira.Token
  alias Kujira.Ghost.Market

  defstruct [
    :address,
    :owner,
    :deposit_token,
    :oracle_denom,
    :receipt_token,
    :debt_token,
    :markets,
    :status
  ]

  @type t :: %__MODULE__{
          address: String.t(),
          owner: String.t(),
          deposit_token: Token.t(),
          oracle_denom: {:live, String.t()} | {:static, Decimal.t()},
          receipt_token: Token.t(),
          debt_token: Token.t(),
          markets: :not_loaded | list(Market.t()),
          status: :not_loaded | Status.t()
        }

  @spec from_config(String.t(), map()) :: {:ok, __MODULE__.t()} | :error
  def from_config(address, %{
        "owner" => owner,
        "denom" => denom,
        "oracle" => oracle,
        # "decimals" => decimals,
        "receipt_denom" => receipt_denom,
        "debt_token_denom" => debt_token_denom
      }) do
    {:ok,
     %__MODULE__{
       address: address,
       owner: owner,
       deposit_token: Token.from_denom(denom),
       receipt_token: Token.from_denom(receipt_denom),
       debt_token: Token.from_denom(debt_token_denom),
       oracle_denom: parse_oracle(oracle),
       markets: :not_loaded,
       status: :not_loaded
     }}
  end

  defp parse_oracle(%{"live" => live}), do: {:live, live}

  defp parse_oracle(%{"static" => static}) do
    {decimal, ""} = Decimal.parse(static)
    {:static, decimal}
  end
end
