defmodule Mix.Tasks.DumpTx do
  use Mix.Task

  def run([hash]) do
    Mix.Task.run("app.start")

    {:ok, channel} =
      GRPC.Stub.connect("kujira-grpc.polkachu.com", 11890,
        interceptors: [{GRPC.Logger.Client, level: :info}]
      )

    {:ok, res} =
      Cosmos.Tx.V1beta1.Service.Stub.get_tx(channel, %Cosmos.Tx.V1beta1.GetTxRequest{
        hash: hash
      })

    binary = Protobuf.Encoder.encode(res)
    string = Base.encode64(binary)
    File.write!("./test/support/mocks/tx/#{hash}", string)
  end
end
