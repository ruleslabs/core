%lang starknet

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_le, assert_not_zero
from starkware.cairo.common.math_cmp import is_not_zero

// Constants

from ruleslabs.models.card import SERIAL_NUMBER_MAX

//
// Storage
//

@storage_var
func scarcity_max_supply_storage(season: felt, scarcity: felt) -> (supply: felt) {
}

@storage_var
func last_scarcity_storage(season: felt) -> (scarcity: felt) {
}

@storage_var
func stopped_scarcity_storage(season: felt, scarcity: felt) -> (stopped: felt) {
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

//
// Getters
//

func Scarcity_max_supply{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  season: felt, scarcity: felt
) -> (max_supply: felt) {
  if (scarcity == 0) {
    return (max_supply=SERIAL_NUMBER_MAX);
  }

  let (supply) = scarcity_max_supply_storage.read(season, scarcity);
  return (supply,);
}

func Scarcity_productionStopped{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  season: felt, scarcity: felt
) -> (stopped: felt) {
  let (stopped) = stopped_scarcity_storage.read(season, scarcity);
  return (stopped,);
}

//
// Externals
//

func Scarcity_addScarcity{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  season: felt, supply: felt
) -> (scarcity: felt) {
  alloc_locals;

  assert_not_zero(supply);

  let (local last_scarcity) = last_scarcity_storage.read(season);

  scarcity_max_supply_storage.write(season, last_scarcity + 1, supply);
  last_scarcity_storage.write(season, last_scarcity + 1);

  ScarcityAdded.emit(season, last_scarcity + 1, supply);

  return (last_scarcity + 1,);
}

func Scarcity_stopProduction{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  season: felt, scarcity: felt
) {
  alloc_locals;
  let (already_stopped) = stopped_scarcity_storage.read(season, scarcity);
  stopped_scarcity_storage.write(season, scarcity, TRUE);

  if (already_stopped == FALSE) {
    ScarcityProductionStopped.emit(season, scarcity);
    return ();
  }

  return ();
}
