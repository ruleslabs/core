import pytest

from starkware.starkware_utils.error_handling import StarkException

from conftest import BASE_URI

from utils.misc import (
  dict_to_tuple, to_starknet_args, update_dict, get_method, to_uint, get_account_address,
  SERIAL_NUMBER_MAX, get_declared_class, compute_card_id
)

# Marketplace

async def _get_marketplace(ctx):
  (marketplace,) = (
    await ctx.rules.marketplace().call()
  ).result
  return marketplace


async def _set_marketplace(ctx, signer_account_name, contract_addres):
  await ctx.execute(
    signer_account_name,
    ctx.rules.contract_address,
    'setMarketplace',
    [contract_addres]
  )


# Cards

async def _card_exists(ctx, card_id):
  (exists,) = (
    await ctx.rules.cardExists(card_id).call()
  ).result
  return exists


async def _card_id(ctx, card):
  (card_id,) = (
    await ctx.rules.cardId(dict_to_tuple(card)).call()
  ).result
  return card_id

# Packs

async def _create_pack(ctx, signer_account_name, max_supply, metadata):
  await ctx.execute(
    signer_account_name,
    ctx.rules.contract_address,
    'createPack',
    [max_supply, *to_starknet_args(metadata)]
  )


async def _create_common_pack(ctx, signer_account_name, season, metadata):
  await ctx.execute(
    signer_account_name,
    ctx.rules.contract_address,
    'createCommonPack',
    [season, *to_starknet_args(metadata)]
  )


async def _pack_exists(ctx, pack_id):
  (exists,) = (
    await ctx.rules.packExists(pack_id).call()
  ).result
  return exists

# Token URI

async def _get_uri(ctx, token_id):
  (uri,) = (
    await ctx.rules.uri(token_id).call()
  ).result
  return uri


async def _set_uri(ctx, signer_account_name, uri):
  await ctx.execute(
    signer_account_name,
    ctx.rules.contract_address,
    'setUri',
    [len(uri), *uri]
  )

# Contract URI

async def _get_contract_uri(ctx):
  (contract_uri,) = (
    await ctx.rules.contractURI().call()
  ).result
  return contract_uri


async def _set_contract_uri(ctx, signer_account_name, contract_uri):
  await ctx.execute(
    signer_account_name,
    ctx.rules.contract_address,
    'setContractURI',
    [len(contract_uri), *contract_uri]
  )

# Roles

async def _get_role(ctx, role_name):
  method = get_method(ctx.rules, role_name)

  (role,) = (
    await method().call()
  ).result
  return (role)


async def _role_members_count(ctx, role):
  (count,) = (
    await ctx.rules.roleMembersCount(role).call()
  ).result
  return (count)


async def _has_role(ctx, role, account_name):
  account_address = get_account_address(ctx, account_name)

  (has_role,) = (
    await ctx.rules.hasRole(role, account_address).call()
  ).result
  return (has_role)


async def _grant_role(ctx, signer_account_name, role_name, account_address):
  method_name = 'add' + ROLES[role_name]
  await ctx.execute(
    signer_account_name,
    ctx.rules.contract_address,
    method_name,
    [account_address]
  )


async def _revoke_role(ctx, signer_account_name, role_name, account_address):
  method_name = 'revoke' + ROLES[role_name]
  await ctx.execute(
    signer_account_name,
    ctx.rules.contract_address,
    method_name,
    [account_address]
  )

# Ownable

async def _owner(ctx):
  (owner_address,) = (
    await ctx.rules.owner().call()
  ).result
  return owner_address


async def _transfer_ownership(ctx, signer_account_name, account_address):
  await ctx.execute(
    signer_account_name,
    ctx.rules.contract_address,
    'transferOwnership',
    [account_address]
  )


async def _renounce_ownership(ctx, signer_account_name):
  await ctx.execute(signer_account_name, ctx.rules.contract_address, 'renounceOwnership', [])

# Scarcity

async def _scarcity_max_supply(ctx, season, scarcity):
  (supply,) = (
    await ctx.rules.scarcityMaxSupply(season, scarcity).call()
  ).result
  return supply


async def _add_scarcity_for_season(ctx, signer_account_name, season, supply):
  await ctx.execute(
    signer_account_name,
    ctx.rules.contract_address,
    'addScarcityForSeason',
    [season, supply]
  )


# Mint

async def _create_and_mint_card(ctx, signer_account_name, card, metadata, to_account_address):
  await ctx.execute(
    signer_account_name,
    ctx.rules.contract_address,
    'createAndMintCard',
    [to_account_address, *to_starknet_args(card), *to_starknet_args(metadata)]
  )

async def _mint_pack(ctx, signer_account_name, pack_id, to_account_address, amount, unlocked):
  await ctx.execute(
    signer_account_name,
    ctx.rules.contract_address,
    'mintPack',
    [to_account_address, *to_starknet_args(pack_id), amount, unlocked]
  )

# Balance and supply

async def _balance_of(ctx, account_name, token_id):
  account_address = get_account_address(ctx, account_name)

  (balance,) = (
    await ctx.rules.balanceOf(account_address, token_id).call()
  ).result
  return balance


# Pack locking

async def _get_unlocked(ctx, account_name, token_id):
  account_address = get_account_address(ctx, account_name)

  (amount,) = (
    await ctx.rules.getUnlocked(account_address, token_id).call()
  ).result
  return amount

# Transfer

async def _safe_transfer(ctx, signer_account_name, token_id, from_account_address, to_account_address, amount):
  await ctx.execute(
    signer_account_name,
    ctx.rules.contract_address,
    'safeTransferFrom',
    [from_account_address, to_account_address, *to_starknet_args(token_id), *to_starknet_args(amount), 1, 0]
  )

# Approval

async def _set_approve_for_all(ctx, signer_account_name, to_account_address, approved):
  await ctx.execute(
    signer_account_name,
    ctx.rules.contract_address,
    'setApprovalForAll',
    [to_account_address, approved]
  )

# Pack opening

async def _open_pack_from(ctx, signer_account_name, pack_id, cards, metadata, from_account_address):
  await ctx.execute(
    signer_account_name,
    ctx.rules.contract_address,
    'openPackFrom',
    [from_account_address, *to_starknet_args(pack_id), len(cards), *to_starknet_args(cards), len(metadata), *to_starknet_args(metadata)]
  )

# Proxy

async def _upgrade(ctx, signer_account_name, new_declared_class):
  await ctx.execute(
    signer_account_name,
    ctx.rules.contract_address,
    'upgrade',
    [new_declared_class.class_hash]
  )

