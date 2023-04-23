%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address

@storage_var
func Ownable_owner() -> (owner: felt) {
}

namespace Ownable {

  // modifiers

  func only_owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let (owner) = Ownable_owner.read();
    let (caller) = get_caller_address();
    assert owner = caller;
    return ();
  }

  // init

  func initialize{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt
  ) {
    Ownable_owner.write(owner);
    return ();
  }

  // getters

  func owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    owner: felt
  ) {
    let (owner) = Ownable_owner.read();
    return (owner,);
  }

  // setters

  func transfer_ownership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    new_owner: felt
  ) -> (new_owner: felt) {
    // modifiers
    only_owner();

    // body
    Ownable_owner.write(new_owner);
    return (new_owner=new_owner);
  }

  func renounce_ownership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    // modifiers
    only_owner();

    // body
    Ownable_owner.write(0);
    return ();
  }
}
