defmodule Kujira.TestHelpers do
  defmacro __using__(_) do
    quote do
      setup do
        {:ok, channel} =
          GRPC.Stub.connect("kujira.grpc.kjnodes.com", 11390,
            interceptors: [{GRPC.Logger.Client, level: :info}]
          )

        [channel: channel]
      end

      def load_tx(hash) do
        "./test/support/mocks/tx/#{hash}"
        |> File.read!()
        |> Base.decode64!()
        |> Cosmos.Tx.V1beta1.GetTxResponse.decode()
      end

      def load_block(height) do
        "./test/support/mocks/block/#{height}"
        |> File.read!()
        |> Base.decode64!()
        |> Cosmos.Base.Tendermint.V1beta1.Block.decode()
      end
    end
  end
end
