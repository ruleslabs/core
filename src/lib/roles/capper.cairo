%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address

from lib.roles.AccessControl_base import (
  AccessControl_hasRole,

  AccessControl_grant_role,
  AccessControl_revoke_role,
  _grant_role
)

# Constants

from openzeppelin.utils.constants import TRUE, FALSE

const CAPPER_ROLE = 0x4341505045525F524F4C45 # "CAPPER_ROLE"

#
# Constructor
#

func Capper_initializer{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
  }(admin: felt):
  _grant_role(CAPPER_ROLE, admin)
  return ()
end

#
# Getters
#

func Capper_role{}() -> (role: felt):
  return (CAPPER_ROLE)
end

#
# Externals
#

func Capper_onlyCapper{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
  }():
  let (caller) = get_caller_address()
  let (has_role) = AccessControl_hasRole(CAPPER_ROLE, caller)
  assert has_role = TRUE

  return ()
end

func Capper_grant{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
  }(account: felt):
  AccessControl_grant_role(CAPPER_ROLE, account)
  return ()
end

func Capper_revoke{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(account: felt) -> ():
  AccessControl_revoke_role(CAPPER_ROLE, account)
  return ()
end
