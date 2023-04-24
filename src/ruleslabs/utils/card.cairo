%lang starknet

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import assert_le, assert_not_zero
from starkware.cairo.common.uint256 import Uint256, uint256_eq, uint256_check

// Constants

const SEASON_MAX = 2 ** 8 - 1;
const SCARCITY_MAX = 2 ** 8 - 1;
const SERIAL_NUMBER_MAX = 2 ** 24 - 1;

const SEASON_MIN = 1;
const SCARCITY_MIN = 0;
const SERIAL_NUMBER_MIN = 1;

const ARTIST_NAME_HIGH_MASK = 2 ** 88 - 1;
const SERIAL_NUMBER_MASK = 2 ** 128 - 2 ** 104;
const SCARCITY_MASK = 2 ** 96 - 2 ** 88;
const SEASON_MASK = 2 ** 104 - 2 ** 96;

const SERIAL_NUMBER_SHIFT = 2 ** 104;
const SEASON_SHIFT = 2 ** 96;
const SCARCITY_SHIFT = 2 ** 88;

//
// Structs
//

struct Card {
  artist_name: Uint256,
  season: felt,  // uint16
  scarcity: felt,  // uint8
  serial_number: felt,  // uint32
}

//
// Functions
//

func _card_to_card_id{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  card: Card
) -> (card_id: Uint256) {

  // [XXX X X 000] [00000000] [00000000] [00000000] <- card_id
  //  |   | |
  //  |   |  -> scarcity
  //  |  ---> season
  //   -------> serial_number

  let serial_number = card.serial_number * SERIAL_NUMBER_SHIFT;
  let season = card.season * SEASON_SHIFT;
  let scarcity = card.scarcity * SCARCITY_SHIFT;

  return (
    card_id=Uint256(card.artist_name.low, card.artist_name.high + serial_number + season + scarcity),
  );
}

func _card_id_to_card{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(
  card_id: Uint256
) -> (card: Card) {
  // artist name
  assert bitwise_ptr[0].x = card_id.high;
  assert bitwise_ptr[0].y = ARTIST_NAME_HIGH_MASK;

  let artist_name = Uint256(card_id.low, bitwise_ptr[0].x_and_y);

  // serial number
  assert bitwise_ptr[1].x = card_id.high;
  assert bitwise_ptr[1].y = SERIAL_NUMBER_MASK;

  let serial_number = bitwise_ptr[1].x_and_y / SERIAL_NUMBER_SHIFT;

  // season
  assert bitwise_ptr[2].x = card_id.high;
  assert bitwise_ptr[2].y = SEASON_MASK;

  let season = bitwise_ptr[2].x_and_y / SEASON_SHIFT;

  // scarcity
  assert bitwise_ptr[3].x = card_id.high;
  assert bitwise_ptr[3].y = SCARCITY_MASK;

  let scarcity = bitwise_ptr[3].x_and_y / SCARCITY_SHIFT;

  let bitwise_ptr = bitwise_ptr + 4 * BitwiseBuiltin.SIZE;

  return (Card(artist_name, season, scarcity, serial_number),);
}

// Guards

func _assert_artist_name_is_valid{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  artist_name: Uint256
) {
  with_attr error_message("Invalid artist name") {
    uint256_check(artist_name);
    assert_not_zero(artist_name.low + artist_name.high);
    assert_le(artist_name.high, ARTIST_NAME_HIGH_MASK);
  }
  return ();
}

func _assert_season_is_valid{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(season: felt) {
  with_attr error_message("Invalid season") {
    assert_le(season, SEASON_MAX);
    assert_le(SEASON_MIN, season);
  }
  return ();
}

func _assert_scarcity_is_valid{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(scarcity: felt) {
  with_attr error_message("Invalid scarcity") {
    assert_le(scarcity, SCARCITY_MAX);
    assert_le(SCARCITY_MIN, scarcity);
  }
  return ();
}

func _assert_serial_number_is_valid{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  serial_number: felt
) {
  with_attr error_message("Invalid serial number") {
    assert_le(serial_number, SERIAL_NUMBER_MAX);
    assert_le(SERIAL_NUMBER_MIN, serial_number);
  }
  return ();
}

func _assert_card_well_formed{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(card: Card) {
  _assert_artist_name_is_valid(card.artist_name);
  _assert_season_is_valid(card.season);
  _assert_scarcity_is_valid(card.scarcity);
  _assert_serial_number_is_valid(card.serial_number);

  return ();
}
