%lang starknet

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.math import assert_not_zero

from ruleslabs.models.card import CardModel, assert_season_is_valid
from ruleslabs.models.metadata import Metadata, _assert_metadata_are_valid

// Libraries

from periphery.proxy.library import Proxy

// Interfaces

from ruleslabs.contracts.RulesData.IRulesData import IRulesData
from ruleslabs.contracts.RulesCards.IRulesCards import IRulesCards

// Constants

from ruleslabs.models.card import SERIAL_NUMBER_MAX, SCARCITY_MIN

//
// Storage
//

// Initialization

@storage_var
func contract_initialized() -> (initialized: felt) {
}

// Packs

@storage_var
func packs_supply_storage() -> (supply: felt) {
}

@storage_var
func packs_max_supply_storage(pack_id: Uint256) -> (max_supply: felt) {
}

@storage_var
func packs_metadata_storage(pack_id: Uint256) -> (metadata: Metadata) {
}

namespace RulesPacks {
  //
  // Initializer
  //

  func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    // assert not already initialized
    let (initialized) = contract_initialized.read();
    with_attr error_message("RulesPacks: contract already initialized") {
      assert initialized = FALSE;
    }
    contract_initialized.write(TRUE);

    return ();
  }

  //
  // Getters
  //

  func pack_exists{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    pack_id: Uint256
  ) -> (res: felt) {
    let (metadata) = packs_metadata_storage.read(pack_id);

    if (metadata.multihash_identifier == 0) {
        return (FALSE,);
    } else {
        return (TRUE,);
    }
  }

  func pack_max_supply{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    pack_id: Uint256
  ) -> (max_supply: felt) {
    let (max_supply) = packs_max_supply_storage.read(pack_id);
    return (max_supply,);
  }

  func pack{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    pack_id: Uint256
  ) -> (metadata: Metadata) {
    let (metadata) = packs_metadata_storage.read(pack_id);

    return (metadata,);
  }

  //
  // Setters
  //

  func upgrade{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    implementation: felt
  ) {
    // make sure the target is not null
    with_attr error_message("RulesPacks: new implementation cannot be null") {
      assert_not_zero(implementation);
    }

    // change implementation
    Proxy.set_implementation(implementation);
    return ();
  }

  //
  // Business logic
  //

  func create_pack{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    max_supply: felt,
    metadata: Metadata,
  ) -> (pack_id: Uint256) {
    alloc_locals;

    _assert_metadata_are_valid(metadata);

    with_attr error_message("RulesPacks: pack max supply cannot be null") {
      assert_not_zero(max_supply);
    }

    let (local supply) = packs_supply_storage.read();
    let pack_id = Uint256(supply + 1, 0);

    packs_max_supply_storage.write(pack_id, max_supply);
    packs_metadata_storage.write(pack_id, metadata);

    packs_supply_storage.write(value=supply + 1);

    return (pack_id,);
  }

  func create_common_pack{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    season: felt, metadata: Metadata
  ) -> (pack_id: Uint256) {

    _assert_metadata_are_valid(metadata);

    assert_season_is_valid(season);

    let pack_id = Uint256(0, season);
    let (exists) = pack_exists(pack_id);
    with_attr error_message("RulesPacks: a common pack already exists for this season") {
      assert exists = FALSE;
    }

    packs_metadata_storage.write(pack_id, metadata);

    return (pack_id,);
  }
}
