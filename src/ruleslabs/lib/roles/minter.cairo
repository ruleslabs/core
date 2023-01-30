%lang starknet

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address

from ruleslabs.lib.roles.AccessControl_base import (
  AccessControl_has_role,
  AccessControl_grant_role,
  AccessControl_revoke_role,
  _grant_role,
)

// Constants

const MINTER_ROLE = 0x4D494E5445525F524F4C45;  // "MINTER_ROLE"

//
// Constructor
//

func Minter_initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  admin: felt
) {
  _grant_role(MINTER_ROLE, admin);
  return ();
}

//
// Getters
//

func Minter_role{}() -> (role: felt) {
  return (MINTER_ROLE,);
}

//
// Externals
//

func Minter_only_minter{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
  let (caller) = get_caller_address();
  let (has_role) = AccessControl_has_role(MINTER_ROLE, caller);
  with_attr error_message("AccessControl: only minters are authorized to perform this action") {
    assert has_role = TRUE;
  }

  return ();
}

func Minter_grant{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(account: felt) {
  AccessControl_grant_role(MINTER_ROLE, account);
  return ();
}

func Minter_revoke{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  account: felt
) -> () {
  AccessControl_revoke_role(MINTER_ROLE, account);
  return ();
}
