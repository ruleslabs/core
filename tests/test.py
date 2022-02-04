import pytest

from starkware.starkware_utils.error_handling import StarkException
from starkware.starknet.definitions.error_codes import StarknetErrorCode

from utils import dict_to_tuple, to_flat_tuple

# Artist

async def _create_artist(ctx, account_name, artist_name):
  await ctx.execute(
    account_name,
    ctx.ravageData.contract_address,
    "createArtist",
    [*artist_name]
  )

async def _artist_exists(ctx, artist_name):
  (exists,) = (
    await ctx.ravageData.artistExists(artist_name).call()
  ).result
  return exists

# Cards

async def _create_card(ctx, account_name, card):
  await ctx.execute(
    account_name,
    ctx.ravageCards.contract_address,
    "createCard",
    [*to_flat_tuple(card)]
  )

async def _card_exists(ctx, card_id):
  (exists,) = (
    await ctx.ravageCards.cardExists(card_id).call()
  ).result
  return exists

async def _get_card_id(ctx, card):
  card_id = (
    await ctx.ravageCards.getCardId(dict_to_tuple(card)).call()
  ).result
  return tuple(tuple(card_id)[0])

# async def _create_and_mint_card(ctx, artist_name):
#   await ctx.ravageData.createArtist(artsit_name).invoke()

# Base Token URI

async def _get_base_token_uri(ctx):
  (base_token_uri,) = (
    await ctx.ravageTokens.baseTokenURI().call()
  ).result
  return base_token_uri

async def _set_base_token_uri(ctx, account_name, base_token_uri):
  await ctx.execute(
    account_name,
    ctx.ravageTokens.contract_address,
    "setBaseTokenURI",
    [len(base_token_uri), *base_token_uri]
  )

############
# SCENARIO #
############

class ScenarioState:
  ctx = None

  def __init__(self, ctx):
    self.ctx = ctx

  async def create_artist(self, account_name, artist_name):
    await _create_artist(self.ctx, account_name, artist_name)

  async def create_card(self, account_name, card):
    await _create_card(self.ctx, account_name, card)

  # async def create_and_mint_card(card):
  #   await _create_and_mint_card(card)

  async def set_base_token_uri(self, account_name, base_token_uri):
    await _set_base_token_uri(self.ctx, account_name, base_token_uri)


async def run_scenario(ctx, scenario):
  scenario_state = ScenarioState(ctx)
  for (account_name, function_name, kargs, expect_success) in scenario:
    if account_name not in [MINTER, OWNER]:
      raise f"Invalid signer '{signer}'"

    func = getattr(scenario_state, function_name, None)
    if not func:
      raise AttributeError(f"ScenarioState.{function_name} doesn't exist.")

    try:
      await func(account_name, **kargs)
    except StarkException as e:
      if not expect_success:
        assert e.code == StarknetErrorCode.TRANSACTION_FAILED
      else:
        assert e.code != StarknetErrorCode.TRANSACTION_FAILED
        raise e
    else:
      assert expect_success == True

##########
# CONSTS #
##########

MINTER="minter"
OWNER="owner"

ARTIST_1 = (0x416C7068612057616E6E, 0)
METADATA_1 = dict(hash=(0x1, 0x1), multihash_identifier=(0x1220))
CARD_ARTIST_1 = dict(artist_name=ARTIST_1, season=1, scarcity=1, serial_number=1, metadata=METADATA_1)

#########
# TESTS #
#########

@pytest.mark.asyncio
async def test_settle_where_minter_create_artist(ctx_factory):
  ctx = ctx_factory()

  # Given
  assert await _artist_exists(ctx, artist_name=ARTIST_1) == 0

  # When
  await run_scenario(
    ctx,
    [
      (MINTER, "create_artist", dict(artist_name=ARTIST_1), True),
      (MINTER, "create_artist", dict(artist_name=ARTIST_1), False)
    ]
  )

  # Then
  assert await _artist_exists(ctx, artist_name=ARTIST_1) == 1


@pytest.mark.asyncio
async def test_settle_where_minter_create_card(ctx_factory):
  ctx = ctx_factory()

  # Given
  card_id = await _get_card_id(ctx, CARD_ARTIST_1)
  assert await _card_exists(ctx, card_id) == 0

  # When
  await run_scenario(
    ctx,
    [
      (MINTER, "create_card", dict(card=CARD_ARTIST_1), False),
      (MINTER, "create_artist", dict(artist_name=ARTIST_1), True),
      (MINTER, "create_card", dict(card=CARD_ARTIST_1), True),
      (MINTER, "create_card", dict(card=CARD_ARTIST_1), False),
    ]
  )

  # Then
  assert await _card_exists(ctx, card_id) == 1


@pytest.mark.asyncio
async def test_settle_where_minter_create_invalid_card(ctx_factory):
  ctx = ctx_factory()

  print((lambda d: d.update(season=2) or d)(CARD_ARTIST_1))

  # When / Then
  await run_scenario(
    ctx,
    [
      (MINTER, "create_artist", dict(artist_name=ARTIST_1), True),
      (MINTER, "create_card", dict(card=(lambda d: d.update(season=0) or d)(CARD_ARTIST_1)), False),
      (MINTER, "create_card", dict(card=(lambda d: d.update(scarcity=0) or d)(CARD_ARTIST_1)), False),
      (MINTER, "create_card", dict(card=(lambda d: d.update(serial_number=0) or d)(CARD_ARTIST_1)), False),
      (MINTER, "create_card", dict(card=(lambda d: d.update(season=2 ** 16) or d)(CARD_ARTIST_1)), False),
      (MINTER, "create_card", dict(card=(lambda d: d.update(scarcity=2 ** 8) or d)(CARD_ARTIST_1)), False),
      (MINTER, "create_card", dict(card=(lambda d: d.update(serial_number=2 ** 32) or d)(CARD_ARTIST_1)), False),
    ]
  )

@pytest.mark.asyncio
async def test_settle_where_owner_set_base_token_uri(ctx_factory):
  ctx = ctx_factory()

  # Given
  base_token_uri = [1, 2, 2, 3, 3, 3]
  assert await _get_base_token_uri(ctx) == []

  # When
  await run_scenario(
    ctx,
    [
      (OWNER, "set_base_token_uri", dict(base_token_uri=base_token_uri + base_token_uri), True),
      (OWNER, "set_base_token_uri", dict(base_token_uri=[32434, 5234, 23, 5324]), True),
      (OWNER, "set_base_token_uri", dict(base_token_uri=base_token_uri), True),
    ]
  )

  # Then
  assert await _get_base_token_uri(ctx) == base_token_uri


# @pytest.mark.asyncio
# async def test_settle_where_non_minter_create_artist(ctx_factory):
