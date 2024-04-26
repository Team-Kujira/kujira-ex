defmodule ChainRegistry do
  use Tesla
  use Memoize

  adapter(Tesla.Adapter.Hackney, recv_timeout: 30_000)

  plug(
    Tesla.Middleware.BaseUrl,
    "https://raw.githubusercontent.com/cosmos/chain-registry/master"
  )

  plug(Tesla.Middleware.JSON)

  defmemo chain_assets(chain), expires_in: 24 * 60 * 60 * 1000 do
    with {:ok, %{body: body}} <- get("/#{chain}/assetlist.json"),
         {:ok, res} <- Jason.decode(body) do
      {:ok, res}
    end
  end
end