async def _initialize(ctx, signer_account_name, params):
  await ctx.execute(
    signer_account_name,
    ctx.rules.contract_address,
    'initialize',
    params,
  )

async def _reset(ctx, signer_account_name):
  await ctx.execute(signer_account_name, ctx.rules.contract_address, 'reset', [])

##########
# CONSTS #
##########

NULL = 'null'
DEAD = 'dead'
MINTER = 'minter'
OWNER = 'owner'
RANDO_1 = 'rando1'
RANDO_2 = 'rando2'
RANDO_3 = 'rando3'
VALID_ACCOUNT_NAMES = [MINTER, OWNER, RANDO_1, RANDO_2, RANDO_3, NULL]

MINTER_ROLE = 'MINTER_ROLE'
CAPPER_ROLE = 'CAPPER_ROLE'
ROLES = dict(MINTER_ROLE='Minter', CAPPER_ROLE='Capper')

METADATA_1 = dict(hash=(0x1, 0x1), multihash_identifier=(0x1220))

INVALID_METADATA_1 = dict(hash=(0x0, 0x1), multihash_identifier=(0x1220))
INVALID_METADATA_2 = dict(hash=(0x1, 0x0), multihash_identifier=(0x1220))
INVALID_METADATA_3 = dict(hash=(0x1, 0x1), multihash_identifier=(0x0))
INVALID_METADATA_4 = dict(hash=(0x1, 0x1), multihash_identifier=(0x1221))

FELT_METADATA_1 = dict(hash=(0x1), multihash_identifier=(0x1220))

INVALID_FELT_METADATA_1 = dict(hash=(0x0), multihash_identifier=(0x1220))
INVALID_FELT_METADATA_2 = dict(hash=(0x1), multihash_identifier=(0x0))
INVALID_FELT_METADATA_3 = dict(hash=(0x1), multihash_identifier=(0x1221))

ARTIST_1 = (0x416C7068612057616E6E, 0)
ARTIST_2 = (0x6162636465666768696A6B6C6D6E6F70, 0x7172737475767778797A31)
INVALID_ARTIST = (0x6162636465666768696A6B6C6D6E6F70, 0x7172737475767778797A3132)

CARD_1 = dict(artist_name=ARTIST_1, season=1, scarcity=0, serial_number=1)
CARD_2 = dict(artist_name=ARTIST_2, season=1, scarcity=0, serial_number=1)

############
# SCENARIO #
############

class ScenarioState:
  ctx = None

  def __init__(self, ctx):
    self.ctx = ctx

  # Marketplace

  async def set_marketplace(self, signer_account_name, contract_name):
    contract_address = get_account_address(self.ctx, contract_name)

    await _set_marketplace(self.ctx, signer_account_name, contract_address)

  # Proxy

  async def upgrade(self, signer_account_name, new_declared_class_name):
    new_declared_class = get_declared_class(self.ctx, new_declared_class_name)

    await _upgrade(self.ctx, signer_account_name, new_declared_class)

  async def initialize(self, signer_account_name, params):
    await _initialize(self.ctx, signer_account_name, params)

  async def reset(self, signer_account_name):
    await _reset(self.ctx, signer_account_name)

  # Transfer

  async def safe_transfer(self, signer_account_name, token_id, from_account_name, to_account_name, amount):
    from_account_address = get_account_address(self.ctx, from_account_name)
    to_account_address = get_account_address(self.ctx, to_account_name)

    await _safe_transfer(self.ctx, signer_account_name, token_id, from_account_address, to_account_address, to_uint(amount))

  # Approval

  async def set_approve_for_all(self, signer_account_name, to_account_name, approved):
    to_account_address = get_account_address(self.ctx, to_account_name)

    await _set_approve_for_all(self.ctx, signer_account_name, to_account_address, approved)

  # Cards

  async def create_and_mint_card(self, signer_account_name, card, metadata, to_account_name):
    to_account_address = get_account_address(self.ctx, to_account_name)

    await _create_and_mint_card(self.ctx, signer_account_name, card, metadata, to_account_address)

  # Packs

  async def create_pack(self, signer_account_name, max_supply, metadata):
    await _create_pack(self.ctx, signer_account_name, max_supply, metadata)

  async def create_common_pack(self, signer_account_name, season, metadata):
    await _create_common_pack(self.ctx, signer_account_name, season, metadata)

  async def mint_pack(self, signer_account_name, pack_id, to_account_name, amount, unlocked=False):
    to_account_address = get_account_address(self.ctx, to_account_name)

    await _mint_pack(self.ctx, signer_account_name, pack_id, to_account_address, amount, unlocked)

  # Packs opening

  async def open_pack_from(self, signer_account_name, pack_id, cards, metadata, from_account_name):
    to_account_address = get_account_address(self.ctx, from_account_name)

    await _open_pack_from(self.ctx, signer_account_name, pack_id, cards, metadata, to_account_address)

  # Others

  async def set_uri(self, signer_account_name, uri):
    await _set_uri(self.ctx, signer_account_name, uri)

  async def set_contract_uri(self, signer_account_name, contract_uri):
    await _set_contract_uri(self.ctx, signer_account_name, contract_uri)

  async def grant_role(self, signer_account_name, role_name, account_name):
    account_address = get_account_address(self.ctx, account_name)

    await _grant_role(self.ctx, signer_account_name, role_name, account_address)

  async def revoke_role(self, signer_account_name, role_name, account_name):
    account_address = get_account_address(self.ctx, account_name)

    await _revoke_role(self.ctx, signer_account_name, role_name, account_address)

  async def transfer_ownership(self, signer_account_name, account_name):
    account_address = get_account_address(self.ctx, account_name)

    await _transfer_ownership(self.ctx, signer_account_name, account_address)

  async def renounce_ownership(self, signer_account_name):
    await _renounce_ownership(self.ctx, signer_account_name)

  async def add_scarcity_for_season(self, signer_account_name, season, supply):
    await _add_scarcity_for_season(self.ctx, signer_account_name, season, supply)


async def run_scenario(ctx, scenario):
  scenario_state = ScenarioState(ctx)
  for (signer_account_name, function_name, kwargs, expect_success) in scenario:
    if signer_account_name not in VALID_ACCOUNT_NAMES:
      raise AttributeError(f'Invalid signer \'{signer_account_name}\'')

    print(kwargs)

    func = getattr(scenario_state, function_name, None)
    if not func:
      raise AttributeError(f'ScenarioState.{function_name} doesn\'t exist.')

    try:
      await func(signer_account_name, **kwargs)
    except StarkException as e:
      if expect_success:
        assert expect_success == False
        raise e
      else:
        assert expect_success == False
    else:
      assert expect_success == True


