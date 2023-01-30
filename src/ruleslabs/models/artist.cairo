%lang starknet

from starkware.cairo.common.bool import FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_le
from starkware.cairo.common.uint256 import Uint256, uint256_eq, uint256_check

const ARTIST_NAME_HIGH_MAX = 2 ** 88 - 1;

//
// Functions
//

func assert_artist_name_well_formed{
  syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(artist_name: Uint256) {
  with_attr error_message("artist_name is not a valid Uint256") {
    uint256_check(artist_name);
  }

  with_attr error_message("artist_name cannot be null") {
    let (is_null) = uint256_eq(artist_name, Uint256(0, 0));
    assert is_null = FALSE;
  }

  with_attr error_message("artist_name cannot exceed 27 characters") {
    assert_le(artist_name.high, ARTIST_NAME_HIGH_MAX);
  }

  return ();
}
