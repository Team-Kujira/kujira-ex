defmodule Mix.Tasks.DumpBlock do
  use Mix.Task
  alias Cosmos.Base.Tendermint
  import Tendermint.V1beta1.Service.Stub

  def run([height]) do
    Mix.Task.run("app.start")

    {:ok, channel} =
      GRPC.Stub.connect("kujira-grpc.polkachu.com", 11890,
        interceptors: [{GRPC.Logger.Client, level: :info}]
      )

    {height, ""} = Integer.parse(height)

    {:ok, %{block: block}} =
      get_block_by_height(
        channel,
        Tendermint.V1beta1.GetBlockByHeightRequest.new(height: height)
      )

    binary = Protobuf.Encoder.encode(block)
    string = Base.encode64(binary)
    File.write!("./test/support/mocks/block/#{height}", string)
  end
end
