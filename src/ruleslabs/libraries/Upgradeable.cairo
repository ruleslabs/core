%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero

// Libraries

from periphery.proxy.library import Proxy


namespace Upgradeable {

  func upgrade{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    implementation: felt
  ) {
    // make sure the target is not null
    with_attr error_message("RulesTokens: new implementation cannot be null") {
      assert_not_zero(implementation);
    }

    // change implementation
    Proxy.set_implementation(implementation);
    return ();
  }
}
