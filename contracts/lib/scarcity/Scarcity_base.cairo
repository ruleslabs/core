%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_le, assert_not_zero
from starkware.cairo.common.math_cmp import is_not_zero

const SCARCITY_SUPPLY_DIVISOR = 2

const TRUE = 1
const FALSE = 0

#
# Storage
#

@storage_var
func scarcity_supply_storage(season: felt, scarcity: felt) -> (supply: felt):
end

@storage_var
func last_scarcity_storage(season: felt) -> (scarcity: felt):
end

#
# Getters
#

func Scarcity_supply{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(season: felt, scarcity: felt) -> (supply: felt):
  let (supply) = scarcity_supply_storage.read(season, scarcity)
  return (supply)
end

#
# Externals
#

func Scarcity_addScarcity{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(season: felt, supply: felt) -> (scarcity: felt):
  alloc_locals

  assert_not_zero(supply)

  let (local last_scarcity) = last_scarcity_storage.read(season)
  let (last_supply) = scarcity_supply_storage.read(season, last_scarcity)

  let (is_last_supply_set) = is_not_zero(last_supply)

  if is_last_supply_set == TRUE:
    assert_le(supply * SCARCITY_SUPPLY_DIVISOR, last_supply)
    tempvar range_check_ptr = range_check_ptr
  else:
    tempvar range_check_ptr = range_check_ptr
  end

  scarcity_supply_storage.write(season, last_scarcity + 1, supply)
  last_scarcity_storage.write(season, last_scarcity + 1)

  return (last_scarcity + 1)
end
