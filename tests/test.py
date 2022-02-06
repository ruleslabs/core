import pytest

from starkware.starkware_utils.error_handling import StarkException
from starkware.starknet.definitions.error_codes import StarknetErrorCode

from utils import dict_to_tuple, to_flat_tuple, update_dict

# Artist

async def _create_artist(ctx, signer_account_name, artist_name):
  await ctx.execute(
    signer_account_name,
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

async def _create_card(ctx, signer_account_name, card):
  await ctx.execute(
    signer_account_name,
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

async def _set_base_token_uri(ctx, signer_account_name, base_token_uri):
  await ctx.execute(
    signer_account_name,
    ctx.ravageTokens.contract_address,
    "setBaseTokenURI",
    [len(base_token_uri), *base_token_uri]
  )

# Roles

async def _get_minter_role(contract):
  (minter_role,) = (
    await contract.MINTER_ROLE().call()
  ).result
  return (minter_role)

async def _has_tokens_role(ctx, role, account_name):
  account_address = getattr(ctx, account_name, None).contract_address
  if not account_address:
    raise AttributeError(f"ctx.'{account}' doesn't exists.")

  (has_role,) = (
    await ctx.ravageTokens.hasRole(role, account_address).call()
  ).result
  return (has_role)

async def _add_minter(ctx, signer_account_name, contract, account_address):
  await ctx.execute(
    signer_account_name,
    contract.contract_address,
    "addMinter",
    [account_address]
  )

async def _revoke_minter(ctx, signer_account_name, contract, account_address):
  await ctx.execute(
    signer_account_name,
    contract.contract_address,
    "revokeMinter",
    [account_address]
  )

############
# SCENARIO #
############

class ScenarioState:
  ctx = None

  def __init__(self, ctx):
    self.ctx = ctx

  async def create_artist(self, signer_account_name, artist_name):
    await _create_artist(self.ctx, signer_account_name, artist_name)

  async def create_card(self, signer_account_name, card):
    await _create_card(self.ctx, signer_account_name, card)

  # async def create_and_mint_card(card):
  #   await _create_and_mint_card(card)

  async def set_base_token_uri(self, signer_account_name, base_token_uri):
    await _set_base_token_uri(self.ctx, signer_account_name, base_token_uri)

  async def add_tokens_minter(self, signer_account_name, account_name):
    account_address = getattr(self.ctx, account_name, None).contract_address
    if not account_address:
      raise AttributeError(f"ctx.'{account_name}' doesn't exists.")

    await _add_minter(self.ctx, signer_account_name, self.ctx.ravageTokens, account_address)

  async def revoke_tokens_minter(self, signer_account_name, account_name):
    account_address = getattr(self.ctx, account_name, None).contract_address
    if not account_address:
      raise AttributeError(f"ctx.'{account_name}' doesn't exists.")

    await _revoke_minter(self.ctx, signer_account_name, self.ctx.ravageTokens, account_address)


async def run_scenario(ctx, scenario):
  scenario_state = ScenarioState(ctx)
  for (signer_account_name, function_name, kwargs, expect_success) in scenario:
    if signer_account_name not in VALID_ACCOUNT_NAMES:
      raise AttributeError(f"Invalid signer '{signer_account_name}'")

    func = getattr(scenario_state, function_name, None)
    if not func:
      raise AttributeError(f"ScenarioState.{function_name} doesn't exist.")

    try:
      await func(signer_account_name, **kwargs)
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

MINTER = "minter"
OWNER = "owner"
RANDO = "rando"
VALID_ACCOUNT_NAMES = [MINTER, OWNER, RANDO]

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

  # When / Then
  await run_scenario(
    ctx,
    [
      (MINTER, "create_artist", dict(artist_name=ARTIST_1), True),
      (MINTER, "create_card", dict(card=update_dict(CARD_ARTIST_1, season=0)), False),
      (MINTER, "create_card", dict(card=update_dict(CARD_ARTIST_1, scarcity=0)), False),
      (MINTER, "create_card", dict(card=update_dict(CARD_ARTIST_1, serial_number=0)), False),
      (MINTER, "create_card", dict(card=update_dict(CARD_ARTIST_1, season=2 ** 16)), False),
      (MINTER, "create_card", dict(card=update_dict(CARD_ARTIST_1, scarcity=2 ** 8)), False),
      (MINTER, "create_card", dict(card=update_dict(CARD_ARTIST_1, serial_number=2 ** 32)), False),
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


@pytest.mark.asyncio
async def test_settle_where_owner_distribute_ravageTokens_minter_role(ctx_factory):
  ctx = ctx_factory()

  # Given
  minter_role = await _get_minter_role(ctx.ravageTokens)
  assert minter_role != 0

  assert await _has_tokens_role(ctx, minter_role, OWNER) == 1
  assert await _has_tokens_role(ctx, minter_role, MINTER) == 1
  assert await _has_tokens_role(ctx, minter_role, RANDO) == 0

  # When
  await run_scenario(
    ctx,
    [
      (RANDO, "add_tokens_minter", dict(account_name=RANDO), False),
      (MINTER, "add_tokens_minter", dict(account_name=RANDO), False),
      (OWNER, "add_tokens_minter", dict(account_name=RANDO), True),
      (OWNER, "add_tokens_minter", dict(account_name=RANDO), True),
      (OWNER, "revoke_tokens_minter", dict(account_name=MINTER), True),
      (RANDO, "revoke_tokens_minter", dict(account_name=OWNER), False),
      (OWNER, "revoke_tokens_minter", dict(account_name=OWNER), True),
    ]
  )

  assert await _has_tokens_role(ctx, minter_role, OWNER) == 0
  assert await _has_tokens_role(ctx, minter_role, MINTER) == 0
  assert await _has_tokens_role(ctx, minter_role, RANDO) == 1
