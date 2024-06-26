defmodule Kujira.Oracle do
  @moduledoc """
  Utility functions for querying the on-chain oracle
  """

  alias Kujira.Oracle.Query.Stub
  alias Kujira.Oracle.QueryExchangeRateRequest
  alias Kujira.Oracle.QueryExchangeRateResponse
  alias Kujira.Oracle.QueryExchangeRatesRequest
  alias Kujira.Oracle.QueryExchangeRatesResponse

  @doc """
  Loads the price for a specfic price from the on-chain oracle
  """
  @spec load_price(GRPC.Channel.t(), any()) :: {:ok, Decimal.t()} | {:error, GRPC.RPCError.t()}
  def load_price(channel, denom) do
    Memoize.Cache.get_or_run(
      {__MODULE__, :load_price, [denom]},
      fn ->
        with {:ok, %QueryExchangeRateResponse{exchange_rate: exchange_rate}} <-
               Stub.exchange_rate(channel, QueryExchangeRateRequest.new(denom: denom)),
             {rate, ""} <- Decimal.parse(exchange_rate) do
          {:ok, Decimal.div(rate, Decimal.new(10 ** 18))}
        else
          err -> err
        end
      end
    )
  end

  @doc """
  Loads all prices from the on-chain oracle
  """
  @spec load_prices(GRPC.Channel.t()) :: {:ok, map()} | {:error, GRPC.RPCError.t()}
  def load_prices(channel) do
    Memoize.Cache.get_or_run(
      {__MODULE__, :load_prices, []},
      fn ->
        with {:ok, %QueryExchangeRatesResponse{exchange_rates: rates}} <-
               Stub.exchange_rates(channel, QueryExchangeRatesRequest.new()),
             {:ok, rates} <-
               Enum.reduce(rates, {:ok, %{}}, fn
                 el, {:ok, acc} ->
                   case Decimal.parse(el.amount) do
                     {dec, ""} ->
                       {:ok, Map.put(acc, el.denom, Decimal.div(dec, Decimal.new(10 ** 18)))}

                     _ ->
                       :error
                   end

                 _, err ->
                   err
               end) do
          {:ok, rates}
        else
          err -> err
        end
      end
    )
  end
end
