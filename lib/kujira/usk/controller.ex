defmodule Kujira.Usk.Controller do
  @moduledoc """
  A contract that owns the minting rights for USK, and whitelists individual contracts for USK minting

  ## Fields
  * `:address` - The address of the contract

  * `:owner` - The owner of the contract

  * `:token` - The token that this contract is the admin for (USK)

  * `:permitted` - Addresses permitted to mint USK via the controller
  """
  alias Kujira.Token

  defstruct [
    :address,
    :owner,
    :token,
    :permitted
  ]

  @type t :: %__MODULE__{
          address: String.t(),
          owner: String.t(),
          token: Token.t(),
          permitted: list(String.t())
        }

  @spec from_query(String.t(), map()) :: {:ok, __MODULE__.t()} | :error
  def from_query(address, %{
        "owner" => owner,
        "denom" => denom,
        "permitted" => permitted
      }) do
    {:ok,
     %__MODULE__{
       address: address,
       owner: owner,
       token: Token.from_denom(denom),
       permitted: permitted
     }}
  end
end
