defmodule Kujira.Bow.Leverage do
  @moduledoc """
  A CDP contract that integrates BOW with GHOST, allowing LP tokens to be used as collateral when borrowing the underlying tokens
  that make up the LP position.

  This allows an LP-er to provide eg only the base asset of a pair, and borrow the stable quote-side of the position, in order to avoid having
  to sell any of their position in order to provide liquidity.

  ## Fields
  * `:address` - The address of the contract

  * `:owner` - The owner of the contract

  * `:bow` - The BOW contract that the liquidity is deposited to

  * `:token_base` - The base Token of the LP pair

  * `:token_quote` - The quote Token of the LP pair

  * `:oracle_base` - The Oracle feed used to price the base token

  * `:oracle_quote` - The Oracle feed used to price the quote token

  * `:ghost_vault_base` - The GHOST Vault where the base token is borrowed from

  * `:ghost_vault_quote` - The GHOST Vault where the quote token is borrowed from

  * `:orca_queue_base` - The ORCA Queue where the base token is liquidated to repay the GHOST quote Vault

  * `:orca_queue_quote` - The ORCA Queue where the quote token is liquidated to repay the GHOST base Vault

  * `:max_ltv` - The maximum ratio of the value of borrowed tokens to value of LP tokens, above which a position can be liquidated

  * `:full_liquidation_threshold` - The position value below which a liquidation covers all outstanding debt

  * `:partial_liquidation_fraction` - The target LTV to be achieved when a position is partially liquidated

  * `:borrow_fee` - The percentage of borrowed assets that are sent to KUJI stakers as a fee
  """

  defmodule Status do
    @moduledoc """
    The current deposit and borrow totals

    ## Fields
    * `:deposited` - The amount of LP token deposited

    * `:borrowed_base` - The amount of the base token of the pair borrowed

    * `:borrowed_quote` - The amount of the quote token of the pair borrowed
    """

    defstruct deposited: 0,
              borrowed_base: 0,
              borrowed_quote: 0

    @type t :: %__MODULE__{
            deposited: non_neg_integer(),
            borrowed_base: non_neg_integer(),
            borrowed_quote: non_neg_integer()
          }

    @spec from_query(map()) :: :error | {:ok, __MODULE__.t()}
    def from_query(%{
          "total_lp_amount" => deposited,
          "borrowed" => [%{"amount" => borrowed_base}, %{"amount" => borrowed_quote}]
        }) do
      with {deposited, ""} <- Integer.parse(deposited),
           {borrowed_base, ""} <- Integer.parse(borrowed_base),
           {borrowed_quote, ""} <- Integer.parse(borrowed_quote) do
        {:ok,
         %__MODULE__{
           deposited: deposited,
           borrowed_base: borrowed_base,
           borrowed_quote: borrowed_quote
         }}
      else
        _ ->
          :error
      end
    end
  end

  alias Kujira.Bow
  alias Kujira.Token
  alias Kujira.Ghost
  alias Kujira.Orca

  defstruct [
    :address,
    :owner,
    :bow,
    :token_base,
    :token_quote,
    :oracle_base,
    :oracle_quote,
    :ghost_vault_base,
    :ghost_vault_quote,
    :orca_queue_base,
    :orca_queue_quote,
    :max_ltv,
    :full_liquidation_threshold,
    :partial_liquidation_fraction,
    :borrow_fee,
    :status
  ]

  @type t :: %__MODULE__{
          address: String.t(),
          owner: String.t(),
          bow: {Bow.Pool.Xyk, String.t()} | {Bow.Pool.Stable, String.t()},
          token_base: Token.t(),
          token_quote: Token.t(),
          oracle_base: String.t(),
          oracle_quote: String.t(),
          ghost_vault_base: {Ghost.Vault, String.t()},
          ghost_vault_quote: {Ghost.Vault, String.t()},
          orca_queue_base: {Orca.Queue, String.t()},
          orca_queue_quote: {Orca.Queue, String.t()},
          max_ltv: Decimal.t(),
          full_liquidation_threshold: non_neg_integer(),
          partial_liquidation_fraction: Decimal.t(),
          borrow_fee: Decimal.t(),
          status: :not_loaded | Status.t()
        }

  @spec from_config(GRPC.Channel.t(), String.t(), map()) :: :error | {:ok, __MODULE__.t()}
  def from_config(channel, address, %{
        "owner" => owner,
        "bow_contract" => bow,
        "denoms" => [
          %{
            "denom" => denom_base,
            # "decimals" => decimals_base,
            "oracle" => oracle_base
          },
          %{
            "denom" => denom_quote,
            # "decimals" => decimals_quote,
            "oracle" => oracle_quote
          }
        ],
        "vaults" => [ghost_vault_base, ghost_vault_quote],
        "orcas" => [orca_queue_base, orca_queue_quote],
        "max_ltv" => max_ltv,
        "full_liquidation_threshold" => full_liquidation_threshold,
        "partial_liquidation_target" => partial_liquidation_fraction,
        "borrow_fee" => borrow_fee
      }) do
    with {full_liquidation_threshold, ""} <- Integer.parse(full_liquidation_threshold),
         {max_ltv, ""} <- Decimal.parse(max_ltv),
         {partial_liquidation_fraction, ""} <- Decimal.parse(partial_liquidation_fraction),
         {borrow_fee, ""} <- Decimal.parse(borrow_fee),
         {:ok, token_base} <- Token.from_denom(channel, denom_base),
         {:ok, token_quote} <- Token.from_denom(channel, denom_quote) do
      {:ok,
       %__MODULE__{
         address: address,
         owner: owner,
         bow: {Bow.Pool, bow},
         token_base: token_base,
         token_quote: token_quote,
         oracle_base: oracle_base,
         oracle_quote: oracle_quote,
         ghost_vault_base: {Ghost.Vault, ghost_vault_base},
         ghost_vault_quote: {Ghost.Vault, ghost_vault_quote},
         orca_queue_base: {Orca.Queue, orca_queue_base},
         orca_queue_quote: {Orca.Queue, orca_queue_quote},
         max_ltv: max_ltv,
         full_liquidation_threshold: full_liquidation_threshold,
         partial_liquidation_fraction: partial_liquidation_fraction,
         borrow_fee: borrow_fee,
         status: :not_loaded
       }}
    else
      _ ->
        :error
    end
  end

  @doc """
  Returns a tuple of {token, price, amount} of collateral at risk at the speciifc price point
  """
  @spec liquidation_price(
          Bow.Leverage.t(),
          Bow.Pool.t(),
          Bow.Status.t(),
          Kujira.Ghost.Vault.Status.t(),
          Kujira.Ghost.Vault.Status.t(),
          Decimal.t(),
          Decimal.t(),
          Decimal.t()
        ) :: {Token.t(), Decimal.t(), integer()}
  def liquidation_price(
        %__MODULE__{
          token_base: token_base,
          token_quote: token_quote,
          max_ltv: max_ltv
        },
        %Bow.Pool.Xyk{},
        %Kujira.Bow.Status{} = pool_status,
        %Ghost.Vault.Status{debt_ratio: base_debt_ratio},
        %Ghost.Vault.Status{debt_ratio: quote_debt_ratio},
        %Decimal{} = lp_amount,
        %Decimal{} = debt_shares_base,
        %Decimal{} = debt_shares_quote
      ) do
    debt_amount_base = Decimal.mult(debt_shares_base, base_debt_ratio)
    debt_amount_quote = Decimal.mult(debt_shares_quote, quote_debt_ratio)

    collateral_amount_base =
      Decimal.div(lp_amount, pool_status.lp_amount)
      |> Decimal.mult(pool_status.base_amount)

    collateral_amount_quote =
      Decimal.div(lp_amount, pool_status.lp_amount)
      |> Decimal.mult(pool_status.quote_amount)

    d = max_ltv |> Decimal.mult(collateral_amount_base) |> Decimal.sub(debt_amount_base)

    liquidation_price =
      Decimal.sub(debt_amount_quote, Decimal.mult(max_ltv, collateral_amount_quote))
      |> Decimal.div(d)

    # Unliquidatable
    if Decimal.lt?(liquidation_price, 0) do
      {token_base, Decimal.from_float(0.0), 0}
    else
      k = Decimal.mult(collateral_amount_base, collateral_amount_quote)
      liquidation_collateral_base = k |> Decimal.div(liquidation_price) |> Decimal.sqrt()

      liquidation_collateral_quote = Decimal.mult(liquidation_price, liquidation_collateral_base)

      remaining_debt_base =
        debt_amount_base |> Decimal.sub(liquidation_collateral_base) |> Decimal.max(0)

      remaining_debt_quote =
        debt_amount_quote |> Decimal.sub(liquidation_collateral_quote) |> Decimal.max(0)

      # One of these two will be zero. Do a comparison to check
      if Decimal.gt?(remaining_debt_quote, remaining_debt_base) do
        # We still have quote assets to pay off, so the base asset is at-risk. Divide the quote debt by the price to get the base amount
        {token_base, liquidation_price, Decimal.div(remaining_debt_quote, liquidation_price)}
      else
        {token_quote, liquidation_price, Decimal.mult(remaining_debt_base, liquidation_price)}
      end
    end
  end

  def liquidation_price(
        %__MODULE__{
          token_base: token_base
        },
        _,
        %Bow.Status{},
        %Ghost.Vault.Status{},
        %Ghost.Vault.Status{},
        %Decimal{},
        %Decimal{},
        %Decimal{}
      ) do
    # TODO: Determine whether liquidation price makes sense for a stable pool, as it's impossible to know the ratio of asset in the pool for a given price
    # Perhaps we just naively put the total amount of each asset at the max ltv
    {token_base, Decimal.from_float(0.0), 0}
  end
end
