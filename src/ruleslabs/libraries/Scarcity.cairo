%lang starknet

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_le, assert_not_zero
from starkware.cairo.common.math_cmp import is_not_zero

// Constants

from ruleslabs.utils.card import SERIAL_NUMBER_MAX

//
// Storage
//

@storage_var
func scarcity_max_supply_storage(season: felt, scarcity: felt) -> (supply: felt) {
}

@storage_var
func last_scarcity_storage(season: felt) -> (scarcity: felt) {
}

//
// Events
//

@event
func ScarcityAdded(season: felt, scarcity: felt, supply: felt) {
}

@event
func ScarcityProductionStopped(season: felt, scarcity: felt) {
}

namespace Scarcity {

  // Getters

  func max_supply{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    season: felt, scarcity: felt
  ) -> (max_supply: felt) {
    if (scarcity == 0) {
      return (max_supply=SERIAL_NUMBER_MAX,);
    }

    let (supply) = scarcity_max_supply_storage.read(season, scarcity);
    return (supply,);
  }

  // Setters

  func add_scarcity{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    season: felt, supply: felt
  ) -> (scarcity: felt) {
    assert_not_zero(supply);

    let (last_scarcity) = last_scarcity_storage.read(season);

    scarcity_max_supply_storage.write(season, last_scarcity + 1, supply);
    last_scarcity_storage.write(season, last_scarcity + 1);

    ScarcityAdded.emit(season, last_scarcity + 1, supply);

    return (last_scarcity + 1,);
  }
}
