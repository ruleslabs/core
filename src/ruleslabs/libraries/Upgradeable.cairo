%lang starknet

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero

// Libraries

from periphery.proxy.library import Proxy

// Storage

@storage_var
func contract_initialized() -> (initialized: felt) {
}

namespace Upgradeable {

  // Modifier

  func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    with_attr error_message("Upgradeable: already initialized") {
      let (initialized) = contract_initialized.read();
      assert initialized = FALSE;
    }

    return ();
  }

  // Init

  func initialize{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    // modifiers
    initializer();

    // body
    contract_initialized.write(TRUE);
    return ();
  }

  // Business logic

  func upgrade{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(implementation: felt) {
    // make sure the target is not null
    with_attr error_message("Upgradeable: new implementation cannot be null") {
      assert_not_zero(implementation);
    }

    // change implementation
    Proxy.set_implementation(implementation);
    return ();
  }
}
