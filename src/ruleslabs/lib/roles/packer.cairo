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

const PACKER_ROLE = 0x5041434B45525F524F4C45;  // "PACKER_ROLE"

//
// Constructor
//

func Packer_initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  admin: felt
) {
  _grant_role(PACKER_ROLE, admin);
  return ();
}

//
// Getters
//

func Packer_role{}() -> (role: felt) {
  return (PACKER_ROLE,);
}

//
// Externals
//

func Packer_only_packer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
  let (caller) = get_caller_address();
  let (has_role) = AccessControl_has_role(PACKER_ROLE, caller);
  with_attr error_message("AccessControl: only packers are authorized to perform this action") {
    assert has_role = TRUE;
  }

  return ();
}

func Packer_grant{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(account: felt) {
  AccessControl_grant_role(PACKER_ROLE, account);
  return ();
}

func Packer_revoke{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  account: felt
) -> () {
  AccessControl_revoke_role(PACKER_ROLE, account);
  return ();
}
