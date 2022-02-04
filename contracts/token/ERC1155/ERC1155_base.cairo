%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import (
  Uint256, uint256_lt, uint256_add, uint256_check
)
from starkware.cairo.common.math import assert_not_zero
from starkware.starknet.common.syscalls import get_caller_address

from contracts.openzeppelin.ERC165_base import (
  ERC165_register_interface
)

from contracts.openzeppelin.IERC165 import IERC165
from contracts.token.ERC1155.IERC1155_Receiver import IERC1155_Receiver

const TRUE = 1
const FALSE = 0

const ERC1155_ERC165 = 0xd9b67a26
const ERC1155_ERC165_TOKENRECEIVER = 0x4e2312e0
const ERC1155_ACCEPTED = 0xf23a6e61
const ERC1155_BATCH_ACCEPTED = 0xbc197c81
const ACCOUNT_ERC165 = 0x50b70dcb

#
# Storage
#

@storage_var
func ERC1155_name_() -> (name: felt):
end

@storage_var
func ERC1155_symbol_() -> (symbol: felt):
end

@storage_var
func ERC721_balances(owner: felt, token_id: Uint256) -> (balance: Uint256):
end

#
# Constructor
#

func ERC1155_initializer{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
  }(name: felt, symbol: felt):
  ERC1155_name_.write(name)
  ERC1155_symbol_.write(symbol)

  ERC165_register_interface(ERC1155_ERC165)
  return ()
end

#
# Getters
#

func ERC1155_name{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
  }() -> (name: felt):
  let (name) = ERC1155_name_.read()
  return (name)
end

func ERC1155_symbol{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
  }() -> (symbol: felt):
  let (symbol) = ERC1155_symbol_.read()
  return (symbol)
end

#
# Externals
#

func ERC1155_mint{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(
    to: felt,
    token_id: Uint256,
    amount: Uint256
  ):
  uint256_check(token_id)
  assert_not_zero(to) # mint to null address

  let (is_amount_valid) = uint256_lt(Uint256(0, 0), amount)
  assert is_amount_valid = 1 # mint null amount

  # Update balances
  let (balance: Uint256) = ERC721_balances.read(to, token_id)

  let (new_balance: Uint256, _) = uint256_add(balance, Uint256(1, 0))
  ERC721_balances.write(to, token_id, new_balance)

  return ()
end

func ERC1155_safeMint{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(
    to: felt,
    token_id: Uint256,
    amount: Uint256,
    data_len: felt,
    data: felt*
  ):
  uint256_check(token_id)
  ERC1155_mint(to, token_id, amount)

  _safe_transfer_acceptance_check(
    _from = 0,
    to = to,
    token_id = token_id,
    value = amount,
    data_len = data_len,
    data = data
  )

  return ()
end

#
# Internals
#

func _safe_transfer_acceptance_check{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(
    _from: felt,
    to: felt,
    token_id: Uint256,
    value: Uint256,
    data_len: felt,
    data: felt*
  ):
  # If `to` refers to a smart contract, it must implement {IERC1155_Receiver-onERC1155Received}
  # and return the acceptance magic value.
  let (success) = _check_onERC1155Received(_from, to, token_id, value, data_len, data)
  assert success = 1

  return ()
end

func _check_onERC1155Received{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(
    _from: felt,
    to: felt,
    token_id: Uint256,
    value: Uint256,
    data_len: felt,
    data: felt*
  ) -> (success: felt):
  let (caller) = get_caller_address()
  let (is_supported) = IERC165.supportsInterface(to, ERC1155_ERC165_TOKENRECEIVER)

  if is_supported == TRUE:
    let (selector) = IERC1155_Receiver.onERC1155Received(
      to,
      caller,
      _from,
      token_id,
      value,
      data_len,
      data
    )

    assert selector = ERC1155_ACCEPTED
    return (TRUE)
  end

  let (is_account) = IERC165.supportsInterface(to, ACCOUNT_ERC165)
  return (is_account)
end

func _check_onERC1155BatchReceived{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(
    _from: felt,
    to: felt,
    ids_len: felt,
    ids: Uint256*,
    values_len: felt,
    values: Uint256*,
    data_len: felt,
    data: felt*
  ) -> (success: felt):
  let (caller) = get_caller_address()
  let (is_supported) = IERC165.supportsInterface(to, ERC1155_ERC165_TOKENRECEIVER)

  if is_supported == TRUE:
    let (selector) = IERC1155_Receiver.onERC1155BatchReceived(
      to,
      caller,
      _from,
      ids_len,
      ids,
      values_len,
      values,
      data_len,
      data
    )

    assert selector = ERC1155_BATCH_ACCEPTED
    return (TRUE)
  end

  let (is_account) = IERC165.supportsInterface(to, ACCOUNT_ERC165)
  return (is_account)
end