#########
# TESTS #
#########

@pytest.mark.asyncio
async def test_settle_where_minter_create_valid_card(ctx_factory):
  ctx = ctx_factory()

  # Given
  card_id = await _card_id(ctx, CARD_1)
  assert await _card_exists(ctx, card_id) == 0

  # When
  await run_scenario(
    ctx,
    [
      (MINTER, 'create_and_mint_card', dict(card=CARD_1, metadata=FELT_METADATA_1, to_account_name=RANDO_1), True),
      (MINTER, 'create_and_mint_card', dict(card=CARD_1, metadata=FELT_METADATA_1, to_account_name=RANDO_1), False),

      (MINTER, 'create_and_mint_card', dict(card=CARD_2, metadata=FELT_METADATA_1, to_account_name=RANDO_1), True),
    ]
  )

  # Then
  assert await _card_exists(ctx, card_id) == 1
  assert await _card_id(ctx, CARD_2) == compute_card_id(CARD_2)
  assert await _card_id(ctx, CARD_1) == compute_card_id(CARD_1)


@pytest.mark.asyncio
async def test_settle_where_minter_create_invalid_card(ctx_factory):
  ctx = ctx_factory()

  # Given
  assert await _scarcity_max_supply(ctx, 1, 1) == 0

  # When
  await run_scenario(
    ctx,
    [
      (MINTER, 'create_and_mint_card', dict(card=update_dict(CARD_1, season=0), metadata=FELT_METADATA_1, to_account_name=RANDO_1), False),
      (MINTER, 'create_and_mint_card', dict(card=update_dict(CARD_1, serial_number=0), metadata=FELT_METADATA_1, to_account_name=RANDO_1), False),
      (MINTER, 'create_and_mint_card', dict(card=update_dict(CARD_1, season=2 ** 16), metadata=FELT_METADATA_1, to_account_name=RANDO_1), False),
      (MINTER, 'create_and_mint_card', dict(card=update_dict(CARD_1, scarcity=2 ** 8), metadata=FELT_METADATA_1, to_account_name=RANDO_1), False),
      (MINTER, 'create_and_mint_card', dict(card=update_dict(CARD_1, serial_number=2 ** 32), metadata=FELT_METADATA_1, to_account_name=RANDO_1), False),

      (MINTER, 'create_and_mint_card', dict(card=CARD_1, metadata=INVALID_FELT_METADATA_1, to_account_name=RANDO_1), False),
      (MINTER, 'create_and_mint_card', dict(card=CARD_1, metadata=INVALID_FELT_METADATA_2, to_account_name=RANDO_1), False),
      (MINTER, 'create_and_mint_card', dict(card=CARD_1, metadata=INVALID_FELT_METADATA_3, to_account_name=RANDO_1), False),

      (MINTER, 'create_and_mint_card', dict(card=CARD_1, metadata=FELT_METADATA_1, to_account_name=RANDO_1), True),
    ]
  )


@pytest.mark.asyncio
async def test_settle_where_owner_set_uri(ctx_factory):
  ctx = ctx_factory()

  # Given
  uri = [1, 2, 2, 3, 3, 3]
  assert await _get_uri(ctx, to_uint(1)) == [BASE_URI]

  # When
  await run_scenario(
    ctx,
    [
      (OWNER, 'set_uri', dict(uri=uri + uri), True),
      (OWNER, 'set_uri', dict(uri=[32434, 5234, 23, 5324]), True),
      (OWNER, 'set_uri', dict(uri=uri), True),
    ]
  )

  # Then
  assert await _get_uri(ctx, to_uint(1 << 128)) == uri
  assert await _get_uri(ctx, to_uint(1)) == uri


@pytest.mark.asyncio
async def test_settle_where_owner_set_contract_uri(ctx_factory):
  ctx = ctx_factory()

  # Given
  contract_uri = [1, 2, 2, 3, 3, 3]
  assert await _get_contract_uri(ctx) == []

  # When
  await run_scenario(
    ctx,
    [
      (OWNER, 'set_contract_uri', dict(contract_uri=contract_uri + contract_uri), True),
      (OWNER, 'set_contract_uri', dict(contract_uri=[32434, 5234, 23, 5324]), True),
      (OWNER, 'set_contract_uri', dict(contract_uri=contract_uri), True),
    ]
  )

  # Then
  assert await _get_contract_uri(ctx) == contract_uri


@pytest.mark.asyncio
@pytest.mark.parametrize(
  'role_name, initial_members_count',
  [
    (MINTER_ROLE, 2),
    (CAPPER_ROLE, 1),
  ]
)
async def test_settle_where_owner_distribute_role(ctx_factory, role_name, initial_members_count):
  ctx = ctx_factory()

  # Given
  role = await _get_role(ctx, role_name)
  assert role != 0

  assert await _has_role(ctx, role, OWNER) == 1
  assert await _has_role(ctx, role, RANDO_1) == 0
  assert await _has_role(ctx, role, RANDO_2) == 0
  assert await _has_role(ctx, role, RANDO_3) == 0
  assert await _role_members_count(ctx, role) == initial_members_count

  # When
  await run_scenario(
    ctx,
    [
      (RANDO_1, 'grant_role', dict(role_name=role_name, account_name=RANDO_2), False),
      (RANDO_3, 'grant_role', dict(role_name=role_name, account_name=RANDO_3), False),

      (OWNER, 'grant_role', dict(role_name=role_name, account_name=RANDO_1), True),
      (OWNER, 'grant_role', dict(role_name=role_name, account_name=RANDO_2), True),
      (OWNER, 'grant_role', dict(role_name=role_name, account_name=RANDO_1), True),

      (OWNER, 'revoke_role', dict(role_name=role_name, account_name=RANDO_1), True),
      (OWNER, 'revoke_role', dict(role_name=role_name, account_name=OWNER), True),

      (OWNER, 'grant_role', dict(role_name=role_name, account_name=RANDO_1), True),
      (OWNER, 'grant_role', dict(role_name=role_name, account_name=RANDO_3), True),

      (OWNER, 'revoke_role', dict(role_name=role_name, account_name=RANDO_2), True),
      (OWNER, 'revoke_role', dict(role_name=role_name, account_name=RANDO_2), True),

      (OWNER, 'grant_role', dict(role_name=role_name, account_name=RANDO_1), True)
    ]
  )

  assert await _has_role(ctx, role, OWNER) == 0
  assert await _has_role(ctx, role, RANDO_1) == 1
  assert await _has_role(ctx, role, RANDO_2) == 0
  assert await _has_role(ctx, role, RANDO_3) == 1
  assert await _role_members_count(ctx, role) == initial_members_count + 1


