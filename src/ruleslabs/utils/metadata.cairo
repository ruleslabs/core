%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_check
from starkware.cairo.common.math import assert_not_zero

//
// Structs
//

struct Metadata {
  hash: Uint256,
  multihash_identifier: felt,
}

func _assert_metadata_are_valid{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  metadata: Metadata
) {
  with_attr error_message("Invalid metadata") {
    uint256_check(metadata.hash);
    assert_not_zero(metadata.hash.low);
    assert_not_zero(metadata.hash.high);
    assert_not_zero(metadata.multihash_identifier);
  }
  return ();
}
