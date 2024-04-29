defmodule Kujira.Bow.Pool do
  alias Kujira.Bow.Pool.Lsd
  alias Kujira.Bow.Pool.Stable
  alias Kujira.Bow.Pool.Xyk
  @type t :: Xyk.t() | Stable.t() | Lsd.t()

  @spec from_config(GRPC.Channel.t(), String.t(), map()) :: :error | {:ok, __MODULE__.t()}

  def from_config(
        channel,
        address,
        params
      ) do
    Enum.reduce([Xyk, Stable, Lsd], nil, fn
      _, {:ok, contract} -> {:ok, contract}
      v, _ -> v.from_config(channel, address, params)
    end)
  end
end