@pytest.mark.asyncio
async def test_settle_where_owner_transfer_ownership(ctx_factory):
  ctx = ctx_factory()

  # Given
  owner_address = get_account_address(ctx, OWNER)
  rando1_address = get_account_address(ctx, RANDO_1)
  assert await _owner(ctx) == owner_address

  # When
  await run_scenario(
    ctx,
    [
      (RANDO_1, 'transfer_ownership', dict(account_name=RANDO_2), False),
      (OWNER, 'transfer_ownership', dict(account_name=RANDO_1), True),
      (OWNER, 'transfer_ownership', dict(account_name=RANDO_2), False),
    ]
  )

  # Then
  assert await _owner(ctx) == rando1_address


@pytest.mark.asyncio
async def test_settle_where_owner_renounce_ownership(ctx_factory):
  ctx = ctx_factory()

  # Given
  owner_address = get_account_address(ctx, OWNER)
  assert await _owner(ctx) == owner_address

  # When
  await run_scenario(
    ctx,
    [
      (RANDO_1, 'renounce_ownership', dict(), False),
      (OWNER, 'renounce_ownership', dict(), True),
      (OWNER, 'renounce_ownership', dict(), False),
    ]
  )

  # Then
  assert await _owner(ctx) == 0


@pytest.mark.asyncio
async def test_settle_where_capper_add_scarcity_levels(ctx_factory):
  ctx = ctx_factory()

  # Given
  assert await _scarcity_max_supply(ctx, 1, 0) == SERIAL_NUMBER_MAX
  assert await _scarcity_max_supply(ctx, 1, 1) == 0
  assert await _scarcity_max_supply(ctx, 1, 2) == 0
  assert await _scarcity_max_supply(ctx, 0, 1) == 0

  # When
  await run_scenario(
    ctx,
    [
      (MINTER, 'add_scarcity_for_season', dict(season=1, supply=1000), False),
      (OWNER, 'add_scarcity_for_season', dict(season=1, supply=0), False),
      (OWNER, 'add_scarcity_for_season', dict(season=1, supply=1000), True),
      (OWNER, 'add_scarcity_for_season', dict(season=1, supply=500), True),
      (OWNER, 'add_scarcity_for_season', dict(season=1, supply=10000), True),
      (OWNER, 'add_scarcity_for_season', dict(season=1, supply=0), False),

      (OWNER, 'add_scarcity_for_season', dict(season=2, supply=1), True),
    ]
  )

  # Then
  assert await _scarcity_max_supply(ctx, 1, 0) == SERIAL_NUMBER_MAX
  assert await _scarcity_max_supply(ctx, 1, 1) == 1000
  assert await _scarcity_max_supply(ctx, 1, 2) == 500
  assert await _scarcity_max_supply(ctx, 2, 1) == 1


