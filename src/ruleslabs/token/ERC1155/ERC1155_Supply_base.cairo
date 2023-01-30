%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_lt, uint256_sub, uint256_add

const TRUE = 1;
const FALSE = 0;

//
// Storage
//

@storage_var
func ERC1155_total_supply(token_id: Uint256) -> (total_supply: Uint256) {
}

//
// Getters
//

func ERC1155_Supply_total_supply{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  token_id: Uint256
) -> (total_supply: Uint256) {
  let (total_supply) = ERC1155_total_supply.read(token_id);
  return (total_supply,);
}

func ERC1155_Supply_exists{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  token_id: Uint256
) -> (res: felt) {
  alloc_locals;

  let (total_supply) = ERC1155_Supply_total_supply(token_id);

  // exists if 0 < total_supply
  let (exists) = uint256_lt(Uint256(0, 0), total_supply);
  return (exists,);
}

//
// Externals
//

func ERC1155_Supply_before_token_transfer{
  syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(_from: felt, to: felt, ids_len: felt, ids: Uint256*, amounts: Uint256*) {
  tempvar syscall_ptr = syscall_ptr;
  tempvar pedersen_ptr = pedersen_ptr;
  tempvar range_check_ptr = range_check_ptr;

  if (_from == 0) {
    _increaseTotalSupply(ids_len, ids, amounts);
  }

  if (to == 0) {
    _decreaseTotalSupply(ids_len, ids, amounts);
  }

  return ();
}

//
// Internals
//

func _increaseTotalSupply{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  ids_len: felt, ids: Uint256*, amounts: Uint256*
) {
  if (ids_len == 0) {
    return ();
  }

  let (total_supply) = ERC1155_total_supply.read([ids]);
  let (new_total_supply: Uint256, _) = uint256_add(total_supply, [amounts]);

  ERC1155_total_supply.write([ids], new_total_supply);
  _increaseTotalSupply(ids_len=ids_len - 1, ids=ids + 1, amounts=amounts + 1);
  return ();
}

func _decreaseTotalSupply{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  ids_len: felt, ids: Uint256*, amounts: Uint256*
) {
  if (ids_len == 0) {
    return ();
  }

  let (total_supply) = ERC1155_total_supply.read([ids]);
  let (new_total_supply) = uint256_sub(total_supply, [amounts]);

  ERC1155_total_supply.write([ids], new_total_supply);
  _decreaseTotalSupply(ids_len=ids_len - 1, ids=ids + 1, amounts=amounts + 1);
  return ();
}
