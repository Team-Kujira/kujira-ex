defmodule Kujira.Invalidator do
  @moduledoc """
  A process that Kujira.Node runs, subscribed to new blocks and exceuting cache invalidations for all registered modules
  """

  defp execute(invalidations) do
    for i <- invalidations do
      case i do
        %{arguments: nil} ->
          Memoize.invalidate(i.module, i.function)

        i ->
          Memoize.invalidate(i.module, i.function, i.arguments)
      end
    end
  end
end

defmodule Kujira.Invalidation do
  @moduledoc """
  An invalidation requested by `Kujira.Invalidate.invalidations/1`
  """

  defstruct [:module, :function, :args]

  @type t :: %__MODULE__{module: module(), function: atom(), args: [any()] | nil}
end

defprotocol Kujira.Invalidate do
  @moduledoc """
  Specification for a module to be registered with Kujira.Invalidator

  N.B: This is blocked until the upgrade to Cosmos SDK 0.50, an the associated upgrade to Cometbft 0.38. Currently BlockResult is unavailable over gRPC and so block events can't be scanned for required invalidations
  """

  alias Cosmos.Base.Tendermint.V1beta1.Block

  @spec invalidations(Block.t()) :: Kujira.Invalidation.t()
  def invalidations(block)
end
