%lang starknet

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import assert_not_zero, assert_le
from starkware.cairo.common.math_cmp import is_not_zero
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_caller_address

from ruleslabs.models.metadata import Metadata, _assert_metadata_are_valid
from ruleslabs.models.card import (
  Card,
  CardModel,
  get_card_id_from_card,
  get_card_from_card_id,
  card_is_null,
)

// Libraries

from ruleslabs.lib.scarcity.Scarcity_base import Scarcity_max_supply, Scarcity_productionStopped

from periphery.proxy.library import Proxy

// Interfaces

from ruleslabs.contracts.RulesData.IRulesData import IRulesData

//
// Storage
//

// Initialization

@storage_var
func contract_initialized() -> (initialized: felt) {
}

// Cards

@storage_var
func cards_metadata_storage(card_id: Uint256) -> (metadata: Metadata) {
}

// Addresses

@storage_var
func rules_data_address_storage() -> (rules_data_address: felt) {
}

namespace RulesCards {
  //
  // Initializer
  //

  func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _rules_data_address: felt
  ) {
    // assert not already initialized
    let (initialized) = contract_initialized.read();
    with_attr error_message("RulesCards: contract already initialized") {
      assert initialized = FALSE;
    }
    contract_initialized.write(TRUE);

    rules_data_address_storage.write(_rules_data_address);
    return ();
  }

  //
  // Getters
  //

  func rules_data{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    address: felt
  ) {
    let (address) = rules_data_address_storage.read();
    return (address,);
  }

  func card_exists{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    card_id: Uint256
  ) -> (res: felt) {
    let (metadata) = cards_metadata_storage.read(card_id);

    if (metadata.multihash_identifier == 0) {
        return (FALSE,);
    } else {
        return (TRUE,);
    }
  }

  func card{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    bitwise_ptr: BitwiseBuiltin*,
    range_check_ptr,
  }(card_id: Uint256) -> (card: Card, metadata: Metadata) {
    let (does_card_exists) = card_exists(card_id);
    with_attr error_message("RulesCard: card does not exist") {
      assert_not_zero(does_card_exists);
    }

    let (card) = get_card_from_card_id(card_id);
    let (metadata) = cards_metadata_storage.read(card_id);

    return (card, metadata);
  }

  func card_id{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(card: Card) -> (
    card_id: Uint256
  ) {
    let (card_id) = get_card_id_from_card(card);
    return (card_id,);
  }

  //
  // Setters
  //

  func upgrade{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    implementation: felt
  ) {
    // make sure the target is not null
    with_attr error_message("RulesCards: new implementation cannot be null") {
      assert_not_zero(implementation);
    }

    // change implementation
    Proxy.set_implementation(implementation);
    return ();
  }

  //
  // Business logic
  //

  func create_card{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    card: Card, metadata: Metadata
  ) -> (card_id: Uint256) {
    alloc_locals;

    _assert_metadata_are_valid(metadata);

    let (is_card_model_creation_allowed) = _is_card_model_creation_allowed(card_model=card.model);
    with_attr error_message("Available supply is null") {
      assert is_card_model_creation_allowed = TRUE;
    }

    // Check if the serial_number is valid, given the scarcity supply
    let (supply) = Scarcity_max_supply(card.model.season, card.model.scarcity);
    let is_supply_set = is_not_zero(supply);

    if (is_supply_set == TRUE) {
      with_attr error_message("RulesCards: Invalid Serial") {
        assert_le(card.serial_number, supply);
      }
      tempvar range_check_ptr = range_check_ptr;
    } else {
      tempvar range_check_ptr = range_check_ptr;
    }

    // Check if card already exists
    let (local card_id) = get_card_id_from_card(card);
    let (exists) = card_exists(card_id);

    with_attr error_message("RulesCards: card already exists") {
      assert exists = FALSE;
    }

    cards_metadata_storage.write(card_id, metadata);

    return (card_id,);
  }

  //
  // Internals
  //

  func _is_card_model_creation_allowed{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
  }(card_model: CardModel) -> (res: felt) {
    let (rules_data_address) = rules_data_address_storage.read();

    // Check if artist exists
    let (artist_exists) = IRulesData.artistExists(rules_data_address, card_model.artist_name);
    if (artist_exists == FALSE) {
      return (FALSE,);
    }

    // Check is production is stopped for this scarcity and season
    let (stopped) = Scarcity_productionStopped(card_model.season, card_model.scarcity);
    if (stopped == TRUE) {
      return (FALSE,);
    }

    return (TRUE,);
  }
}
