%lang starknet

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.math import assert_not_zero

from ruleslabs.models.card import CardModel, assert_season_is_valid
from ruleslabs.models.metadata import Metadata
from ruleslabs.models.pack import PackCardModel, get_pack_max_supply, assert_cards_per_pack_is_valid

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
func packs_cards_per_pack_storage(pack_id: Uint256) -> (cards_per_pack: felt) {
}

@storage_var
func packs_max_supply_storage(pack_id: Uint256) -> (max_supply: felt) {
}

@storage_var
func packs_card_models_len_storage(pack_id: Uint256) -> (len: felt) {
}

@storage_var
func packs_card_models_storage(pack_id: Uint256, index: felt) -> (pack_card_model: PackCardModel) {
}

@storage_var
func packs_card_models_quantity_storage(pack_id: Uint256, card_model: CardModel) -> (
  quantity: felt
) {
}

@storage_var
func packs_metadata_storage(pack_id: Uint256) -> (metadata: Metadata) {
}

@storage_var
func rules_data_address_storage() -> (rules_data_address: felt) {
}

@storage_var
func rules_cards_address_storage() -> (rules_cards_address: felt) {
}

namespace RulesPacks {
  //
  // Initializer
  //

  func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _rules_data_address: felt, _rules_cards_address: felt
  ) {
    // assert not already initialized
    let (initialized) = contract_initialized.read();
    with_attr error_message("RulesPacks: contract already initialized") {
      assert initialized = FALSE;
    }
    contract_initialized.write(TRUE);

    rules_data_address_storage.write(_rules_data_address);
    rules_cards_address_storage.write(_rules_cards_address);
    return ();
  }

  //
  // Getters
  //

  func pack_exists{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    pack_id: Uint256
  ) -> (res: felt) {
    let (cards_per_pack) = packs_cards_per_pack_storage.read(pack_id);

    tempvar syscall_ptr = syscall_ptr;
    tempvar pedersen_ptr = pedersen_ptr;
    tempvar range_check_ptr = range_check_ptr;

    if (cards_per_pack == 0) {
      return (FALSE,);
    } else {
      return (TRUE,);
    }
  }

  func pack_card_model_quantity{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    pack_id: Uint256, card_model: CardModel
  ) -> (res: felt) {
    if (pack_id.low == 0) {
      let (cards_per_pack) = packs_cards_per_pack_storage.read(pack_id);
      if (cards_per_pack == 0) {
        return (0,);
      }

      if (card_model.season != pack_id.high) {
        return (0,);
      }
      if (card_model.scarcity != SCARCITY_MIN) {
        return (0,);
      }

      // Check if artist exists
      let (rules_data_address) = rules_data_address_storage.read();
      let (artist_exists) = IRulesData.artistExists(
        rules_data_address, card_model.artist_name
      );
      if (artist_exists == FALSE) {
        return (0,);
      }
      return (SERIAL_NUMBER_MAX,);
    } else {
      let (quantity) = packs_card_models_quantity_storage.read(pack_id, card_model);
      return (quantity,);
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
  ) -> (cards_per_pack: felt, metadata: Metadata) {
    let (cards_per_pack) = packs_cards_per_pack_storage.read(pack_id);
    let (metadata) = packs_metadata_storage.read(pack_id);

    return (cards_per_pack, metadata);
  }

  func rules_cards_address{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    address: felt
  ) {
    let (address) = rules_cards_address_storage.read();
    return (address,);
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
    cards_per_pack: felt,
    pack_card_models_len: felt,
    pack_card_models: PackCardModel*,
    metadata: Metadata,
  ) -> (pack_id: Uint256) {
    alloc_locals;

    let (pack_max_supply) = get_pack_max_supply(
      cards_per_pack, pack_card_models_len, pack_card_models
    );

    let (local supply) = packs_supply_storage.read();
    let pack_id = Uint256(supply + 1, 0);

    packs_cards_per_pack_storage.write(pack_id, cards_per_pack);
    packs_max_supply_storage.write(pack_id, pack_max_supply);
    packs_metadata_storage.write(pack_id, metadata);
    packs_card_models_len_storage.write(pack_id, pack_card_models_len);
    _write_pack_card_models_to_storage(pack_id, pack_card_models_len, pack_card_models);

    packs_supply_storage.write(value=supply + 1);

    return (pack_id,);
  }

  func create_common_pack{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    cards_per_pack: felt, season: felt, metadata: Metadata
  ) -> (pack_id: Uint256) {
    assert_season_is_valid(season);
    assert_cards_per_pack_is_valid(cards_per_pack);

    let pack_id = Uint256(0, season);
    let (exists) = pack_exists(pack_id);
    with_attr error_message("RulesPacks: a common pack already exists for this season") {
      assert exists = FALSE;
    }

    packs_cards_per_pack_storage.write(pack_id, cards_per_pack);
    packs_metadata_storage.write(pack_id, metadata);

    return (pack_id,);
  }

  //
  // Internals
  //

  func _write_pack_card_models_to_storage{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
  }(pack_id: Uint256, pack_card_models_len: felt, pack_card_models: PackCardModel*) {
    if (pack_card_models_len == 0) {
      return ();
    }

    let index = pack_card_models_len - 1;
    let pack_card_model = pack_card_models[index];

    packs_card_models_quantity_storage.write(
      pack_id, pack_card_model.card_model, pack_card_model.quantity
    );
    packs_card_models_storage.write(pack_id, index, pack_card_model);

    _increase_pack_card_model_packed_supply(pack_card_model);

    _write_pack_card_models_to_storage(
      pack_id=pack_id, pack_card_models_len=index, pack_card_models=pack_card_models
    );
    return ();
  }

  func _increase_pack_card_model_packed_supply{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
  }(pack_card_model: PackCardModel) {
    let (rules_cards_address) = rules_cards_address_storage.read();
    IRulesCards.packCardModel(rules_cards_address, pack_card_model);

    return ();
  }

  //#########################################################################################
  // MIGHT BE USEFUL IN A FUTURE VERSION OF CAIRO WHICH SUPPORTS RETURNING ARRAY OF STRUCTS #
  //#########################################################################################

  func _retrieve_pack_card_models_from_storage{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
  }(pack_id: Uint256, pack_card_models: PackCardModel*) -> (pack_card_models_len: felt) {
    alloc_locals;

    let (local pack_card_models_len) = packs_card_models_len_storage.read(pack_id);
    _retrieve_pack_card_models_from_storage_with_len(
      pack_id, pack_card_models_len, pack_card_models
    );

    return (pack_card_models_len,);
  }

  func _retrieve_pack_card_models_from_storage_with_len{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
  }(pack_id: Uint256, pack_card_models_len: felt, pack_card_models: PackCardModel*) {
    if (pack_card_models_len == 0) {
      return ();
    }

    let index = pack_card_models_len - 1;

    let (pack_card_model) = packs_card_models_storage.read(pack_id, index);
    assert pack_card_models[index] = pack_card_model;
    _retrieve_pack_card_models_from_storage_with_len(
      pack_id=pack_id, pack_card_models_len=index, pack_card_models=pack_card_models
    );

    return ();
  }
}
