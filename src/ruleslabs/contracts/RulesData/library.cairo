%lang starknet

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.math import assert_not_zero

from ruleslabs.models.artist import assert_artist_name_well_formed

// Libraries

from periphery.proxy.library import Proxy

//
// Storage
//

// Initialization

@storage_var
func contract_initialized() -> (initialized: felt) {
}

// Artists

@storage_var
func artists_storage(artist_name: Uint256) -> (exists: felt) {
}

namespace RulesData {
  //
  // Initializer
  //

  func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    // assert not already initialized
    let (initialized) = contract_initialized.read();
    with_attr error_message("RulesData: contract already initialized") {
      assert initialized = FALSE;
    }
    contract_initialized.write(TRUE);

    return ();
  }

  //
  // Getters
  //

  func artist_exists{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    artist_name: Uint256
  ) -> (res: felt) {
    let (exists) = artists_storage.read(artist_name);
    return (exists,);
  }

  //
  // Setters
  //

  func upgrade{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    implementation: felt
  ) {
    // make sure the target is not null
    with_attr error_message("RulesData: new implementation cannot be null") {
      assert_not_zero(implementation);
    }

    // change implementation
    Proxy.set_implementation(implementation);
    return ();
  }

  //
  // Business logic
  //

  func create_artist{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    artist_name: Uint256
  ) {
    let (exists) = artist_exists(artist_name);
    assert exists = 0;  // Artist already exists

    assert_artist_name_well_formed(artist_name);  // Invalid artist name

    artists_storage.write(artist_name, TRUE);

    return ();
  }
}
