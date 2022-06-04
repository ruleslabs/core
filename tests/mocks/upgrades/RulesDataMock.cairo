%lang starknet
%builtins pedersen range_check

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

# Libraries

from ruleslabs.contracts.RulesData.library import RulesData
from openzeppelin.upgrades.library import Proxy

#
# Initializer
#

@external
func initialize{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(owner: felt):
  # Should already have an admin since it's an upgraded implementation
  Proxy.assert_only_admin()
  Proxy.initializer(owner)
  return ()
end

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
