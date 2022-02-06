import pytest

from starkware.starkware_utils.error_handling import StarkException
from starkware.starknet.definitions.error_codes import StarknetErrorCode

from utils import dict_to_tuple, to_flat_tuple, update_dict, get_contract, get_method

# Artist

async def _create_artist(ctx, signer_account_name, artist_name):
  await ctx.execute(
    signer_account_name,
    ctx.rulesData.contract_address,
    "createArtist",
    [*artist_name]
  )


async def _artist_exists(ctx, artist_name):
  (exists,) = (
    await ctx.rulesData.artistExists(artist_name).call()
  ).result
  return exists

# Cards

async def _create_card(ctx, signer_account_name, card):
  await ctx.execute(
    signer_account_name,
    ctx.rulesCards.contract_address,
    "createCard",
    [*to_flat_tuple(card)]
  )


async def _card_exists(ctx, card_id):
  (exists,) = (
    await ctx.rulesCards.cardExists(card_id).call()
  ).result
  return exists


async def _get_card_id(ctx, card):
  card_id = (
    await ctx.rulesCards.getCardId(dict_to_tuple(card)).call()
  ).result
  return tuple(tuple(card_id)[0])

# async def _create_and_mint_card(ctx, artist_name):
#   await ctx.rulesData.createArtist(artsit_name).invoke()

# Base Token URI

async def _get_base_token_uri(ctx):
  (base_token_uri,) = (
    await ctx.rulesTokens.baseTokenURI().call()
  ).result
  return base_token_uri


async def _set_base_token_uri(ctx, signer_account_name, base_token_uri):
  await ctx.execute(
    signer_account_name,
    ctx.rulesTokens.contract_address,
    "setBaseTokenURI",
    [len(base_token_uri), *base_token_uri]
  )

# Roles

async def _get_role(ctx, contract_name, role_name):
  contract = get_contract(ctx, contract_name)
  method = get_method(contract, role_name)

  (minter_role,) = (
    await method().call()
  ).result
  return (minter_role)


async def _has_role(ctx, conrtact_name, role, account_name):
  contract = get_contract(ctx, conrtact_name)
  account_address = get_contract(ctx, account_name).contract_address

  (has_role,) = (
    await contract.hasRole(role, account_address).call()
  ).result
  return (has_role)


async def _grant_role(ctx, signer_account_name, contract, role_name, account_address):
  method_name = "add" + ROLES[role_name]
  await ctx.execute(
    signer_account_name,
    contract.contract_address,
    method_name,
    [account_address]
  )


async def _revoke_role(ctx, signer_account_name, contract, role_name, account_address):
  method_name = "revoke" + ROLES[role_name]
  await ctx.execute(
    signer_account_name,
    contract.contract_address,
    method_name,
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

  async def grant_role(self, signer_account_name, contract_name, role_name, account_name):
    account_address = get_contract(self.ctx, account_name).contract_address
    contract = get_contract(self.ctx, contract_name)

    await _grant_role(self.ctx, signer_account_name, contract, role_name, account_address)

  async def revoke_role(self, signer_account_name, contract_name, role_name, account_name):
    account_address = get_contract(self.ctx, account_name).contract_address
    contract = get_contract(self.ctx, contract_name)

    await _revoke_role(self.ctx, signer_account_name, contract, role_name, account_address)


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
RANDO_1 = "rando1"
RANDO_2 = "rando2"
RANDO_3 = "rando3"
VALID_ACCOUNT_NAMES = [MINTER, OWNER, RANDO_1, RANDO_2, RANDO_3]

MINTER_ROLE = "MINTER_ROLE"
CAPPER_ROLE = "CAPPER_ROLE"
ROLES = dict(MINTER_ROLE="Minter", CAPPER_ROLE="Capper")

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
@pytest.mark.parametrize(
  "contract_name, role_name",
  [
    ("rulesTokens", MINTER_ROLE),
    ("rulesCards", CAPPER_ROLE),
    ("rulesCards", MINTER_ROLE),
    ("rulesData", MINTER_ROLE)
  ]
)
async def test_settle_where_owner_distribute_role(ctx_factory, contract_name, role_name):
  ctx = ctx_factory()

  # Given
  role = await _get_role(ctx, contract_name, role_name)
  assert role != 0

  assert await _has_role(ctx, contract_name, role, OWNER) == 1
  assert await _has_role(ctx, contract_name, role, RANDO_1) == 0
  assert await _has_role(ctx, contract_name, role, RANDO_2) == 0
  assert await _has_role(ctx, contract_name, role, RANDO_3) == 0

  # When
  await run_scenario(
    ctx,
    [
      (RANDO_1, "grant_role", dict(contract_name=contract_name, role_name=role_name, account_name=RANDO_2), False),
      (RANDO_3, "grant_role", dict(contract_name=contract_name, role_name=role_name, account_name=RANDO_3), False),

      (OWNER, "grant_role", dict(contract_name=contract_name, role_name=role_name, account_name=RANDO_1), True),
      (OWNER, "grant_role", dict(contract_name=contract_name, role_name=role_name, account_name=RANDO_2), True),
      (OWNER, "grant_role", dict(contract_name=contract_name, role_name=role_name, account_name=RANDO_1), True),

      (OWNER, "revoke_role", dict(contract_name=contract_name, role_name=role_name, account_name=RANDO_1), True),
      (OWNER, "revoke_role", dict(contract_name=contract_name, role_name=role_name, account_name=RANDO_2), True),
      (OWNER, "revoke_role", dict(contract_name=contract_name, role_name=role_name, account_name=RANDO_2), True),
      (OWNER, "revoke_role", dict(contract_name=contract_name, role_name=role_name, account_name=OWNER), True),

      (OWNER, "grant_role", dict(contract_name=contract_name, role_name=role_name, account_name=RANDO_1), True),
      (OWNER, "grant_role", dict(contract_name=contract_name, role_name=role_name, account_name=RANDO_2), True),
      (OWNER, "grant_role", dict(contract_name=contract_name, role_name=role_name, account_name=RANDO_3), True)
    ]
  )

  assert await _has_role(ctx, contract_name, role, OWNER) == 0
  assert await _has_role(ctx, contract_name, role, RANDO_1) == 1
  assert await _has_role(ctx, contract_name, role, RANDO_2) == 1
  assert await _has_role(ctx, contract_name, role, RANDO_3) == 1
