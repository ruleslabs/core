%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_check
from starkware.cairo.common.math import assert_not_zero

// Constants

const MULTIHASH_ID = 0x1220;

// Structs

struct Metadata {
  hash: Uint256,
  multihash_identifier: felt,
}

struct FeltMetadata {
  hash: felt,
  multihash_identifier: felt,
}

func _assert_metadata_are_valid{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  metadata: Metadata
) {
  with_attr error_message("Invalid metadata") {
    uint256_check(metadata.hash);
    assert_not_zero(metadata.hash.low);
    assert_not_zero(metadata.hash.high);

    assert metadata.multihash_identifier = MULTIHASH_ID;
  }
  return ();
}

func _assert_felt_metadata_are_valid{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  metadata: FeltMetadata
) {
  with_attr error_message("Invalid metadata") {
    assert_not_zero(metadata.hash);

    assert metadata.multihash_identifier = MULTIHASH_ID;
  }
  return ();
}
