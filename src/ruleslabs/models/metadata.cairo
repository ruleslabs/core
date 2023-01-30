%lang starknet

from starkware.cairo.common.uint256 import Uint256

//
// Structs
//

struct Metadata {
  hash: Uint256,
  multihash_identifier: felt,
}
