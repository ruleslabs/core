%lang starknet
%builtins pedersen range_check

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

# Libraries

from ruleslabs.contracts.RulesData.library import RulesData

@view
func artistExists{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(artist_name: Uint256) -> (res: felt):
  let (exists) = RulesData.artist_exists(artist_name)
  return (exists)
end

@external
func createArtist{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(artist_name: Uint256):
  RulesData.create_artist(artist_name)
  return ()
end
