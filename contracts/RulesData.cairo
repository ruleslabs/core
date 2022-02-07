%lang starknet
%builtins pedersen range_check

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from contracts.models.artist import assert_artist_name_well_formed

from contracts.lib.Ownable_base import (
  Ownable_get_owner,

  Ownable_initializer,
  Ownable_only_owner,
  Ownable_transfer_ownership
)

from contracts.lib.roles.AccessControl_base import (
  AccessControl_hasRole,
  AccessControl_rolesCount,
  AccessControl_getRoleMember,

  AccessControl_initializer
)

from contracts.lib.roles.minter import (
  Minter_role,

  Minter_initializer,
  Minter_onlyMinter,
  Minter_grant,
  Minter_revoke
)

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
  }(owner: felt):
  Ownable_initializer(owner)
  AccessControl_initializer(owner)
  Minter_initializer(owner)

  return ()
end

#
# Getters
#

# Roles

@view
func MINTER_ROLE{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }() -> (role: felt):
  let (role) = Minter_role()
  return (role)
end

@view
func owner{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }() -> (owner: felt):
  let (owner) = Ownable_get_owner()
  return (owner)
end

@view
func getRoleMember{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(role: felt, index: felt) -> (account: felt):
  let (account) = AccessControl_getRoleMember(role, index)
  return (account)
end

@view
func getRoleMemberCount{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(role: felt) -> (count: felt):
  let (count) = AccessControl_rolesCount(role)
  return (count)
end

@view
func hasRole{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(role: felt, account: felt) -> (has_role: felt):
  let (has_role) = AccessControl_hasRole(role, account)
  return (has_role)
end

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

# Roles

@external
func addMinter{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(account: felt):
  Minter_grant(account)
  return ()
end

@external
func revokeMinter{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(account: felt):
  Minter_revoke(account)
  return ()
end

@external
func createArtist{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(artist_name: Uint256):
  let (exists) = artistExists(artist_name)
  assert exists = 0 # Artist already exists

  Minter_onlyMinter()

  assert_artist_name_well_formed(artist_name) # Invalid artist name

  artists_storage.write(artist_name, TRUE)

  return ()
end

# Ownership

@external
func transferOwnership{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
  }(new_owner: felt) -> (new_owner: felt):
  Ownable_transfer_ownership(new_owner)
  return (new_owner)
end

@external
func renounceOwnership{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
  }():
  Ownable_transfer_ownership(0)
  return ()
end
