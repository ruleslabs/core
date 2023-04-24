%lang starknet

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import get_caller_address

const ADMIN_ROLE_ID = 0x0;

//
// Storage
//

@storage_var
func roles_storage(role: felt, index: felt) -> (account: felt) {
}

@storage_var
func roles_storage_len(role: felt) -> (accounts_len: felt) {
}

//
// Events
//

@event
func RoleGranted(role: felt, account: felt) {
}

@event
func RoleRevoked(role: felt, account: felt) {
}

namespace AccessControl {

  // modifiers

  func only_role{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(role: felt) {
    let (caller) = get_caller_address();
    let (caller_has_role) = has_role(role, caller);
    with_attr error_message("AccessControl: only {role} is authorized to perform this action") {
      assert caller_has_role = TRUE;
    }

    return ();
  }

  func only_admin{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    only_role(ADMIN_ROLE_ID);
    return ();
  }

  // Init

  func initialize{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    admin: felt
  ) {
    roles_storage.write(role=ADMIN_ROLE_ID, index=0, value=admin);
    roles_storage_len.write(role=ADMIN_ROLE_ID, value=1);

    return ();
  }

  // Getters

  func has_role{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    role: felt, account: felt
  ) -> (res: felt) {
    let (accounts_len: felt) = roles_storage_len.read(role);
    let (has_role) = _has_role(role, account, accounts_len);

    return (has_role,);
  }

  func roles_count{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    role: felt
  ) -> (count: felt) {
    let (accounts_len: felt) = roles_storage_len.read(role);

    return (accounts_len,);
  }

  func role_member{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    role: felt, index: felt
  ) -> (account: felt) {
    let (account) = roles_storage.read(role, index);
    return (account,);
  }

  // Setters

  func grant_role{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    role: felt, account: felt
  ) {
    // modifiers
    only_admin();

    // body
    _grant_role(role, account);

    return ();
  }

  func revoke_role{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    role: felt, account: felt
  ) {
    alloc_locals;

    // modifiers
    only_admin();

    // body
    let (local accounts_len) = roles_storage_len.read(role);
    _revoke_role(role, account);

    let (new_accounts_len) = roles_storage_len.read(role);
    if (accounts_len == new_accounts_len) {
      return ();
    }

    RoleRevoked.emit(role, account);

    return ();
  }

  // Internals

  func _array_of_accounts{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    role: felt, exclude: felt, accounts_len: felt, accounts: felt*
  ) -> (len: felt) {
    if (accounts_len == 0) {
      return (0,);
    }

    let (next_account: felt) = roles_storage.read(role, accounts_len - 1);

    if (next_account != exclude) {
      assert accounts[0] = next_account;
      let (len) = _array_of_accounts(role, exclude, accounts_len - 1, accounts + 1);
      return (len + 1,);
    } else {
      let (len) = _array_of_accounts(role, exclude, accounts_len - 1, accounts);
      return (len,);
    }
  }

  func _store_array_of_accounts{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    role: felt, accounts_len: felt, accounts: felt*
  ) {
    if (accounts_len == 0) {
      return ();
    }

    roles_storage.write(role, accounts_len - 1, [accounts]);

    _store_array_of_accounts(role, accounts_len - 1, accounts + 1);
    return ();
  }

  func _grant_role{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    role: felt, account: felt
  ) {
    alloc_locals;

    let (local accounts_len: felt) = roles_storage_len.read(role);
    let (already_has_role) = _has_role(role, account, accounts_len);
    if (already_has_role == TRUE) {
      return ();
    }

    roles_storage.write(role=role, index=accounts_len, value=account);
    roles_storage_len.write(role, accounts_len + 1);

    RoleGranted.emit(role, account);

    return ();
  }

  func _revoke_role{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    role: felt, account: felt
  ) {
    alloc_locals;

    let (local accounts: felt*) = alloc();
    let (accounts_len) = roles_storage_len.read(role);
    let (len) = _array_of_accounts(
      role=role, exclude=account, accounts_len=accounts_len, accounts=accounts
    );

    roles_storage_len.write(role, len);

    _store_array_of_accounts(role, len, accounts);
    return ();
  }

  func _has_role{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    role: felt, account: felt, accounts_len: felt
  ) -> (has_role: felt) {
    if (accounts_len == 0) {
      return (FALSE,);
    }

    let (granted_account: felt) = roles_storage.read(role=role, index=accounts_len - 1);

    if (granted_account == account) {
      return (TRUE,);
    }

    let (has_role) = _has_role(role, account, accounts_len - 1);
    return (has_role,);
  }
}
