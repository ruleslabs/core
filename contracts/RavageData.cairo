%lang starknet
%builtins pedersen range_check

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from contracts.models.artist import assert_artist_name_well_formed

const TRUE = 1
const FALSE = 0

#
# Storage
#

@storage_var
func artists_storage(artist_name: Uint256) -> (exists: felt):
end

#
# Constructor
#

@constructor
func constructor{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }():
  return ()
end

#
# Getters
#

@view
func artistExists{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(artist_name: Uint256) -> (res: felt):
  let (exists) = artists_storage.read(artist_name)

  return (exists)
end

#
# Externals
#

@external
func createArtist{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(artist_name: Uint256):
  let (exists) = artistExists(artist_name)
  assert exists = 0 # Artist already exists

  assert_artist_name_well_formed(artist_name) # Invalid artist name

  artists_storage.write(artist_name, TRUE)

  return ()
end
