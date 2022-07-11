%lang starknet

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import assert_le
from starkware.cairo.common.uint256 import (
  Uint256, uint256_eq, uint256_check
)

# Constants

const SEASON_MAX = 2 ** 8 - 1
const SCARCITY_MAX = 2 ** 8 - 1
const SERIAL_NUMBER_MAX = 2 ** 24 - 1

const SEASON_MIN = 1
const SCARCITY_MIN = 0
const SERIAL_NUMBER_MIN = 1

#
# Structs
#

struct CardModel:
  member artist_name: Uint256
  member season: felt # uint16
  member scarcity: felt # uint8
end

struct Card:
  member model: CardModel
  member serial_number: felt # uint32
end

#
# Functions
#

func card_is_null{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(card: Card) -> (res: felt):
  let (is_artist_name_null) = uint256_eq(card.model.artist_name, Uint256(0, 0))
  if is_artist_name_null == FALSE:
    return (FALSE)
  end

  if card.model.season != 0:
    return (FALSE)
  end
  if card.model.scarcity != 0:
    return (FALSE)
  end
  if card.serial_number != 0:
    return (FALSE)
  end

  return (TRUE)
end

func get_card_id_from_card{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(card: Card) -> (card_id: Uint256):
  alloc_locals

  with_attr error_message("card: Card not well formed"):
    _assert_card_well_formed(card)
  end

  # [XXX X X 000] [00000000] [00000000] [00000000] <- card_id
  #  |   | |
  #  |   |  -> scarcity
  #  |    ---> season
  #   -------> serial_number

  let serial_number = card.serial_number * 2 ** 104
  let season = card.model.season * 2 ** 96
  let scarcity = card.model.scarcity * 2 ** 88

  return (card_id=Uint256(card.model.artist_name.low, card.model.artist_name.high + serial_number + season + scarcity))
end

# Guards

func assert_season_is_valid{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(season: felt):
  with_attr error_message("Invalid season"):
    assert_le(season, SEASON_MAX)
    assert_le(SEASON_MIN, season)
  end
  return ()
end

func assert_scarcity_is_valid{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(scarcity: felt):
  with_attr error_message("Invalid scarcity"):
    assert_le(scarcity, SCARCITY_MAX)
    assert_le(SCARCITY_MIN, scarcity)
  end
  return ()
end

func assert_serial_number_is_valid{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(serial_number: felt):
  with_attr error_message("Invalid serial number"):
    assert_le(serial_number, SERIAL_NUMBER_MAX)
    assert_le(SERIAL_NUMBER_MIN, serial_number)
  end
  return ()
end

# Internals

func _assert_card_well_formed{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(card: Card):
  with_attr error_message("Invalid artist name"):
    uint256_check(card.model.artist_name)
  end

  assert_season_is_valid(card.model.season)
  assert_scarcity_is_valid(card.model.scarcity)
  assert_serial_number_is_valid(card.serial_number)

  return ()
end
