%lang starknet

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.alloc import alloc
from ruleslabs.lib.keccak import keccak256
from starkware.cairo.common.math import assert_le
from starkware.cairo.common.uint256 import (
  Uint256, uint256_eq, uint256_check
)

# Constants

const SEASON_MAX = 2 ** 16 - 1
const SCARCITY_MAX = 2 ** 8 - 1
const SERIAL_NUMBER_MAX = 2 ** 32 - 1

const SEASON_MIN = 1
const SCARCITY_MIN = 0
const SERIAL_NUMBER_MIN = 1

const SHIFT = 2 ** 64
const MASK = 2 ** 64 - 1

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
    bitwise_ptr : BitwiseBuiltin*,
    range_check_ptr
  }(card: Card) -> (card_id: Uint256):
  alloc_locals

  with_attr error_message("card: Card not well formed"):
    _assert_card_well_formed(card)
  end

  let (local keccak_ptr : felt*) = alloc()
  let (local keccak_input : felt*) = alloc()

  # artist_name

  assert bitwise_ptr[0].x = card.model.artist_name.high
  assert bitwise_ptr[0].y = MASK
  assert keccak_input[1] = bitwise_ptr[0].x_and_y

  let (res, _) = unsigned_div_rem(card.model.artist_name.high, SHIFT)
  assert keccak_input[0] = res

  assert bitwise_ptr[1].x = card.model.artist_name.low
  assert bitwise_ptr[1].y = MASK
  assert keccak_input[3] = bitwise_ptr[1].x_and_y

  let (res, _) = unsigned_div_rem(card.model.artist_name.low, SHIFT)
  assert keccak_input[2] = res

  let bitwise_ptr = bitwise_ptr + 2 * BitwiseBuiltin.SIZE

  # [0 XX X XXXX]
  #    |  |  |
  #    |  |   -> serial_number
  #    |   ----> scarcity
  #     -------> season

  assert bitwise_ptr[0].x = card.model.season
  assert bitwise_ptr[0].y = 0xffff
  let season = bitwise_ptr[0].x_and_y
  let season = season * 2 ** 40

  assert bitwise_ptr[1].x = card.model.scarcity
  assert bitwise_ptr[1].y = 0xff
  let scarcity = bitwise_ptr[1].x_and_y
  let scarcity = scarcity * 2 ** 32

  assert bitwise_ptr[2].x = card.serial_number
  assert bitwise_ptr[2].y = 0xffffffff
  let serial_number = bitwise_ptr[2].x_and_y

  assert bitwise_ptr[3].x = season
  assert bitwise_ptr[3].y = scarcity
  assert bitwise_ptr[4].x = bitwise_ptr[3].x_or_y
  assert bitwise_ptr[4].y = serial_number
  assert keccak_input[4] = bitwise_ptr[4].x_or_y

  let bitwise_ptr = bitwise_ptr + 5 * BitwiseBuiltin.SIZE

  let (keccak_output) = keccak256{keccak_ptr = keccak_ptr}(input = keccak_input, n_bytes = 39)

  let low = keccak_output[2] * SHIFT + keccak_output[3]
  let high = keccak_output[0] * SHIFT + keccak_output[1]

  return (card_id = Uint256(low, high))
end

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
