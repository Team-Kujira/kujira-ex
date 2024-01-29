defmodule Kujira.Ghost.Vault do
  @moduledoc """
  We define a Market, as far as Orca is concerned, in order to be able to standardise
  and aggregate the health of the various markets that any given liquidation queue can liquidate

  ## Fields
  * `:address` - The address of the market

  * `:owner` - The owner of the market

  * `:deposit_token` - The token deposited into the vault to be lent

  * `:oracle_denom` - The denom string that is used to price the deposit token

  * `:receipt_token` - The token minted on deposit, that represents ownership of that deposit

  * `:debt_token` - The token minted and sent to a Market when borrowing, use as an accounting tool to accrue interest on debt

  * `:markets` - The whitelisted markets that are allowed to borrow from the Vault
  """

  alias Kujira.Token
  alias Kujira.Ghost.Market

  defstruct [
    :address,
    :owner,
    :deposit_token,
    :oracle_denom,
    :receipt_token,
    :debt_token,
    :markets
  ]

  @type t :: %__MODULE__{
          address: String.t(),
          owner: String.t(),
          deposit_token: Token.t(),
          oracle_denom: {:live, String.t()} | {:static, Decimal.t()},
          receipt_token: Token.t(),
          debt_token: Token.t(),
          markets: :not_loaded | list(Market.t())
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
       markets: :not_loaded
     }}
  end

  defp parse_oracle(%{"live" => live}), do: {:live, live}

  defp parse_oracle(%{"static" => static}) do
    {decimal, ""} = Decimal.parse(static)
    {:static, decimal}
  end
end
