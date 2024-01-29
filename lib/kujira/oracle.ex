defmodule Kujira.Oracle do
  @moduledoc """
  Utility functions for querying the on-chain oracle
  """

  alias Kujira.Oracle.Query.Stub
  alias Kujira.Oracle.QueryExchangeRateRequest
  alias Kujira.Oracle.QueryExchangeRateResponse

  @spec load_price(GRPC.Channel.t(), any()) :: {:ok, Decimal.t()} | :error
  def load_price(channel, denom) do
    with {:ok, %QueryExchangeRateResponse{exchange_rate: exchange_rate}} <-
           Stub.exchange_rate(channel, QueryExchangeRateRequest.new(denom: denom)),
         {rate, ""} <- Decimal.parse(exchange_rate) do
      {:ok, Decimal.div(rate, Decimal.new(10 ** 18))}
    else
      _ ->
        :error
    end
  end
end
