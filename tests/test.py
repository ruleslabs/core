import pytest

from starkware.starkware_utils.error_handling import StarkException
from starkware.starknet.definitions.error_codes import StarknetErrorCode

from utils import (
  dict_to_tuple, to_flat_tuple, update_card, get_contract, get_method, to_uint, get_account_address,
  felts_to_string, felts_to_ascii, from_uint
)

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

async def _create_card(ctx, signer_account_name, card, metadata):
  await ctx.execute(
    signer_account_name,
    ctx.rulesCards.contract_address,
    "createCard",
    [*to_flat_tuple(card), *to_flat_tuple(metadata)]
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

# Token URI

async def _get_base_token_uri(ctx):
  (base_token_uri,) = (
    await ctx.rulesTokens.baseTokenURI().call()
  ).result
  return base_token_uri


async def _get_token_uri(ctx, token_id):
  (token_uri,) = (
    await ctx.rulesTokens.tokenURI(token_id).call()
  ).result
  return token_uri


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


async def _role_members_count(ctx, contract_name, role):
  contract = get_contract(ctx, contract_name)

  (count,) = (
    await contract.getRoleMemberCount(role).call()
  ).result
  return (count)


async def _has_role(ctx, conrtact_name, role, account_name):
  contract = get_contract(ctx, conrtact_name)
  account_address = get_account_address(ctx, account_name)

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

# Ownable

async def _get_owner(ctx, contract_name):
  contract = get_contract(ctx, contract_name)

  (owner_address,) = (
    await contract.owner().call()
  ).result
  return owner_address


async def _transfer_ownership(ctx, signer_account_name, contract, account_address):
  await ctx.execute(
    signer_account_name,
    contract.contract_address,
    "transferOwnership",
    [account_address]
  )


async def _renounce_ownership(ctx, signer_account_name, contract):
  await ctx.execute(signer_account_name, contract.contract_address, "renounceOwnership", [])

# Scarcity

async def _get_supply_for_season_and_scarcity(ctx, season, scarcity):
  (supply,) = (
    await ctx.rulesCards.getSupplyForSeasonAndScarcity(season, scarcity).call()
  ).result
  return supply


async def _add_scarcity_for_season(ctx, signer_account_name, season, supply):
  await ctx.execute(
    signer_account_name,
    ctx.rulesCards.contract_address,
    "addScarcityForSeason",
    [season, supply]
  )


async def _stopped_production_for_season_and_scarcity(ctx, season, scarcity):
  (stopped,) = (
    await ctx.rulesCards.productionStoppedForSeasonAndScarcity(season, scarcity).call()
  ).result
  return stopped


async def _stop_production_for_season_and_scarcity(ctx, signer_account_name, season, scarcity):
  await ctx.execute(
    signer_account_name,
    ctx.rulesCards.contract_address,
    "stopProductionForSeasonAndScarcity",
    [season, scarcity]
  )

# Mint

async def _create_and_mint_card(ctx, signer_account_name, card, metadata, to_account_address):
  await ctx.execute(
    signer_account_name,
    ctx.rulesTokens.contract_address,
    "createAndMintCard",
    [*to_flat_tuple(card), *to_flat_tuple(metadata), to_account_address]
  )

# Balance and supply

async def _balance_of(ctx, account_name, token_id):
  account_address = get_account_address(ctx, account_name)

  (balance,) = (
    await ctx.rulesTokens.balanceOf(account_address, token_id).call()
  ).result
  return balance


async def _get_total_supply(ctx, token_id):
  (supply,) = (
    await ctx.rulesTokens.totalSupply(token_id).call()
  ).result
  return supply

############
# SCENARIO #
############

class ScenarioState:
  ctx = None

  def __init__(self, ctx):
    self.ctx = ctx

  async def create_artist(self, signer_account_name, artist_name):
    await _create_artist(self.ctx, signer_account_name, artist_name)

  async def create_card(self, signer_account_name, card, metadata):
    await _create_card(self.ctx, signer_account_name, card, metadata)

  async def create_and_mint_card(self, signer_account_name, card, metadata, to_account_name):
    to_account_address = get_account_address(self.ctx, to_account_name)

    await _create_and_mint_card(self.ctx, signer_account_name, card, metadata, to_account_address)

  async def set_base_token_uri(self, signer_account_name, base_token_uri):
    await _set_base_token_uri(self.ctx, signer_account_name, base_token_uri)

  async def grant_role(self, signer_account_name, contract_name, role_name, account_name):
    account_address = get_account_address(self.ctx, account_name)
    contract = get_contract(self.ctx, contract_name)

    await _grant_role(self.ctx, signer_account_name, contract, role_name, account_address)

  async def revoke_role(self, signer_account_name, contract_name, role_name, account_name):
    account_address = get_account_address(self.ctx, account_name)
    contract = get_contract(self.ctx, contract_name)

    await _revoke_role(self.ctx, signer_account_name, contract, role_name, account_address)

  async def transfer_ownership(self, signer_account_name, contract_name, account_name):
    account_address = get_account_address(self.ctx, account_name)
    contract = get_contract(self.ctx, contract_name)

    await _transfer_ownership(self.ctx, signer_account_name, contract, account_address)

  async def renounce_ownership(self, signer_account_name, contract_name):
    contract = get_contract(self.ctx, contract_name)

    await _renounce_ownership(self.ctx, signer_account_name, contract)

  async def add_scarcity_for_season(self, signer_account_name, season, supply):
    await _add_scarcity_for_season(self.ctx, signer_account_name, season, supply)

  async def stop_production_for_season_and_scarcity(self, signer_account_name, season, scarcity):
    await _stop_production_for_season_and_scarcity(self.ctx, signer_account_name, season, scarcity)


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

NULL = "null"
MINTER = "minter"
OWNER = "owner"
RANDO_1 = "rando1"
RANDO_2 = "rando2"
RANDO_3 = "rando3"
VALID_ACCOUNT_NAMES = [MINTER, OWNER, RANDO_1, RANDO_2, RANDO_3, NULL]

MINTER_ROLE = "MINTER_ROLE"
CAPPER_ROLE = "CAPPER_ROLE"
ROLES = dict(MINTER_ROLE="Minter", CAPPER_ROLE="Capper")

ARTIST_1 = (0x416C7068612057616E6E, 0)
METADATA_1 = dict(hash=(0x1, 0x1), multihash_identifier=(0x1220))
CARD_MODEL_1 = dict(artist_name=ARTIST_1, season=1, scarcity=0)
CARD_1 = dict(model=CARD_MODEL_1, serial_number=1)

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
  card_id = await _get_card_id(ctx, CARD_1)
  assert await _card_exists(ctx, card_id) == 0

  # When
  await run_scenario(
    ctx,
    [
      (MINTER, "create_card", dict(card=CARD_1, metadata=METADATA_1), False),
      (MINTER, "create_artist", dict(artist_name=ARTIST_1), True),
      (MINTER, "create_card", dict(card=CARD_1, metadata=METADATA_1), True),
      (MINTER, "create_card", dict(card=CARD_1, metadata=METADATA_1), False),
    ]
  )

  # Then
  assert await _card_exists(ctx, card_id) == 1


@pytest.mark.asyncio
async def test_settle_where_minter_create_invalid_card(ctx_factory):
  ctx = ctx_factory()

  # Given
  assert await _get_supply_for_season_and_scarcity(ctx, 1, 1) == 0

  # When / Then
  await run_scenario(
    ctx,
    [
      (MINTER, "create_artist", dict(artist_name=ARTIST_1), True),
      (MINTER, "create_card", dict(card=update_card(CARD_1, season=0), metadata=METADATA_1), False),
      (MINTER, "create_card", dict(card=update_card(CARD_1, serial_number=0), metadata=METADATA_1), False),
      (MINTER, "create_card", dict(card=update_card(CARD_1, season=2 ** 16), metadata=METADATA_1), False),
      (MINTER, "create_card", dict(card=update_card(CARD_1, scarcity=2 ** 8), metadata=METADATA_1), False),
      (MINTER, "create_card", dict(card=update_card(CARD_1, serial_number=2 ** 32), metadata=METADATA_1), False),
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
  "contract_name, role_name, initial_members_count",
  [
    ("rulesTokens", MINTER_ROLE, 2),
    ("rulesCards", CAPPER_ROLE, 1),
    ("rulesCards", MINTER_ROLE, 3),
    ("rulesData", MINTER_ROLE, 2)
  ]
)
async def test_settle_where_owner_distribute_role(ctx_factory, contract_name, role_name, initial_members_count):
  ctx = ctx_factory()

  # Given
  role = await _get_role(ctx, contract_name, role_name)
  assert role != 0

  assert await _has_role(ctx, contract_name, role, OWNER) == 1
  assert await _has_role(ctx, contract_name, role, RANDO_1) == 0
  assert await _has_role(ctx, contract_name, role, RANDO_2) == 0
  assert await _has_role(ctx, contract_name, role, RANDO_3) == 0
  assert await _role_members_count(ctx, contract_name, role) == initial_members_count

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
      (OWNER, "revoke_role", dict(contract_name=contract_name, role_name=role_name, account_name=OWNER), True),

      (OWNER, "grant_role", dict(contract_name=contract_name, role_name=role_name, account_name=RANDO_1), True),
      (OWNER, "grant_role", dict(contract_name=contract_name, role_name=role_name, account_name=RANDO_3), True),

      (OWNER, "revoke_role", dict(contract_name=contract_name, role_name=role_name, account_name=RANDO_2), True),
      (OWNER, "revoke_role", dict(contract_name=contract_name, role_name=role_name, account_name=RANDO_2), True),

      (OWNER, "grant_role", dict(contract_name=contract_name, role_name=role_name, account_name=RANDO_1), True)
    ]
  )

  assert await _has_role(ctx, contract_name, role, OWNER) == 0
  assert await _has_role(ctx, contract_name, role, RANDO_1) == 1
  assert await _has_role(ctx, contract_name, role, RANDO_2) == 0
  assert await _has_role(ctx, contract_name, role, RANDO_3) == 1
  assert await _role_members_count(ctx, contract_name, role) == initial_members_count + 1


