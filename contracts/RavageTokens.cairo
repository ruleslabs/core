%lang starknet
%builtins pedersen range_check

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.registers import get_fp_and_pc

from contracts.models.card import Card

from contracts.token.ERC1155.ERC1155_base import (
  ERC1155_name,
  ERC1155_symbol,

  ERC1155_initializer,
  ERC1155_mint
)

from contracts.token.ERC1155.ERC1155_Metadata_base import (
  ERC1155_Metadata_tokenURI,
  ERC1155_Metadata_baseTokenURI,

  ERC1155_Metadata_setBaseTokenURI
)

from contracts.token.ERC1155.ERC1155_Supply_base import (
  ERC1155_Supply_exists,
  ERC1155_Supply_totalSupply,

  ERC1155_Supply_beforeTokenTransfer
)

from contracts.interfaces.IRavageCards import IRavageCards
# from contracts.interfaces.IRavagePacks import IRavagePacks

const TRUE = 1
const FALSE = 1

#
# Storage
#

@storage_var
func ravage_cards_address_storage() -> (ravage_cards_address: felt):
end

@storage_var
func ravage_packs_address_storage() -> (ravage_cards_address: felt):
end

#
# Events
#

@event
func Transfer(_from: felt, to: felt, token_id: Uint256, amount: Uint256):
end

#
# Constructor
#

@constructor
func constructor{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(
    name: felt,
    symbol: felt,
    owner: felt,
    _ravage_cards_address: felt,
    _ravage_packs_address: felt,
  ):
  ERC1155_initializer(name, symbol)

  ravage_cards_address_storage.write(_ravage_cards_address)
  ravage_packs_address_storage.write(_ravage_packs_address)

  return ()
end

#
# Getters
#

@view
func name{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }() -> (name: felt):
  let (name) = ERC1155_name()
  return (name)
end

@view
func symbol{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }() -> (symbol: felt):
  let (name) = ERC1155_symbol()
  return (name)
end

@view
func tokenURI{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(token_id: Uint256) -> (token_uri_len: felt, token_uri: felt*):
  let (token_uri_len, token_uri) = ERC1155_Metadata_tokenURI(token_id)
  return (token_uri_len, token_uri)
end

@view
func baseTokenURI{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }() -> (base_token_uri_len: felt, base_token_uri: felt*):
  let (base_token_uri_len, base_token_uri) = ERC1155_Metadata_baseTokenURI()
  return (base_token_uri_len, base_token_uri)
end

@view
func getCard{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(card_id: Uint256) -> (card: Card):
  let (ravage_cards_address) = ravage_cards_address_storage.read()

  let (card) = IRavageCards.getCard(ravage_cards_address, card_id)
  return (card)
end

#
# Externals
#

@external
func createAndMintCard{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(
    card: Card,
    to: felt
  ) -> (token_id: Uint256):
  alloc_locals

  let (ravage_cards_address) = ravage_cards_address_storage.read()
  let (local card_id) = IRavageCards.createCard(ravage_cards_address, card)

  _mint_token(to, token_id = card_id, amount = Uint256(1, 0))

  return (token_id = card_id)
end

@external
func mintCard{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(card_id: Uint256, to: felt) -> (token_id: Uint256):
  let (ravage_cards_address) = ravage_cards_address_storage.read()

  let (exists) = IRavageCards.cardExists(ravage_cards_address, card_id)
  assert exists = TRUE # card doesn't exist

  let (exists) = ERC1155_Supply_exists(card_id)
  assert exists = FALSE # token already minted

  _mint_token(to, token_id = card_id, amount = Uint256(1, 0))

  return (token_id = card_id)
end

@external
func setBaseTokenURI{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(base_token_uri_len: felt, base_token_uri: felt*):
  ERC1155_Metadata_setBaseTokenURI(base_token_uri_len, base_token_uri)
  return ()
end

#
# Internals
#

func _mint_token{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(to: felt, token_id: Uint256, amount: Uint256):
  let (ids: Uint256*) = alloc()
  assert ids[0] = token_id

  let (amounts: Uint256*) = alloc()
  assert amounts[0] = amount

  ERC1155_Supply_beforeTokenTransfer(_from = 0, to = to, ids_len = 1, ids = ids, amounts = amounts)

  ERC1155_mint(to, token_id, amount)

  Transfer.emit(_from = 0, to = to, token_id = token_id, amount = amount)

  return ()
end
