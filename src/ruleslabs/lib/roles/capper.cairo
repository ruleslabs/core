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

const CAPPER_ROLE = 0x4341505045525F524F4C45;  // "CAPPER_ROLE"

//
// Constructor
//

func Capper_initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  admin: felt
) {
  _grant_role(CAPPER_ROLE, admin);
  return ();
}

//
// Getters
//

func Capper_role{}() -> (role: felt) {
  return (CAPPER_ROLE,);
}

//
// Externals
//

func Capper_only_capper{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
  let (caller) = get_caller_address();
  let (has_role) = AccessControl_has_role(CAPPER_ROLE, caller);
  with_attr error_message("AccessControl: only cappers are authorized to perform this action") {
    assert has_role = TRUE;
  }

  return ();
}

func Capper_grant{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(account: felt) {
  AccessControl_grant_role(CAPPER_ROLE, account);
  return ();
}

func Capper_revoke{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  account: felt
) -> () {
  AccessControl_revoke_role(CAPPER_ROLE, account);
  return ();
}