@pytest.mark.asyncio
@pytest.mark.parametrize("contract_name", ["rulesTokens", "rulesCards", "rulesData"])
async def test_settle_where_owner_transfer_the_owner_ship(ctx_factory, contract_name):
  ctx = ctx_factory()

  # Given
  owner_address = get_account_address(ctx, OWNER)
  rando1_address = get_account_address(ctx, RANDO_1)
  assert await _get_owner(ctx, contract_name) == owner_address

  # When
  await run_scenario(
    ctx,
    [
      (RANDO_1, "transfer_ownership", dict(contract_name=contract_name, account_name=RANDO_2), False),
      (OWNER, "transfer_ownership", dict(contract_name=contract_name, account_name=RANDO_1), True),
      (OWNER, "transfer_ownership", dict(contract_name=contract_name, account_name=RANDO_2), False),
    ]
  )

  # Then
  assert await _get_owner(ctx, contract_name) == rando1_address


@pytest.mark.asyncio
@pytest.mark.parametrize("contract_name", ["rulesTokens", "rulesCards", "rulesData"])
async def test_settle_where_owner_renounce_the_owner_ship(ctx_factory, contract_name):
  ctx = ctx_factory()

  # Given
  owner_address = get_account_address(ctx, OWNER)
  assert await _get_owner(ctx, contract_name) == owner_address

  # When
  await run_scenario(
    ctx,
    [
      (RANDO_1, "renounce_ownership", dict(contract_name=contract_name), False),
      (OWNER, "renounce_ownership", dict(contract_name=contract_name), True),
      (OWNER, "renounce_ownership", dict(contract_name=contract_name), False),
    ]
  )

  # Then
  assert await _get_owner(ctx, contract_name) == 0


