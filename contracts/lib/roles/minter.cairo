%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address

from contracts.lib.roles.AccessControl_base import (
  AccessControl_hasRole,

  AccessControl_grant_role,
  AccessControl_revoke_role,
  _grant_role
)

const TRUE = 1
const FALSE = 0

const MINTER_ROLE = 0x4D494E5445525F524F4C45 # "MINTER_ROLE"

#
# Constructor
#

func Minter_initializer{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
  }(admin: felt):
  _grant_role(MINTER_ROLE, admin)
  return ()
end

#
# Getters
#

func Minter_role{}() -> (role: felt):
  return (MINTER_ROLE)
end

#
# Externals
#

func Minter_onlyMinter{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
  }():
  let (caller) = get_caller_address()
  let (has_role) = AccessControl_hasRole(MINTER_ROLE, caller)
  assert has_role = TRUE

  return ()
end

func Minter_grant{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
  }(account: felt):
  AccessControl_grant_role(MINTER_ROLE, account)
  return ()
end

func Minter_revoke{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(account: felt) -> ():
  AccessControl_revoke_role(MINTER_ROLE, account)
  return ()
end
