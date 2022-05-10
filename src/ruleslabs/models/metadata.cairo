%lang starknet

from starkware.cairo.common.uint256 import Uint256

#
# Structs
#

struct Metadata:
  member hash: Uint256
  member multihash_identifier: felt
end