@pytest.mark.asyncio
async def test_settle_where_capper_add_scarcity_levels(ctx_factory):
  ctx = ctx_factory()

  # Given
  assert await _get_supply_for_season_and_scarcity(ctx, 1, 0) == 0
  assert await _get_supply_for_season_and_scarcity(ctx, 1, 1) == 0
  assert await _get_supply_for_season_and_scarcity(ctx, 1, 2) == 0
  assert await _get_supply_for_season_and_scarcity(ctx, 0, 1) == 0

  # When
  await run_scenario(
    ctx,
    [
      (MINTER, "add_scarcity_for_season", dict(season=1, supply=1000), False),
      (OWNER, "add_scarcity_for_season", dict(season=1, supply=0), False),
      (OWNER, "add_scarcity_for_season", dict(season=1, supply=1000), True),
      (OWNER, "add_scarcity_for_season", dict(season=1, supply=500), True),
      (OWNER, "add_scarcity_for_season", dict(season=1, supply=251), False),
      (OWNER, "add_scarcity_for_season", dict(season=1, supply=0), False),

      (OWNER, "add_scarcity_for_season", dict(season=2, supply=1), True),
    ]
  )

  # Then
  assert await _get_supply_for_season_and_scarcity(ctx, 1, 0) == 0
  assert await _get_supply_for_season_and_scarcity(ctx, 1, 1) == 1000
  assert await _get_supply_for_season_and_scarcity(ctx, 1, 2) == 500
  assert await _get_supply_for_season_and_scarcity(ctx, 2, 1) == 1


