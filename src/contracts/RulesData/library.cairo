%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from models.artist import assert_artist_name_well_formed

# Constants

from openzeppelin.utils.constants import TRUE

#
# Storage
#

@storage_var
func artists_storage(artist_name: Uint256) -> (exists: felt):
end

#
# Getters
#

func RulesData_artist_exists{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(artist_name: Uint256) -> (res: felt):
  let (exists) = artists_storage.read(artist_name)
  return (exists)
end

#
# Business logic
#

func RulesData_create_artist{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(artist_name: Uint256):
  let (exists) = RulesData_artist_exists(artist_name)
  assert exists = 0 # Artist already exists

  assert_artist_name_well_formed(artist_name) # Invalid artist name

  artists_storage.write(artist_name, TRUE)

  return ()
end
