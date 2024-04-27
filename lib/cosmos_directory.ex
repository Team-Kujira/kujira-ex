defmodule CosmosDirectory do
  use Tesla
  use Memoize

  adapter(Tesla.Adapter.Hackney, recv_timeout: 30_000)

  plug(
    Tesla.Middleware.BaseUrl,
    "https://chains.cosmos.directory"
  )

  plug(Tesla.Middleware.JSON)

  defmemo chain_name(chain_id) do
    with {:ok, %{body: %{"chains" => chains}}} <- get("/"),
         %{"chain_name" => chain_name} <-
           Enum.find(chains, &(&1["chain_id"] == chain_id)) do
      {:ok, chain_name}
    else
      nil -> {:error, :not_found}
      err -> err
    end
  end
end