@pytest.mark.asyncio
async def test_settle_where_capper_stop_production_for_season_and_scarcity(ctx_factory):
  ctx = ctx_factory()

  # Given
  assert await _stopped_production_for_season_and_scarcity(ctx, 1, 0) == 0
  assert await _stopped_production_for_season_and_scarcity(ctx, 1, 1) == 0
  assert await _stopped_production_for_season_and_scarcity(ctx, 1, 2) == 0
  assert await _stopped_production_for_season_and_scarcity(ctx, 42, 42) == 0

  # When
  await run_scenario(
    ctx,
    [
      (MINTER, "stop_production_for_season_and_scarcity", dict(season=1, scarcity=0), False),
      (OWNER, "stop_production_for_season_and_scarcity", dict(season=1, scarcity=0), True),
      (OWNER, "stop_production_for_season_and_scarcity", dict(season=1, scarcity=0), True),
      (OWNER, "stop_production_for_season_and_scarcity", dict(season=1, scarcity=2), True),
      (OWNER, "stop_production_for_season_and_scarcity", dict(season=42, scarcity=42), True),
    ]
  )

  # Then
  assert await _stopped_production_for_season_and_scarcity(ctx, 1, 0) == 1
  assert await _stopped_production_for_season_and_scarcity(ctx, 1, 1) == 0
  assert await _stopped_production_for_season_and_scarcity(ctx, 1, 2) == 1
  assert await _stopped_production_for_season_and_scarcity(ctx, 42, 42) == 1


@pytest.mark.asyncio
async def test_settle_where_minter_create_card_with_invalid_serial_number(ctx_factory):
  ctx = ctx_factory()

  # Given
  card_id_1 = await _get_card_id(ctx, update_card(CARD_1, scarcity=1, serial_number=1))
  card_id_2 = await _get_card_id(ctx, update_card(CARD_1, scarcity=1, serial_number=2))
  card_id_3 = await _get_card_id(ctx, update_card(CARD_1, scarcity=2, serial_number=1))
  assert await _get_supply_for_season_and_scarcity(ctx, 1, 1) == 0

  # When
  await run_scenario(
    ctx,
    [
      (OWNER, "add_scarcity_for_season", dict(season=1, supply=2), True),

      (MINTER, "create_artist", dict(artist_name=ARTIST_1), True),
      (MINTER, "create_card", dict(card=update_card(CARD_1, scarcity=1, serial_number=3), metadata=METADATA_1), False),
      (MINTER, "create_card", dict(card=update_card(CARD_1, scarcity=1, serial_number=1), metadata=METADATA_1), True),
      (MINTER, "create_card", dict(card=update_card(CARD_1, scarcity=1, serial_number=2), metadata=METADATA_1), True),

      (OWNER, "add_scarcity_for_season", dict(season=1, supply=1), True),

      (MINTER, "create_card", dict(card=update_card(CARD_1, scarcity=2, serial_number=1), metadata=METADATA_1), True),
      (MINTER, "create_card", dict(card=update_card(CARD_1, scarcity=2, serial_number=2), metadata=METADATA_1), False),
    ]
  )

  # Then
  assert await _card_exists(ctx, card_id_1) == 1
  assert await _card_exists(ctx, card_id_2) == 1
  assert await _card_exists(ctx, card_id_3) == 1


