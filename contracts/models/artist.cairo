from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import (
  Uint256, uint256_eq, uint256_check
)

const TRUE = 1
const FALSE = 0

func assert_artist_name_well_formed{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(artist_name: Uint256):
  uint256_check(artist_name)

  let (is_null) = uint256_eq(artist_name, Uint256(0, 0))
  assert is_null = FALSE

  return ()
end
