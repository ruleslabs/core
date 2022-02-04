import pytest

from starkware.starkware_utils.error_handling import StarkException
from starkware.starknet.definitions.error_codes import StarknetErrorCode

from utils import dict_to_flat_tuple

# Artist

async def _create_artist(ctx, artist_name):
  await ctx.ravageData.createArtist(artist_name).invoke()

async def _artist_exists(ctx, artist_name):
  (exists,) = (
    await ctx.ravageData.artistExists(artist_name).call()
  ).result
  return exists

# Cards

async def _create_card(ctx, card):
  await ctx.ravageCards.createCard(dict_to_flat_tuple(card)).invoke()

async def _card_exists(ctx, card_id):
  (exists,) = (
    await ctx.ravageCards.cardExists(card_id).call()
  ).result
  return exists

async def _get_card_id(ctx, card):
  card_id = (
    await ctx.ravageCards.getCardId(dict_to_flat_tuple(card)).call()
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

async def _set_base_token_uri(ctx, base_token_uri):
  await ctx.ravageTokens.setBaseTokenURI(base_token_uri).invoke()


class ScenarioState:
  ctx = None

  def __init__(self, ctx):
    self.ctx = ctx

  async def create_artist(self, artist_name):
    await _create_artist(self.ctx, artist_name)

  async def create_card(self, card):
    await _create_card(self.ctx, card)

  # async def create_and_mint_card(card):
  #   await _create_and_mint_card(card)

  async def set_base_token_uri(self, base_token_uri):
    await _set_base_token_uri(self.ctx, base_token_uri)


async def run_scenario(ctx, scenario):
  scenario_state = ScenarioState(ctx)
  for (function_name, kargs, expect_success) in scenario:
    func = getattr(scenario_state, function_name, None)
    if not func:
      raise AttributeError(f"ScenarioState.{function_name} doesn't exist.")

    try:
      await func(**kargs)
    except StarkException as e:
      if not expect_success:
        assert e.code == StarknetErrorCode.TRANSACTION_FAILED
      else:
        assert e.code != StarknetErrorCode.TRANSACTION_FAILED
        raise e
    else:
      assert expect_success == True


ARTIST_1 = (0x416C7068612057616E6E, 0)
METADATA_1 = dict(hash=(0x1, 0x1), multihash_identifier=(0x1220))
CARD_ARTIST_1 = dict(artist_name=ARTIST_1, season=1, scarcity=1, serial_number=1, metadata=METADATA_1)


@pytest.mark.asyncio
async def test_create_artist(ctx_factory):
  ctx = ctx_factory()

  # Given
  assert await _artist_exists(ctx, artist_name=ARTIST_1) == 0

  # When
  await run_scenario(
    ctx,
    [
      ("create_artist", dict(artist_name=ARTIST_1), True),
      ("create_artist", dict(artist_name=ARTIST_1), False)
    ]
  )

  # Then
  assert await _artist_exists(ctx, artist_name=ARTIST_1) == 1


@pytest.mark.asyncio
async def test_create_card(ctx_factory):
  ctx = ctx_factory()

  # Given
  card_id = await _get_card_id(ctx, CARD_ARTIST_1)
  assert await _card_exists(ctx, card_id) == 0

  # When
  await run_scenario(
    ctx,
    [
      ("create_card", dict(card=CARD_ARTIST_1), False),
      ("create_artist", dict(artist_name=ARTIST_1), True),
      ("create_card", dict(card=CARD_ARTIST_1), True),
      ("create_card", dict(card=CARD_ARTIST_1), False),
    ]
  )

  # Then
  assert await _card_exists(ctx, card_id) == 1


@pytest.mark.asyncio
async def test_create_invalid_card(ctx_factory):
  ctx = ctx_factory()

  print((lambda d: d.update(season=2) or d)(CARD_ARTIST_1))

  # When / Then
  await run_scenario(
    ctx,
    [
      ("create_artist", dict(artist_name=ARTIST_1), True),
      ("create_card", dict(card=(lambda d: d.update(season=0) or d)(CARD_ARTIST_1)), False),
      ("create_card", dict(card=(lambda d: d.update(scarcity=0) or d)(CARD_ARTIST_1)), False),
      ("create_card", dict(card=(lambda d: d.update(serial_number=0) or d)(CARD_ARTIST_1)), False),
      ("create_card", dict(card=(lambda d: d.update(season=2 ** 16) or d)(CARD_ARTIST_1)), False),
      ("create_card", dict(card=(lambda d: d.update(scarcity=2 ** 8) or d)(CARD_ARTIST_1)), False),
      ("create_card", dict(card=(lambda d: d.update(serial_number=2 ** 32) or d)(CARD_ARTIST_1)), False),
    ]
  )

@pytest.mark.asyncio
async def test_base_token_uri(ctx_factory):
  ctx = ctx_factory()

  # Given
  base_token_uri = [1, 2, 2, 3, 3, 3]
  assert await _get_base_token_uri(ctx) == []

  # When
  await run_scenario(
    ctx,
    [
      ("set_base_token_uri", dict(base_token_uri=base_token_uri + base_token_uri), True),
      ("set_base_token_uri", dict(base_token_uri=[32434, 5234, 23, 5324]), True),
      ("set_base_token_uri", dict(base_token_uri=base_token_uri), True),
    ]
  )

  # Then
  assert await _get_base_token_uri(ctx) == base_token_uri
