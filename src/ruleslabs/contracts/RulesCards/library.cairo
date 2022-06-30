%lang starknet

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import assert_not_zero, assert_le
from starkware.cairo.common.math_cmp import is_not_zero
from starkware.cairo.common.uint256 import Uint256

from ruleslabs.models.metadata import Metadata
from ruleslabs.models.card import Card, CardModel, get_card_id_from_card, card_is_null
from ruleslabs.models.pack import PackCardModel

# Libraries

from ruleslabs.lib.scarcity.Scarcity_base import (
  Scarcity_max_supply,
  Scarcity_productionStopped,
)

from periphery.proxy.library import Proxy

# Interfaces

from ruleslabs.contracts.RulesData.IRulesData import IRulesData

#
# Storage
#

# Initialization

@storage_var
func contract_initialized() -> (initialized: felt):
end

# Card models

@storage_var
func card_models_packed_supply_storage(card_model: CardModel) -> (rules_data_address: felt):
end

@storage_var
func card_models_supply_storage(card_model: CardModel) -> (rules_data_address: felt):
end

# Cards

@storage_var
func cards_storage(card_id: Uint256) -> (card: Card):
end

@storage_var
func cards_metadata_storage(card_id: Uint256) -> (metadata: Metadata):
end

# Addresses

@storage_var
func rules_data_address_storage() -> (rules_data_address: felt):
end

namespace RulesCards:

  #
  # Initializer
  #

  func initializer{
      syscall_ptr: felt*,
      pedersen_ptr: HashBuiltin*,
      range_check_ptr
    }(_rules_data_address: felt):
    # assert not already initialized
    let (initialized) = contract_initialized.read()
    with_attr error_message("RulesCards: contract already initialized"):
        assert initialized = FALSE
    end
    contract_initialized.write(TRUE)

    rules_data_address_storage.write(_rules_data_address)
    return ()
  end

  #
  # Getters
  #

  func rules_data{
      syscall_ptr: felt*,
      pedersen_ptr: HashBuiltin*,
      range_check_ptr
    }() -> (address: felt):
    let (address) = rules_data_address_storage.read()
    return (address)
  end

  func card_exists{
      syscall_ptr: felt*,
      pedersen_ptr: HashBuiltin*,
      range_check_ptr
    }(card_id: Uint256) -> (res: felt):
    let (card) = cards_storage.read(card_id)
    let (is_null) = card_is_null(card)

    tempvar syscall_ptr = syscall_ptr
    tempvar pedersen_ptr = pedersen_ptr
    tempvar range_check_ptr = range_check_ptr

    if is_null == 1:
        return (FALSE)
    else:
        return (TRUE)
    end
  end

  func card{
      syscall_ptr: felt*,
      pedersen_ptr: HashBuiltin*,
      range_check_ptr
    }(card_id: Uint256) -> (card: Card, metadata: Metadata):
    let (card) = cards_storage.read(card_id)
    let (metadata) = cards_metadata_storage.read(card_id)

    return (card, metadata)
  end

  func card_id{
      syscall_ptr: felt*,
      pedersen_ptr: HashBuiltin*,
      bitwise_ptr: BitwiseBuiltin*,
      range_check_ptr
    }(card: Card) -> (card_id: Uint256):
    let (card_id) = get_card_id_from_card(card)
    return (card_id)
  end

  func card_model_available_supply{
      syscall_ptr: felt*,
      pedersen_ptr: HashBuiltin*,
      range_check_ptr
    }(card_model: CardModel) -> (available_supply: felt):
    let (rules_data_address) = rules_data_address_storage.read()

    # Check if artist exists
    let (artist_exists) = IRulesData.artistExists(rules_data_address, card_model.artist_name)
    if artist_exists == FALSE:
      return (available_supply=0)
    end

    # Check is production is stopped for this scarcity and season
    let (stopped) = Scarcity_productionStopped(card_model.season, card_model.scarcity)
    if stopped == TRUE:
      return (available_supply=0)
    end

    # Check max supply
    let (max_supply) = Scarcity_max_supply(card_model.season, card_model.scarcity)
    if max_supply == 0:
      return (available_supply=0)
    end

    # Get supply and packed supply
    let (packed_supply) = card_models_packed_supply_storage.read(card_model)
    let (supply) = card_models_supply_storage.read(card_model)

    return (max_supply - supply - packed_supply)
  end

  #
  # Setters
  #

  func upgrade{
      syscall_ptr : felt*,
      pedersen_ptr : HashBuiltin*,
      range_check_ptr
    }(implementation: felt):
    # make sure the target is not null
    with_attr error_message("RulesCards: new implementation cannot be null"):
      assert_not_zero(implementation)
    end

    # change implementation
    Proxy.set_implementation(implementation)
    return ()
  end

  #
  # Business logic
  #

  func create_card{
      syscall_ptr: felt*,
      pedersen_ptr: HashBuiltin*,
      bitwise_ptr: BitwiseBuiltin*,
      range_check_ptr
    }(card: Card, metadata: Metadata) -> (card_id: Uint256):
    alloc_locals

    let (available_supply) = card_model_available_supply(card_model=card.model)
    with_attr error_message("Available supply is null"):
      assert_not_zero(available_supply)
    end

    # Check if the serial_number is valid, given the scarcity supply
    let (supply) = Scarcity_max_supply(card.model.season, card.model.scarcity)
    let (is_supply_set) = is_not_zero(supply)

    if is_supply_set == TRUE:
      with_attr error_message("RulesCards: Invalid Serial"):
        assert_le(card.serial_number, supply)
      end
      tempvar range_check_ptr = range_check_ptr
    else:
      tempvar range_check_ptr = range_check_ptr
    end

    # Check if card already exists
    let (local card_id) = get_card_id_from_card(card)
    let (exists) = card_exists(card_id)

    with_attr error_message("RulesCards: card already exists"):
      assert exists = FALSE
    end

    let (supply) = card_models_supply_storage.read(card.model)
    card_models_supply_storage.write(card.model, supply + 1)

    cards_storage.write(card_id, card)
    cards_metadata_storage.write(card_id, metadata)

    return (card_id)
  end

  func pack_card_model{
      syscall_ptr: felt*,
      pedersen_ptr: HashBuiltin*,
      range_check_ptr
    }(pack_card_model: PackCardModel):
    let (available_supply) = card_model_available_supply(pack_card_model.card_model)

    with_attr error_message("Card model quantity too high"):
      assert_le(pack_card_model.quantity, available_supply)
    end

    let (packed_supply) = card_models_packed_supply_storage.read(pack_card_model.card_model)
    card_models_packed_supply_storage.write(pack_card_model.card_model, packed_supply + pack_card_model.quantity)
    return ()
  end
end
