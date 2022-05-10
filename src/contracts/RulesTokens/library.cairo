%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_le
from starkware.cairo.common.math import assert_le, assert_not_zero, assert_not_equal
from starkware.starknet.common.syscalls import get_caller_address
from lib.memset import uint256_memset

from models.metadata import Metadata
from models.card import Card

# Libraries

from token.ERC1155.ERC1155_base import (
  ERC1155_balance_of,

  ERC1155_safe_mint,
  ERC1155_safe_mint_batch,
  ERC1155_mint_batch,
  ERC1155_burn,
)

from token.ERC1155.ERC1155_Metadata_base import (
  ERC1155_Metadata_token_uri,
)

from token.ERC1155.ERC1155_Supply_base import (
  ERC1155_Supply_exists,
  ERC1155_Supply_total_supply,

  ERC1155_Supply_before_token_transfer,
)

# Interfaces

from contracts.RulesCards.IRulesCards import IRulesCards
from contracts.rulesPacks.IRulesPacks import IRulesPacks

# Constants

from openzeppelin.utils.constants import TRUE, FALSE

#
# Storage
#

@storage_var
func rules_cards_address_storage() -> (rules_cards_address: felt):
end

@storage_var
func rules_packs_address_storage() -> (rules_cards_address: felt):
end

#
# Initializer
#

