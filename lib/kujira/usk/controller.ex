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

  @spec from_query(GRPC.Channel.t(), String.t(), map()) :: {:ok, __MODULE__.t()} | :error
  def from_query(channel, address, %{
        "owner" => owner,
        "denom" => denom,
        "permitted" => permitted
      }) do
    with {:ok, token} <- Token.from_denom(channel, denom) do
      {:ok,
       %__MODULE__{
         address: address,
         owner: owner,
         token: token,
         permitted: permitted
       }}
    end
  end
end
