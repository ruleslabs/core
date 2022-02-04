%lang starknet
%builtins pedersen range_check bitwise

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.uint256 import Uint256

from contracts.models.card import (
  Card, CardMetadata, get_card_id_from_card, card_is_null
)

from contracts.interfaces.IRavageData import IRavageData

const TRUE = 1
const FALSE = 0

#
# Storage
#

@storage_var
func cards_storage(card_id: Uint256) -> (card: Card):
end

@storage_var
func ravage_data_address_storage() -> (ravage_data_address: felt):
end

#
# Constructor
#

@constructor
func constructor{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    bitwise_ptr: BitwiseBuiltin*,
    range_check_ptr
  }(_ravage_data_address: felt):
  ravage_data_address_storage.write(_ravage_data_address)

  return ()
end

#
# Getters
#

@view
func cardExists{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(card_id: Uint256) -> (res: felt):
  let (card) = cards_storage.read(card_id)
  let (is_null) = card_is_null(card)

  tempvar syscall_ptr = syscall_ptr
  tempvar pedersen_ptr = pedersen_ptr
  tempvar range_check_ptr = range_check_ptr

  if is_null == 1:
      return (FALSE)
  else:
      return (TRUE)
  end
end

@view
func getCard{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(card_id: Uint256) -> (card: Card):
  let (card) = cards_storage.read(card_id)

  return (card)
end

@view
func getCardId{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    bitwise_ptr: BitwiseBuiltin*,
    range_check_ptr
  }(card: Card) -> (card_id: Uint256):
  let (card_id) = get_card_id_from_card(card)

  return (card_id)
end

#
# Externals
#

@external
func createCard{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    bitwise_ptr: BitwiseBuiltin*,
    range_check_ptr
  }(card: Card) -> (card_id: Uint256):
  alloc_locals

  let (ravage_data_address) = ravage_data_address_storage.read()

  let (artist_exists) = IRavageData.artistExists(ravage_data_address, card.artist_name)
  assert_not_zero(artist_exists) # Unknown artist

  let (local card_id) = get_card_id_from_card(card)

  let (exists) = cardExists(card_id)
  assert exists = FALSE # Card already exists

  cards_storage.write(card_id, card)

  return (card_id)
end
