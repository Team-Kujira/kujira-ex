defmodule Kujira.TestHelpers do
  defmacro __using__(_) do
    quote do
      setup do
        {:ok, channel} =
          GRPC.Stub.connect("kujira-grpc.polkachu.com", 11890,
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
    end
  end
end
