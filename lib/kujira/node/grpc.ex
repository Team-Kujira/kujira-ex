defmodule Kujira.Node.Grpc do
  @moduledoc """
  Stores a gRPC connection to chain core node
  """
  defmacro __using__(_opts) do
    quote do
      use Agent

      def start_link(config) do
        {:ok, channel} =
          GRPC.Stub.connect(config[:host], config[:port],
            interceptors: [{GRPC.Logger.Client, level: :debug}]
          )

        Agent.start_link(fn -> channel end, name: __MODULE__)
      end

      def channel() do
        Agent.get(__MODULE__, & &1)
      end
    end
  end
end