func RulesTokens_initializer{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(_rules_cards_address: felt, _rules_packs_address: felt):
  rules_cards_address_storage.write(_rules_cards_address)
  rules_packs_address_storage.write(_rules_packs_address)
  return ()
end

#
# Getters
#

func RulesTokens_token_uri{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(token_id: Uint256) -> (token_uri_len: felt, token_uri: felt*):
  let (exists) = ERC1155_Supply_exists(token_id)
  with_attr error_message("Token {token_id} does not exist."):
    assert exists = TRUE
  end

  let (token_uri_len, token_uri) = ERC1155_Metadata_token_uri(token_id)
  return (token_uri_len, token_uri)
end

func RulesTokens_card{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(card_id: Uint256) -> (card: Card, metadata: Metadata):
  let (rules_cards_address) = rules_cards_address_storage.read()

  let (card, metadata) = IRulesCards.getCard(rules_cards_address, card_id)
  return (card, metadata)
end

# Other contracts

func RulesTokens_rules_cards{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }() -> (address: felt):
  let (address) = rules_cards_address_storage.read()
  return (address)
end

func RulesTokens_rules_packs{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }() -> (address: felt):
  let (address) = rules_packs_address_storage.read()
  return (address)
end

#
# Business logic
#

func RulesTokens_create_and_mint_card{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(card: Card, metadata: Metadata, to: felt) -> (token_id: Uint256):
  alloc_locals

  let (rules_cards_address) = rules_cards_address_storage.read()
  let (local card_id) = IRulesCards.createCard(rules_cards_address, card, metadata)

  let data = cast(0, felt*)
  _safe_mint(to, token_id=card_id, amount=Uint256(1, 0), data_len=0, data=data)

  return (token_id=card_id)
end

func RulesTokens_mint_card{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(card_id: Uint256, to: felt) -> (token_id: Uint256):
  let (rules_cards_address) = rules_cards_address_storage.read()
  let (exists) = IRulesCards.cardExists(rules_cards_address, card_id)
  with_attr error_message("Card does not exist"):
    assert exists = TRUE
  end

  let (exists) = ERC1155_Supply_exists(card_id)
  with_attr error_message("Token already minted"):
    assert exists = FALSE
  end

  let data = cast(0, felt*)
  _safe_mint(to, token_id=card_id, amount=Uint256(1, 0), data_len=0, data=data)

  return (token_id=card_id)
end

func RulesTokens_mint_pack{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(pack_id: Uint256, to: felt, amount: felt) -> (token_id: Uint256):
  alloc_locals

  let (rules_packs_address) = rules_packs_address_storage.read()
  let (exists) = IRulesPacks.packExists(rules_packs_address, pack_id)
  with_attr error_message("Pack does not exist"):
    assert exists = TRUE
  end

  let (local supply) = ERC1155_Supply_total_supply(pack_id)
  let (local max_supply) = IRulesPacks.getPackMaxSupply(rules_packs_address, pack_id)

  if max_supply == 0:
    # the pack is a common pack
    let (rules_cards_address) = rules_cards_address_storage.read()
    let (stopped) = IRulesCards.productionStoppedForSeasonAndScarcity(rules_cards_address, season=pack_id.high, scarcity=0)

    with_attr error_message("RulesTokens: Production stopped for the common cards of this season"):
      assert stopped = FALSE
    end

    tempvar syscall_ptr = syscall_ptr
    tempvar pedersen_ptr = pedersen_ptr
    tempvar range_check_ptr = range_check_ptr
  else:
    # the pack is a classic pack
    local felt_supply = supply.low

    with_attr error_message("RulesTokens: Can't mint {amount} packs, amount too high. supply: {felt_supply}, max supply: {max_supply}"):
      assert_le(amount + felt_supply, max_supply)
    end

    tempvar syscall_ptr = syscall_ptr
    tempvar pedersen_ptr = pedersen_ptr
    tempvar range_check_ptr = range_check_ptr
  end

  let data = cast(0, felt*)
  _safe_mint(to, token_id=pack_id, amount=Uint256(amount, 0), data_len=0, data=data)

  return (token_id=pack_id)
end

# Opening

func RulesTokens_open_pack{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    bitwise_ptr: BitwiseBuiltin*,
    range_check_ptr
  }(to: felt, pack_id: Uint256, cards_len: felt, cards: Card*, metadatas_len: felt, metadatas: Metadata*):
  alloc_locals
  with_attr error_message("RulesTokens: cards count and metadata count doesn't match"):
    assert cards_len = metadatas_len
  end

  let (local caller) = get_caller_address()

  # Ensures 'owner' hold at least one pack
  let (balance) = ERC1155_balance_of(caller, pack_id)
  let (valid_amount) = uint256_le(Uint256(1, 0), balance)
  with_attr error_message("RulesTokens: caller does not own this pack"):
    assert valid_amount = TRUE
  end

  # Check if card models are in the pack and `cards_len == cards_per_pack`
  let (rules_packs_address) = rules_packs_address_storage.read()
  let (cards_per_pack, _) = IRulesPacks.getPack(rules_packs_address, pack_id)

  with_attr error_message("RulesTokens: wrong number of cards, expected {cards_per_pack} got {cards_len}"):
    assert cards_per_pack = cards_len
  end
  _assert_cards_presence_in_pack(rules_packs_address, pack_id, cards_len, cards)

  # Create cards
  let (rules_cards_address) = rules_cards_address_storage.read()
  let (card_ids: Uint256*) = alloc()
  _create_cards_batch(rules_cards_address, cards_len, cards, metadatas, card_ids)

  # Mint cards to receipent
  let (amounts: Uint256*) = alloc()
  uint256_memset(dst=amounts, value=Uint256(1, 0), n=cards_len)
  let data = cast(0, felt*)
  # Unsafe to avoid Reetrancy attack which could cancel the opening
  _mint_batch(to=to, ids_len=cards_len, ids=card_ids, amounts_len=cards_len, amounts=amounts, data_len=0, data=data)

  # Burn openned pack
  ERC1155_burn(caller, pack_id, amount=Uint256(1, 0))
  return ()
end

#
# Internals
#

func _assert_cards_presence_in_pack{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(rules_packs_address: felt, pack_id: Uint256, cards_len: felt, cards: Card*):
  if cards_len == 0:
    return ()
  end

  let (quantity) = IRulesPacks.getPackCardModelQuantity(rules_packs_address, pack_id, [cards].model)
  with_attr error_message("RulesTokens: Card {cards_len} not mintable from pack"):
    assert_not_zero(quantity)
  end

  _assert_cards_presence_in_pack(rules_packs_address, pack_id, cards_len=cards_len - 1, cards=cards + Card.SIZE)
  return ()
end

func _safe_mint{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(to: felt, token_id: Uint256, amount: Uint256, data_len: felt, data: felt*):
  let (ids: Uint256*) = alloc()
  assert ids[0] = token_id

  let (amounts: Uint256*) = alloc()
  assert amounts[0] = amount

  ERC1155_Supply_before_token_transfer(_from=0, to=to, ids_len=1, ids=ids, amounts=amounts)

  ERC1155_safe_mint(to, token_id, amount, data_len, data)
  return ()
end

func _safe_mint_batch{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(to: felt, ids_len: felt, ids: Uint256*, amounts_len: felt, amounts: Uint256*, data_len: felt, data: felt*):
  ERC1155_Supply_before_token_transfer(_from=0, to=to, ids_len=ids_len, ids=ids, amounts=amounts)

  ERC1155_safe_mint_batch(to, ids_len, ids, amounts_len, amounts, data_len, data)
  return ()
end

func _mint_batch{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(to: felt, ids_len: felt, ids: Uint256*, amounts_len: felt, amounts: Uint256*, data_len: felt, data: felt*):
  ERC1155_Supply_before_token_transfer(_from=0, to=to, ids_len=ids_len, ids=ids, amounts=amounts)

  ERC1155_mint_batch(to, ids_len, ids, amounts_len, amounts, data_len, data)
  return ()
end

func _create_cards_batch{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(rules_cards_address: felt, cards_len: felt, cards: Card*, metadatas: Metadata*, card_ids: Uint256*):
  if cards_len == 0:
    return ()
  end

  let (card_id) = IRulesCards.createCard(rules_cards_address, [cards], [metadatas])
  assert [card_ids] = card_id

  _create_cards_batch(
    rules_cards_address, cards_len - 1, cards + Card.SIZE, metadatas + Metadata.SIZE, card_ids + Uint256.SIZE
  )
  return ()
end
