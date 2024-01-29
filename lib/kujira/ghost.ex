defmodule Kujira.Ghost do
  @moduledoc """
  Kujira's lending platform.

  It has a vault-market architecture, where multiple Market can draw down from a single Vault. A Market must be whitelisted,
  as the repayment is guaranteed by its own execution logic, e.g. being over-collateralised and having a connection to Orca
  to liquidate collateral when needed
  """

  use Memoize
  alias GRPC.Channel
  alias Kujira.Contract
  alias Kujira.Ghost.Market
  alias Kujira.Ghost.Vault

  @vault_code_ids Application.get_env(:kujira, __MODULE__, vault_code_ids: [140])
                  |> Keyword.get(:vault_code_ids)

  @market_code_ids Application.get_env(:kujira, __MODULE__, market_code_ids: [136, 186])
                   |> Keyword.get(:market_code_ids)

  @doc """
  Fetches the Market contract and its current config from the chain.

  Config is very very rarely changed, if ever, and so this function is Memoized by default.
  Clear with `Memoize.invalidate(Kujira.Ghost, :get_market, [address])`
  """

  @spec get_market(Channel.t(), String.t()) :: {:ok, Market.t()} | {:error, :not_found}
  def get_market(channel, address), do: Contract.get(channel, {Market, address})

  @doc """
  Fetches all Liquidation Markets. This will only change when config changes or new Markets are added.
  It's Memoized, clearing every 24h.

  Manually clear with `Memoize.invalidate(Kujira.Ghost, :list_markets)`
  """

  @spec list_markets(GRPC.Channel.t(), list(integer())) :: {:ok, list(Market.t())} | :error
  def list_markets(channel, code_ids \\ @market_code_ids) when is_list(code_ids),
    do: Contract.list(channel, Market, code_ids)

  @doc """
  Fetches the Vault contract and its current config from the chain.

  Config is very very rarely changed, if ever, and so this function is Memoized by default.
  Clear with `Memoize.invalidate(Kujira.Ghost, :get_vault, [address])`
  """

  @spec get_vault(Channel.t(), String.t()) :: {:ok, Vault.t()} | {:error, :not_found}
  def get_vault(channel, address), do: Contract.get(channel, {Vault, address})

  @doc """
  Fetches all Liquidation Vaults. This will only change when config changes or new Vaults are added.
  It's Memoized, clearing every 24h.

  Manually clear with `Memoize.invalidate(Kujira.Ghost, :list_vaults)`
  """

  @spec list_vaults(GRPC.Channel.t(), list(integer())) :: {:ok, list(Vault.t())} | :error
  def list_vaults(channel, code_ids \\ @vault_code_ids) when is_list(code_ids),
    do: Contract.list(channel, Vault, code_ids)
end
