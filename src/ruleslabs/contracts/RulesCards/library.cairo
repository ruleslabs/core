%lang starknet

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import assert_not_zero, assert_le
from starkware.cairo.common.math_cmp import is_not_zero
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_caller_address

from ruleslabs.models.metadata import Metadata
from ruleslabs.models.card import (
  Card,
  CardModel,
  get_card_id_from_card,
  get_card_from_card_id,
  card_is_null,
)
from ruleslabs.models.pack import PackCardModel

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

// Card models

@storage_var
func card_models_packed_supply_storage(card_model: CardModel) -> (rules_data_address: felt) {
}

@storage_var
func card_models_supply_storage(card_model: CardModel) -> (rules_data_address: felt) {
}

// Cards

@storage_var
func cards_storage(card_id: Uint256) -> (res: felt) {
}

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
    let (res) = cards_storage.read(card_id);
    return (res,);
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

  func card_model_available_supply{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
  }(card_model: CardModel) -> (available_supply: felt) {
    let (available_supply) = _card_model_available_supply(card_model, FALSE);
    return (available_supply,);
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
    card: Card, metadata: Metadata, packed: felt
  ) -> (card_id: Uint256) {
    alloc_locals;

    let (available_supply) = _card_model_available_supply(card_model=card.model, packed=packed);
    with_attr error_message("Available supply is null") {
      assert_not_zero(available_supply);
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

    if (packed == FALSE) {
      let (supply) = card_models_supply_storage.read(card.model);
      card_models_supply_storage.write(card.model, supply + 1);
      tempvar syscall_ptr = syscall_ptr;
      tempvar pedersen_ptr = pedersen_ptr;
      tempvar range_check_ptr = range_check_ptr;
    } else {
      tempvar syscall_ptr = syscall_ptr;
      tempvar pedersen_ptr = pedersen_ptr;
      tempvar range_check_ptr = range_check_ptr;
    }

    cards_storage.write(card_id, TRUE);
    cards_metadata_storage.write(card_id, metadata);

    return (card_id,);
  }

  func pack_card_model{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    pack_card_model: PackCardModel
  ) {
    let (available_supply) = card_model_available_supply(pack_card_model.card_model);

    with_attr error_message("Card model quantity too high") {
      assert_le(pack_card_model.quantity, available_supply);
    }

    let (packed_supply) = card_models_packed_supply_storage.read(pack_card_model.card_model);
    card_models_packed_supply_storage.write(
      pack_card_model.card_model, packed_supply + pack_card_model.quantity
    );
    return ();
  }

  //
  // Internals
  //

  func _card_model_available_supply{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
  }(card_model: CardModel, packed: felt) -> (available_supply: felt) {
    let (rules_data_address) = rules_data_address_storage.read();

    // Check if artist exists
    let (artist_exists) = IRulesData.artistExists(rules_data_address, card_model.artist_name);
    if (artist_exists == FALSE) {
      return (available_supply=0);
    }

    // Check is production is stopped for this scarcity and season
    let (stopped) = Scarcity_productionStopped(card_model.season, card_model.scarcity);
    if (stopped == TRUE) {
      return (available_supply=0);
    }

    // Check max supply
    let (max_supply) = Scarcity_max_supply(card_model.season, card_model.scarcity);
    if (max_supply == 0) {
      return (available_supply=0);
    }

    if (packed == TRUE) {
      return (1,);  // return anything above 0
    }

    // Get supply and packed supply

    let (supply) = card_models_supply_storage.read(card_model);
    let (packed_supply) = card_models_packed_supply_storage.read(card_model);
    return (max_supply - supply - packed_supply,);
  }
}