@pytest.mark.asyncio
async def test_settle_where_minter_create_card_with_frozen_scarcity(ctx_factory):
  ctx = ctx_factory()

  # Given
  card_id_1 = await _get_card_id(ctx, CARD_1)
  card_id_2 = await _get_card_id(ctx, update_card(CARD_1, serial_number=5))
  card_id_3 = await _get_card_id(ctx, update_card(CARD_1, season=2))
  assert await _stopped_production_for_season_and_scarcity(ctx, 1, 0) == 0
  assert await _stopped_production_for_season_and_scarcity(ctx, 2, 0) == 0

  # When
  await run_scenario(
    ctx,
    [
      (MINTER, "create_artist", dict(artist_name=ARTIST_1), True),
      (MINTER, "create_card", dict(card=CARD_1, metadata=METADATA_1), True),
      (MINTER, "create_card", dict(card=update_card(CARD_1, serial_number=5), metadata=METADATA_1), True),

      (OWNER, "stop_production_for_season_and_scarcity", dict(season=1, scarcity=0), True),

      (MINTER, "create_card", dict(card=update_card(CARD_1, serial_number=10), metadata=METADATA_1), False),
      (MINTER, "create_card", dict(card=update_card(CARD_1, season=2), metadata=METADATA_1), True),
    ]
  )

  # Then
  assert await _card_exists(ctx, card_id_1) == 1
  assert await _card_exists(ctx, card_id_2) == 1
  assert await _card_exists(ctx, card_id_3) == 1


@pytest.mark.asyncio
async def test_settle_where_minter_create_and_mint_cards(ctx_factory):
  ctx = ctx_factory()

  # Given
  card_id_1 = await _get_card_id(ctx, CARD_1)
  card_id_2 = await _get_card_id(ctx, update_card(CARD_1, serial_number=2))
  assert await _balance_of(ctx, MINTER, card_id_1) == to_uint(0)
  assert await _balance_of(ctx, MINTER, card_id_2) == to_uint(0)
  assert await _balance_of(ctx, RANDO_1, card_id_1) == to_uint(0)
  assert await _balance_of(ctx, RANDO_1, card_id_2) == to_uint(0)

  # When
  await run_scenario(
    ctx,
    [
      (MINTER, "create_artist", dict(artist_name=ARTIST_1), True),

      (MINTER, "create_and_mint_card", dict(card=CARD_1, metadata=METADATA_1, to_account_name=NULL), False),

      (MINTER, "create_and_mint_card", dict(card=CARD_1, metadata=METADATA_1, to_account_name=MINTER), True),
      (MINTER, "create_and_mint_card", dict(card=update_card(CARD_1, serial_number=2), metadata=METADATA_1, to_account_name=RANDO_1), True),

      (MINTER, "create_and_mint_card", dict(card=CARD_1, metadata=METADATA_1, to_account_name=MINTER), False),
    ]
  )

  # Then
  assert await _balance_of(ctx, MINTER, card_id_1) == to_uint(1)
  assert await _balance_of(ctx, MINTER, card_id_2) == to_uint(0)
  assert await _balance_of(ctx, RANDO_1, card_id_1) == to_uint(0)
  assert await _balance_of(ctx, RANDO_1, card_id_2) == to_uint(1)


@pytest.mark.asyncio
async def test_settle_where_minter_create_and_mint_card_and_check_token_uri(ctx_factory):
  ctx = ctx_factory()

  # Given
  base_token_uri = [0x68747470733A2F2F6578616D706C652E, 0x636F6D2F6170692F63617264732F]
  card_id_1 = await _get_card_id(ctx, CARD_1)
  token_uri = felts_to_ascii(base_token_uri) + felts_to_string([from_uint(card_id_1)])

  # When
  await run_scenario(
    ctx,
    [
      (OWNER, "set_base_token_uri", dict(base_token_uri=base_token_uri), True),

      (MINTER, "create_artist", dict(artist_name=ARTIST_1), True),
      (MINTER, "create_and_mint_card", dict(card=CARD_1, metadata=METADATA_1, to_account_name=MINTER), True),
    ]
  )

  # Then
  print(card_id_1)
  print(await _get_token_uri(ctx, card_id_1))
  assert felts_to_ascii(await _get_token_uri(ctx, card_id_1)) == token_uri