@pytest.mark.asyncio
async def test_settle_where_minter_create_card_with_invalid_serial_number(ctx_factory):
  ctx = ctx_factory()

  # Given
  card_id_1 = await _card_id(ctx, update_dict(CARD_1, scarcity=1, serial_number=1))
  card_id_2 = await _card_id(ctx, update_dict(CARD_1, scarcity=1, serial_number=2))
  card_id_3 = await _card_id(ctx, update_dict(CARD_1, scarcity=2, serial_number=1))
  assert await _scarcity_max_supply(ctx, 1, 1) == 0

  # When
  await run_scenario(
    ctx,
    [
      (OWNER, 'add_scarcity_for_season', dict(season=1, supply=2), True),

      (MINTER, 'create_and_mint_card', dict(card=update_dict(CARD_1, scarcity=1, serial_number=3), metadata=FELT_METADATA_1, to_account_name=RANDO_1), False),
      (MINTER, 'create_and_mint_card', dict(card=update_dict(CARD_1, scarcity=1, serial_number=1), metadata=FELT_METADATA_1, to_account_name=RANDO_1), True),
      (MINTER, 'create_and_mint_card', dict(card=update_dict(CARD_1, scarcity=1, serial_number=2), metadata=FELT_METADATA_1, to_account_name=RANDO_1), True),

      (OWNER, 'add_scarcity_for_season', dict(season=1, supply=1), True),

      (MINTER, 'create_and_mint_card', dict(card=update_dict(CARD_1, scarcity=2, serial_number=1), metadata=FELT_METADATA_1, to_account_name=RANDO_1), True),
      (MINTER, 'create_and_mint_card', dict(card=update_dict(CARD_1, scarcity=2, serial_number=2), metadata=FELT_METADATA_1, to_account_name=RANDO_1), False),
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
  card_id_1 = await _card_id(ctx, CARD_1)
  card_id_2 = await _card_id(ctx, update_dict(CARD_1, serial_number=2))
  assert await _balance_of(ctx, MINTER, card_id_1) == to_uint(0)
  assert await _balance_of(ctx, MINTER, card_id_2) == to_uint(0)
  assert await _balance_of(ctx, RANDO_1, card_id_1) == to_uint(0)
  assert await _balance_of(ctx, RANDO_1, card_id_2) == to_uint(0)

  # When
  await run_scenario(
    ctx,
    [
      (MINTER, 'create_and_mint_card', dict(card=CARD_1, metadata=FELT_METADATA_1, to_account_name=NULL), False),

      (MINTER, 'create_and_mint_card', dict(card=CARD_1, metadata=FELT_METADATA_1, to_account_name=MINTER), True),
      (MINTER, 'create_and_mint_card', dict(card=update_dict(CARD_1, serial_number=2), metadata=FELT_METADATA_1, to_account_name=RANDO_1), True),

      (MINTER, 'create_and_mint_card', dict(card=CARD_1, metadata=FELT_METADATA_1, to_account_name=MINTER), False),
    ]
  )

  # Then
  assert await _balance_of(ctx, MINTER, card_id_1) == to_uint(1)
  assert await _balance_of(ctx, MINTER, card_id_2) == to_uint(0)
  assert await _balance_of(ctx, RANDO_1, card_id_1) == to_uint(0)
  assert await _balance_of(ctx, RANDO_1, card_id_2) == to_uint(1)


@pytest.mark.asyncio
async def test_settle_where_minter_create_cards_and_mint_them(ctx_factory):
  ctx = ctx_factory()

  # Given
  CARD_2 = update_dict(CARD_1, serial_number=2)
  card_id_1 = await _card_id(ctx, CARD_1)
  card_id_2 = await _card_id(ctx, CARD_2)
  assert await _balance_of(ctx, MINTER, card_id_1) == to_uint(0)
  assert await _balance_of(ctx, MINTER, card_id_2) == to_uint(0)
  assert await _balance_of(ctx, RANDO_1, card_id_1) == to_uint(0)
  assert await _balance_of(ctx, RANDO_1, card_id_2) == to_uint(0)

  # When
  await run_scenario(
    ctx,
    [
      (MINTER, 'create_and_mint_card', dict(card=CARD_1, metadata=FELT_METADATA_1, to_account_name=MINTER), True),
      (MINTER, 'create_and_mint_card', dict(card=CARD_2, metadata=FELT_METADATA_1, to_account_name=RANDO_1), True),
    ]
  )

  # Then
  assert await _balance_of(ctx, MINTER, card_id_1) == to_uint(1)
  assert await _balance_of(ctx, MINTER, card_id_2) == to_uint(0)
  assert await _balance_of(ctx, RANDO_1, card_id_1) == to_uint(0)
  assert await _balance_of(ctx, RANDO_1, card_id_2) == to_uint(1)


@pytest.mark.asyncio
async def test_settle_where_minter_creates_pack(ctx_factory):
  ctx = ctx_factory()

  # Given
  assert await _pack_exists(ctx, to_uint(1)) == 0
  assert await _pack_exists(ctx, to_uint(2)) == 0
  assert await _pack_exists(ctx, to_uint(3)) == 0

  # When
  await run_scenario(
    ctx,
    [
      (MINTER, 'create_pack', dict(max_supply=0x42, metadata=METADATA_1), True),

      (MINTER, 'create_pack', dict(max_supply=0x42, metadata=METADATA_1), True),
    ]
  )

  # Then
  assert await _pack_exists(ctx, to_uint(1)) == 1
  assert await _pack_exists(ctx, to_uint(2)) == 1
  assert await _pack_exists(ctx, to_uint(3)) == 0


@pytest.mark.asyncio
async def test_settle_where_minter_create_packs_and_mint_them_1(ctx_factory):
  ctx = ctx_factory()

  # Given
  assert await _balance_of(ctx, MINTER, to_uint(1)) == to_uint(0)
  assert await _balance_of(ctx, MINTER, to_uint(1)) == to_uint(0)
  assert await _balance_of(ctx, RANDO_1, to_uint(2)) == to_uint(0)
  assert await _balance_of(ctx, RANDO_1, to_uint(2)) == to_uint(0)

  # When
  await run_scenario(
    ctx,
    [
      (MINTER, 'mint_pack', dict(pack_id=to_uint(1), to_account_name=MINTER, amount=1), False),

      (MINTER, 'create_pack', dict(max_supply=5, metadata=METADATA_1), True),
      (MINTER, 'create_pack', dict(max_supply=5, metadata=METADATA_1), True),

      (MINTER, 'mint_pack', dict(pack_id=to_uint(1), to_account_name=MINTER, amount=3), True),
      (MINTER, 'mint_pack', dict(pack_id=to_uint(1), to_account_name=RANDO_1, amount=2), True),
      (MINTER, 'mint_pack', dict(pack_id=to_uint(1), to_account_name=RANDO_1, amount=1), False),

      (MINTER, 'mint_pack', dict(pack_id=to_uint(2), to_account_name=RANDO_1, amount=6), False),
      (MINTER, 'mint_pack', dict(pack_id=to_uint(2), to_account_name=RANDO_1, amount=5), True),
    ]
  )

  # Then
  assert await _balance_of(ctx, MINTER, to_uint(1)) == to_uint(3)
  assert await _balance_of(ctx, MINTER, to_uint(2)) == to_uint(0)
  assert await _balance_of(ctx, RANDO_1, to_uint(1)) == to_uint(2)
  assert await _balance_of(ctx, RANDO_1, to_uint(2)) == to_uint(5)


@pytest.mark.asyncio
async def test_settle_where_tokens_are_transfered(ctx_factory):
  ctx = ctx_factory()

  # When
  await run_scenario(
    ctx,
    [
      (MINTER, 'create_pack', dict(max_supply=0x42, metadata=METADATA_1), True),
      (MINTER, 'create_pack', dict(max_supply=0x42, metadata=METADATA_1), True),
      (MINTER, 'create_pack', dict(max_supply=0x42, metadata=METADATA_1), True),

      (MINTER, 'mint_pack', dict(pack_id=to_uint(1), to_account_name=RANDO_1, amount=5, unlocked=True), True),
      (MINTER, 'mint_pack', dict(pack_id=to_uint(2), to_account_name=RANDO_2, amount=5, unlocked=True), True),
      (MINTER, 'mint_pack', dict(pack_id=to_uint(3), to_account_name=RANDO_3, amount=5, unlocked=True), True),

      (RANDO_1, 'safe_transfer', dict(token_id=to_uint(1), from_account_name=RANDO_1, to_account_name=NULL, amount=5), False),
      (RANDO_3, 'safe_transfer', dict(token_id=to_uint(3), from_account_name=RANDO_1, to_account_name=DEAD, amount=5), False),
      (RANDO_1, 'safe_transfer', dict(token_id=to_uint(1), from_account_name=RANDO_1, to_account_name=RANDO_2, amount=5), True),
      (RANDO_3, 'safe_transfer', dict(token_id=to_uint(3), from_account_name=RANDO_3, to_account_name=RANDO_1, amount=2), True),
      (RANDO_2, 'safe_transfer', dict(token_id=to_uint(1), from_account_name=RANDO_2, to_account_name=RANDO_3, amount=2), True),
      (RANDO_2, 'safe_transfer', dict(token_id=to_uint(2), from_account_name=RANDO_2, to_account_name=RANDO_1, amount=3), True),
      (RANDO_3, 'safe_transfer', dict(token_id=to_uint(1), from_account_name=RANDO_3, to_account_name=RANDO_1, amount=1), True),
      (RANDO_3, 'safe_transfer', dict(token_id=to_uint(1), from_account_name=RANDO_3, to_account_name=RANDO_1, amount=2), False),
    ]
  )

  # Then
  assert await _balance_of(ctx, RANDO_1, to_uint(1)) == to_uint(1)
  assert await _balance_of(ctx, RANDO_1, to_uint(2)) == to_uint(3)
  assert await _balance_of(ctx, RANDO_1, to_uint(3)) == to_uint(2)

  assert await _balance_of(ctx, RANDO_2, to_uint(1)) == to_uint(3)
  assert await _balance_of(ctx, RANDO_2, to_uint(2)) == to_uint(2)
  assert await _balance_of(ctx, RANDO_2, to_uint(3)) == to_uint(0)

  assert await _balance_of(ctx, RANDO_3, to_uint(1)) == to_uint(1)
  assert await _balance_of(ctx, RANDO_3, to_uint(2)) == to_uint(0)
  assert await _balance_of(ctx, RANDO_3, to_uint(3)) == to_uint(3)


@pytest.mark.asyncio
async def test_settle_where_tokens_are_all_approved(ctx_factory):
  ctx = ctx_factory()

  # When
  await run_scenario(
    ctx,
    [
      (MINTER, 'create_pack', dict(max_supply=0x42, metadata=METADATA_1), True),

      (MINTER, 'mint_pack', dict(pack_id=to_uint(1), to_account_name=RANDO_1, amount=5, unlocked=True), True),

      (RANDO_2, 'safe_transfer', dict(token_id=to_uint(1), from_account_name=RANDO_1, to_account_name=RANDO_3, amount=1), False),

      (RANDO_1, 'set_approve_for_all', dict(to_account_name=NULL, approved=True), False),
      (RANDO_1, 'set_approve_for_all', dict(to_account_name=RANDO_2, approved=2), False),
      (RANDO_1, 'set_approve_for_all', dict(to_account_name=RANDO_2, approved=True), True),

      (RANDO_1, 'safe_transfer', dict(token_id=to_uint(1), from_account_name=RANDO_1, to_account_name=RANDO_3, amount=1), True),
      (RANDO_2, 'safe_transfer', dict(token_id=to_uint(1), from_account_name=RANDO_1, to_account_name=RANDO_3, amount=1), True),
      (RANDO_3, 'safe_transfer', dict(token_id=to_uint(1), from_account_name=RANDO_1, to_account_name=RANDO_3, amount=1), False),

      (RANDO_1, 'set_approve_for_all', dict(to_account_name=RANDO_2, approved=False), True),
      (RANDO_1, 'set_approve_for_all', dict(to_account_name=RANDO_3, approved=True), True),

      (RANDO_1, 'safe_transfer', dict(token_id=to_uint(1), from_account_name=RANDO_1, to_account_name=RANDO_3, amount=1), True),
      (RANDO_2, 'safe_transfer', dict(token_id=to_uint(1), from_account_name=RANDO_1, to_account_name=RANDO_3, amount=1), False),
      (RANDO_3, 'safe_transfer', dict(token_id=to_uint(1), from_account_name=RANDO_1, to_account_name=RANDO_2, amount=2), True),

      (RANDO_3, 'set_approve_for_all', dict(to_account_name=RANDO_1, approved=True), True),

      (RANDO_1, 'safe_transfer', dict(token_id=to_uint(1), from_account_name=RANDO_3, to_account_name=RANDO_2, amount=1), True),

      (RANDO_3, 'set_approve_for_all', dict(to_account_name=RANDO_1, approved=False), True),

      (RANDO_1, 'safe_transfer', dict(token_id=to_uint(1), from_account_name=RANDO_3, to_account_name=RANDO_2, amount=1), False),
      (RANDO_3, 'safe_transfer', dict(token_id=to_uint(1), from_account_name=RANDO_3, to_account_name=RANDO_1, amount=1), True),
    ]
  )

  # Then
  assert await _balance_of(ctx, RANDO_1, to_uint(1)) == to_uint(1)
  assert await _balance_of(ctx, RANDO_2, to_uint(1)) == to_uint(3)
  assert await _balance_of(ctx, RANDO_3, to_uint(1)) == to_uint(1)


@pytest.mark.asyncio
async def test_settle_where_minter_create_valid_and_invalid_packs(ctx_factory):
  ctx = ctx_factory()

  # Given
  assert await _pack_exists(ctx, to_uint(1)) == 0
  assert await _pack_exists(ctx, to_uint(2)) == 0

  # When
  await run_scenario(
    ctx,
    [
      (MINTER, 'create_pack', dict(max_supply=0x42, metadata=INVALID_METADATA_1), False),
      (MINTER, 'create_pack', dict(max_supply=0x42, metadata=INVALID_METADATA_2), False),
      (MINTER, 'create_pack', dict(max_supply=0x42, metadata=INVALID_METADATA_3), False),
      (MINTER, 'create_pack', dict(max_supply=0x42, metadata=INVALID_METADATA_4), False),
      (MINTER, 'create_pack', dict(max_supply=0x42, metadata=METADATA_1), True),
    ]
  )

  # Then
  assert await _pack_exists(ctx, to_uint(1)) == 1
  assert await _pack_exists(ctx, to_uint(2)) == 0


@pytest.mark.asyncio
async def test_settle_where_minter_create_valid_and_invalid_common_packs(ctx_factory):
  ctx = ctx_factory()

  # Given
  assert await _pack_exists(ctx, to_uint(1 << 128)) == 0
  assert await _pack_exists(ctx, to_uint(2 << 128)) == 0
  assert await _pack_exists(ctx, to_uint(42 << 128)) == 0
  assert await _pack_exists(ctx, to_uint(41 << 128)) == 0
  assert await _pack_exists(ctx, to_uint(40 << 128)) == 0

  # When
  await run_scenario(
    ctx,
    [
      (MINTER, 'create_common_pack', dict(season=0, metadata=METADATA_1), False),
      (MINTER, 'create_common_pack', dict(season=1, metadata=METADATA_1), True),
      (MINTER, 'create_common_pack', dict(season=1, metadata=METADATA_1), False),
      (MINTER, 'create_common_pack', dict(season=42, metadata=METADATA_1), True),
      (MINTER, 'create_common_pack', dict(season=41, metadata=METADATA_1), True),

      (MINTER, 'create_common_pack', dict(season=40, metadata=INVALID_METADATA_1), False),
      (MINTER, 'create_common_pack', dict(season=40, metadata=INVALID_METADATA_2), False),
      (MINTER, 'create_common_pack', dict(season=40, metadata=INVALID_METADATA_3), False),
      (MINTER, 'create_common_pack', dict(season=40, metadata=INVALID_METADATA_4), False),
      (MINTER, 'create_common_pack', dict(season=40, metadata=METADATA_1), True),
    ]
  )

  # Then
  assert await _pack_exists(ctx, to_uint(1 << 128)) == 1
  assert await _pack_exists(ctx, to_uint(2 << 128)) == 0
  assert await _pack_exists(ctx, to_uint(42 << 128)) == 1
  assert await _pack_exists(ctx, to_uint(41 << 128)) == 1
  assert await _pack_exists(ctx, to_uint(40 << 128)) == 1


@pytest.mark.asyncio
async def test_settle_where_minter_create_packs_and_mint_them_2(ctx_factory):
  ctx = ctx_factory()

  # Given
  assert await _balance_of(ctx, MINTER, to_uint(1)) == to_uint(0)
  assert await _balance_of(ctx, MINTER, to_uint(1)) == to_uint(0)
  assert await _balance_of(ctx, RANDO_1, to_uint(2)) == to_uint(0)
  assert await _balance_of(ctx, RANDO_1, to_uint(2)) == to_uint(0)

  # When
  await run_scenario(
    ctx,
    [
      (MINTER, 'mint_pack', dict(pack_id=to_uint(1 << 128), to_account_name=MINTER, amount=1), False),

      (MINTER, 'create_common_pack', dict(season=1, metadata=METADATA_1), True),

      (MINTER, 'mint_pack', dict(pack_id=to_uint(1 << 128), to_account_name=MINTER, amount=1000000), True),
      (MINTER, 'mint_pack', dict(pack_id=to_uint(1 << 128), to_account_name=RANDO_1, amount=1), True),
      (MINTER, 'mint_pack', dict(pack_id=to_uint(2 << 128), to_account_name=MINTER, amount=1000000), False),

      (MINTER, 'mint_pack', dict(pack_id=to_uint(1 << 128), to_account_name=MINTER, amount=1), True),

      (MINTER, 'mint_pack', dict(pack_id=to_uint(1 << 128), to_account_name=MINTER, amount=1), True),
    ]
  )

  # Then
  assert await _balance_of(ctx, MINTER, to_uint(1 << 128)) == to_uint(1000002)
  assert await _balance_of(ctx, RANDO_1, to_uint(1 << 128)) == to_uint(1)


@pytest.mark.asyncio
async def test_settle_where_owner_open_common_packs_1(ctx_factory):
  ctx = ctx_factory()

  # Given
  CARD_1_2 = update_dict(CARD_1, serial_number=2)
  CARD_2_2 = update_dict(CARD_2, serial_number=2)

  card_id_1 = await _card_id(ctx, CARD_1)
  card_id_1_2 = await _card_id(ctx, CARD_1_2)
  card_id_2_2 = await _card_id(ctx, CARD_2_2)

  assert await _balance_of(ctx, RANDO_1, card_id_1) == to_uint(0)
  assert await _balance_of(ctx, RANDO_1, card_id_1_2) == to_uint(0)
  assert await _balance_of(ctx, RANDO_1, card_id_2_2) == to_uint(0)
  assert await _balance_of(ctx, RANDO_1, to_uint(1 << 128)) == to_uint(0)

  # When
  await run_scenario(
    ctx,
    [
      (MINTER, 'create_common_pack', dict(season=1, metadata=METADATA_1), True),

      (MINTER, 'mint_pack', dict(pack_id=to_uint(1 << 128), to_account_name=RANDO_1, amount=4), True),

      (OWNER, 'open_pack_from', dict(pack_id=to_uint(1 << 128), cards=[CARD_1, CARD_2], metadata=[METADATA_1], from_account_name=RANDO_1), False),

      # cannot double mint
      (OWNER, 'open_pack_from', dict(pack_id=to_uint(1 << 128), cards=[CARD_1, CARD_1], metadata=[FELT_METADATA_1, FELT_METADATA_1], from_account_name=RANDO_1), False),
      (OWNER, 'open_pack_from', dict(pack_id=to_uint(1 << 128), cards=[CARD_1], metadata=[FELT_METADATA_1], from_account_name=RANDO_1), True),
      (OWNER, 'open_pack_from', dict(pack_id=to_uint(1 << 128), cards=[CARD_1], metadata=[FELT_METADATA_1], from_account_name=RANDO_1), False),

      # cannot mint card twice
      (MINTER, 'create_and_mint_card', dict(card=CARD_1, metadata=FELT_METADATA_1, to_account_name=RANDO_2), False),

      # multiples cards
      (OWNER, 'open_pack_from', dict(pack_id=to_uint(1 << 128), cards=[CARD_1_2, CARD_2_2], metadata=[FELT_METADATA_1, FELT_METADATA_1], from_account_name=RANDO_1), True),
    ]
  )

  # Then
  assert await _balance_of(ctx, RANDO_1, card_id_1) == to_uint(1)
  assert await _balance_of(ctx, RANDO_1, card_id_1_2) == to_uint(1)
  assert await _balance_of(ctx, RANDO_1, card_id_2_2) == to_uint(1)
  assert await _balance_of(ctx, RANDO_1, to_uint(1 << 128)) == to_uint(2)


@pytest.mark.asyncio
async def test_settle_where_owner_open_classic_packs_1(ctx_factory):
  ctx = ctx_factory()

  # Given
  CARD_1_2 = update_dict(CARD_1, serial_number=2)
  CARD_3 = update_dict(CARD_1, scarcity=1)

  card_id_1 = await _card_id(ctx, CARD_1)
  card_id_2 = await _card_id(ctx, CARD_2)
  card_id_3 = await _card_id(ctx, CARD_3)
  card_id_1_2 = await _card_id(ctx, CARD_1_2)

  assert await _balance_of(ctx, RANDO_1, card_id_1) == to_uint(0)
  assert await _balance_of(ctx, RANDO_1, card_id_2) == to_uint(0)
  assert await _balance_of(ctx, RANDO_1, card_id_3) == to_uint(0)
  assert await _balance_of(ctx, RANDO_1, card_id_1_2) == to_uint(0)

  assert await _balance_of(ctx, RANDO_1, to_uint(1)) == to_uint(0)

  # When
  await run_scenario(
    ctx,
    [
      (MINTER, 'create_pack', dict(max_supply=0x42, metadata=METADATA_1), True),

      (MINTER, 'mint_pack', dict(pack_id=to_uint(1), to_account_name=RANDO_1, amount=3), True),

      (OWNER, 'open_pack_from', dict(pack_id=to_uint(1), cards=[CARD_1, CARD_2, CARD_1_2], metadata=[FELT_METADATA_1, FELT_METADATA_1, FELT_METADATA_1], from_account_name=RANDO_1), True),
      (OWNER, 'open_pack_from', dict(pack_id=to_uint(1), cards=[CARD_3], metadata=[FELT_METADATA_1, FELT_METADATA_1], from_account_name=RANDO_1), False),

      (OWNER, 'open_pack_from', dict(pack_id=to_uint(1), cards=[CARD_3], metadata=[FELT_METADATA_1], from_account_name=RANDO_1), False),
      (OWNER, 'add_scarcity_for_season', dict(season=1, supply=1), True),
      (OWNER, 'open_pack_from', dict(pack_id=to_uint(1), cards=[CARD_3], metadata=[FELT_METADATA_1], from_account_name=RANDO_1), True),
    ]
  )

  # Then
  assert await _balance_of(ctx, RANDO_1, card_id_1) == to_uint(1)
  assert await _balance_of(ctx, RANDO_1, card_id_2) == to_uint(1)
  assert await _balance_of(ctx, RANDO_1, card_id_3) == to_uint(1)
  assert await _balance_of(ctx, RANDO_1, card_id_1_2) == to_uint(1)

  assert await _balance_of(ctx, RANDO_1, to_uint(1)) == to_uint(1)


@pytest.mark.asyncio
async def test_settle_where_owner_open_classic_packs_2(ctx_factory):
  ctx = ctx_factory()

  # Given
  CARD_3_1 = update_dict(CARD_1, scarcity=1, serial_number=1)
  CARD_3_2 = update_dict(CARD_1, scarcity=1, serial_number=2)
  CARD_3_3 = update_dict(CARD_1, scarcity=1, serial_number=3)
  CARD_3_4 = update_dict(CARD_1, scarcity=1, serial_number=4)
  CARD_3_5 = update_dict(CARD_1, scarcity=1, serial_number=5)

  # When
  await run_scenario(
    ctx,
    [
      (MINTER, 'create_pack', dict(max_supply=0x42, metadata=METADATA_1), True),

      (OWNER, 'add_scarcity_for_season', dict(season=1, supply=4), True),

      (MINTER, 'mint_pack', dict(pack_id=to_uint(1), to_account_name=RANDO_1, amount=1), True),

      (OWNER, 'open_pack_from', dict(pack_id=to_uint(1), cards=[CARD_3_1, CARD_3_2, CARD_3_3], metadata=[FELT_METADATA_1, FELT_METADATA_1, FELT_METADATA_1], from_account_name=RANDO_1), True),
      (MINTER, 'create_and_mint_card', dict(card=CARD_3_4, metadata=FELT_METADATA_1, to_account_name=RANDO_2), True),
      (MINTER, 'create_and_mint_card', dict(card=CARD_3_5, metadata=FELT_METADATA_1, to_account_name=RANDO_2), False),
    ]
  )


@pytest.mark.asyncio
async def test_settle_where_owner_mint_locked_and_unlocked_packs(ctx_factory):
  ctx = ctx_factory()

  # Given
  assert await _balance_of(ctx, RANDO_1, to_uint(1)) == to_uint(0)
  assert await _balance_of(ctx, RANDO_2, to_uint(1)) == to_uint(0)
  assert await _balance_of(ctx, RANDO_3, to_uint(1)) == to_uint(0)

  # When
  await run_scenario(
    ctx,
    [
      (MINTER, 'create_pack', dict(max_supply=0x42, metadata=METADATA_1), True),

      (MINTER, 'mint_pack', dict(pack_id=to_uint(1), to_account_name=RANDO_1, amount=2, unlocked=True), True),
      (RANDO_1, 'safe_transfer', dict(token_id=to_uint(1), from_account_name=RANDO_1, to_account_name=RANDO_3, amount=1), True),

      (MINTER, 'mint_pack', dict(pack_id=to_uint(1), to_account_name=RANDO_1, amount=1, unlocked=True), True),
      (RANDO_1, 'safe_transfer', dict(token_id=to_uint(1), from_account_name=RANDO_1, to_account_name=RANDO_3, amount=2), True),

      (MINTER, 'mint_pack', dict(pack_id=to_uint(1), to_account_name=RANDO_1, amount=2), True),
      (MINTER, 'mint_pack', dict(pack_id=to_uint(1), to_account_name=RANDO_1, amount=1, unlocked=True), True),
      (RANDO_1, 'safe_transfer', dict(token_id=to_uint(1), from_account_name=RANDO_1, to_account_name=RANDO_3, amount=3), False),
      (RANDO_1, 'safe_transfer', dict(token_id=to_uint(1), from_account_name=RANDO_1, to_account_name=RANDO_3, amount=1), True),
    ]
  )

  # Then
  assert await _get_unlocked(ctx, RANDO_1, to_uint(1)) == 0
  assert await _get_unlocked(ctx, RANDO_2, to_uint(1)) == 0
  assert await _get_unlocked(ctx, RANDO_3, to_uint(1)) == 4

  assert await _balance_of(ctx, RANDO_1, to_uint(1)) == to_uint(2)
  assert await _balance_of(ctx, RANDO_2, to_uint(1)) == to_uint(0)
  assert await _balance_of(ctx, RANDO_3, to_uint(1)) == to_uint(4)


# Proxy

@pytest.mark.asyncio
async def test_upgrade(ctx_factory):
  ctx = ctx_factory()

  params = [1, 1, 1]

  # When
  await run_scenario(
    ctx,
    [
      (OWNER, 'initialize', dict(params=params), False),

      (RANDO_1, 'upgrade', dict(new_declared_class_name='upgrade'), False),
      (OWNER, 'upgrade', dict(new_declared_class_name='upgrade'), True),

      (OWNER, 'initialize', dict(params=[]), False),
      (OWNER, 'reset', dict(), True),
      (OWNER, 'initialize', dict(params=[]), True),
      (OWNER, 'initialize', dict(params=[]), False),
    ]
  )


@pytest.mark.asyncio
async def test_settle_where_owner_set_marketplace(ctx_factory):
  ctx = ctx_factory()

  # Given
  assert await _get_marketplace(ctx) == 0x0

  # When
  await run_scenario(
    ctx,
    [
      (MINTER, 'create_pack', dict(max_supply=0x42, metadata=METADATA_1), True),

      (MINTER, 'mint_pack', dict(pack_id=to_uint(1), to_account_name=RANDO_1, amount=2, unlocked=True), True),
      (RANDO_2, 'safe_transfer', dict(token_id=to_uint(1), from_account_name=RANDO_1, to_account_name=RANDO_3, amount=1), False),

      (RANDO_2, 'set_marketplace', dict(contract_name=RANDO_2), False),
      (OWNER, 'set_marketplace', dict(contract_name=RANDO_2), True),

      (RANDO_2, 'safe_transfer', dict(token_id=to_uint(1), from_account_name=RANDO_1, to_account_name=RANDO_3, amount=1), True),

      (OWNER, 'set_marketplace', dict(contract_name=RANDO_3), True),

      (RANDO_2, 'safe_transfer', dict(token_id=to_uint(1), from_account_name=RANDO_1, to_account_name=RANDO_3, amount=1), False),
      (RANDO_3, 'safe_transfer', dict(token_id=to_uint(1), from_account_name=RANDO_1, to_account_name=RANDO_3, amount=1), True),
    ]
  )

  # Then
  assert await _get_marketplace(ctx) == get_account_address(ctx, RANDO_3)
