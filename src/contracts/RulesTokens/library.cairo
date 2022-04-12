%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.math import assert_le

from models.metadata import Metadata
from models.card import Card

# Libraries

from token.ERC1155.ERC1155_base import (
  ERC1155_safe_mint,
)

from token.ERC1155.ERC1155_Metadata_base import (
  ERC1155_Metadata_token_uri,
)

from token.ERC1155.ERC1155_Supply_base import (
  ERC1155_Supply_exists,
  ERC1155_Supply_total_supply,

  ERC1155_Supply_before_token_transfer
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
  local felt_supply = supply.low
  with_attr error_message("Can't mint {amount} packs, amount too high. supply: {felt_supply}, max supply: {max_supply}"):
    assert_le(amount + felt_supply, max_supply)
  end

  let data = cast(0, felt*)
  _safe_mint(to, token_id=pack_id, amount=Uint256(amount, 0), data_len=0, data=data)

  return (token_id=pack_id)
end

#
# Internals
#

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
