defmodule Kujira do
  @moduledoc """
  Documentation for `Kujira`.
  """

  import Cosmos.Tx.V1beta1.Service.Stub
  alias Cosmos.Tx.V1beta1.GetTxsEventRequest
  alias Cosmos.Tx.V1beta1.GetTxsEventResponse
  alias Cosmos.Base.Query.V1beta1.PageRequest
  alias Cosmos.Tx.V1beta1.OrderBy
  alias Cosmos.Tx.V1beta1.Tx

  @doc """
  Get transactions where the sender is `address`
  """

  @spec txs_by_sender(
          GRPC.Channel.t(),
          String.t(),
          keyword(
            pagination: PageRequest.t(),
            order_by: OrderBy.t(),
            page: number(),
            limit: number()
          )
        ) ::
          {:ok, GetTxsEventResponse} | {:error, GRPC.RPCError.t()}
  def txs_by_sender(channel, address, opts \\ []) do
    pagination = Keyword.get(opts, :pagination)
    order_by = Keyword.get(opts, :order_by)
    page = Keyword.get(opts, :page)
    limit = Keyword.get(opts, :limit)

    get_txs_event(
      channel,
      GetTxsEventRequest.new(
        events: ["message.sender='#{address}'"],
        pagination: pagination,
        order_by: order_by,
        page: page,
        limit: limit
      )
    )
  end

  @doc """
  Decodes an Any (eg sdk.Tx, PubKey etc to the Elixir defined type)
  """
  def decode_any(%Google.Protobuf.Any{
        type_url: type_url,
        value: value
      }) do
    module = to_module(type_url)
    module.decode(value)
  end

  defp to_module("/" <> type_url) do
    parts =
      type_url
      |> String.split(".")
      |> Enum.map(&capitalize/1)
      |> Enum.join(".")

    String.to_existing_atom("Elixir." <> parts)
  end

  defp capitalize(string) do
    with <<c::utf8, rest::binary>> <- string,
         do: String.upcase(<<c>>) <> rest
  end

  def tx_hash(%Tx{} = tx) do
    tx_hash(Tx.encode(tx))
  end

  def tx_hash(bytes) do
    Base.encode16(:crypto.hash(:sha256, bytes))
  end

  def decode_tx(tx) do
    with {:ok, json} <- Jason.decode(tx) do
      json
    else
      {:error, _} ->
        %Tx{body: %{messages: messages} = body} = tx = Tx.decode(tx)

        %{tx | body: %{body | messages: Enum.map(messages, &decode_any/1)}}
    end
  end
end
