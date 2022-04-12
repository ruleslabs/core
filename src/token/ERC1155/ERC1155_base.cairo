%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import (
  Uint256, uint256_lt, uint256_add, uint256_check, uint256_le
)
from starkware.cairo.common.math import assert_not_zero, assert_not_equal
from starkware.starknet.common.syscalls import get_caller_address

from openzeppelin.security.safemath import (
  uint256_checked_add,
  uint256_checked_sub_le
)

from openzeppelin.introspection.ERC165 import (
  ERC165_register_interface
)

# Constants

from openzeppelin.utils.constants import (
  TRUE, FALSE, IERC1155_ID, IERC1155_ACCEPTED_ID, IERC1155_BATCH_ACCEPTED_ID, IERC1155_RECEIVER_ID, IACCOUNT_ID
)

#
# Import interfaces
#

from openzeppelin.introspection.IERC165 import IERC165
from token.ERC1155.IERC1155_Receiver import IERC1155_Receiver

#
# Events
#

@event
func Transfer(from_: felt, to: felt, token_id: Uint256, amount: Uint256):
end

@event
func ApprovalForAll(owner: felt, operator: felt, approved: felt):
end

@event
func Approval(owner: felt, operator: felt, token_id: Uint256, amount: Uint256):
end

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
func ERC1155_balances(owner: felt, token_id: Uint256) -> (balance: Uint256):
end

@storage_var
func ERC1155_operator_approvals(owner: felt, operator: felt) -> (res: felt):
end

@storage_var
func ERC1155_token_approval_operator(owner: felt, token_id: Uint256) -> (operator: felt):
end

@storage_var
func ERC1155_token_approval_amount(owner: felt, token_id: Uint256) -> (amount: Uint256):
end

#
# Initializer
#

func ERC1155_initializer{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
  }(name: felt, symbol: felt):
  ERC1155_name_.write(name)
  ERC1155_symbol_.write(symbol)

  ERC165_register_interface(IERC1155_ID)
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

func ERC1155_balanceOf{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(account: felt, token_id: Uint256) -> (balance: Uint256):
  with_attr error_message("ERC1155: token_id is not a valid Uint256"):
    uint256_check(token_id)
  end

  let (balance: Uint256) = ERC1155_balances.read(account, token_id)
  return (balance)
end

func ERC1155_approved_for_all{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(owner: felt, operator: felt) -> (is_approved: felt):
  let (is_approved) = ERC1155_operator_approvals.read(owner, operator)
  return (is_approved)
end

func ERC1155_approved{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(owner: felt, token_id: Uint256) -> (operator: felt, amount: Uint256):
  let (operator) = ERC1155_token_approval_operator.read(owner, token_id)
  let (amount) = ERC1155_token_approval_amount.read(owner, token_id)
  return (operator, amount)
end

#
# Business logic
#

# Mint

func ERC1155_mint{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(to: felt, token_id: Uint256, amount: Uint256):
  alloc_locals
  with_attr error_message("ERC1155: token_id is not a valid Uint256"):
    uint256_check(token_id)
  end

  with_attr error_message("ERC1155: minting to null address is not allowed"):
    assert_not_zero(to)
  end

  let (is_amount_valid) = uint256_lt(Uint256(0, 0), amount)
  assert is_amount_valid = 1 # mint null amount

  # Update balances
  let (balance: Uint256) = ERC1155_balances.read(to, token_id)

  let (new_balance: Uint256, _) = uint256_add(balance, amount)
  ERC1155_balances.write(to, token_id, new_balance)

  return ()
end

func ERC1155_safe_mint{
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
  alloc_locals
  ERC1155_mint(to, token_id, amount)

  let (caller) = get_caller_address()

  _safe_transfer_acceptance_check(
    _from = 0,
    to = to,
    token_id = token_id,
    amount = amount,
    data_len = data_len,
    data = data
  )

  return ()
end

# Transfer

func ERC1155_transfer_from{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(_from: felt, to: felt, token_id: Uint256, amount: Uint256):
  alloc_locals
  with_attr error_message("ERC1155: token_id is not a valid Uint256"):
    uint256_check(token_id)
  end

  let (caller) = get_caller_address()
  let (is_approved) = _is_approved_or_owner(owner=_from, spender=caller, token_id=token_id, amount=amount)
  with_attr error_message("ERC1155: either is not approved or the caller is the zero address"):
    assert_not_zero(caller * is_approved)
  end

  _transfer(_from, to, token_id, amount)
  return ()
end

func ERC1155_safe_transfer_from{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(_from: felt, to: felt, token_id: Uint256, amount: Uint256, data_len: felt, data: felt*):
  alloc_locals
  with_attr error_message("ERC1155: token_id is not a valid Uint256"):
    uint256_check(token_id)
  end

  let (caller) = get_caller_address()
  let (is_approved) = _is_approved_or_owner(owner=_from, spender=caller, token_id=token_id, amount=amount)
  with_attr error_message("ERC1155: either is not approved or the caller is the zero address"):
    assert_not_zero(caller * is_approved)
  end

  _safe_transfer(_from, to, token_id, amount, data_len, data)
  return ()
end

# Approval

func ERC1155_set_approve_for_all{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(operator: felt, approved: felt):
  # Ensures caller is neither zero address nor operator
  let (caller) = get_caller_address()
  with_attr error_message("ERC1155: either the caller or operator is the zero address"):
    assert_not_zero(caller * operator)
  end

  with_attr error_message("ERC1155: approve to caller"):
    assert_not_equal(caller, operator)
  end

  # Make sure `approved` is a boolean (0 or 1)
  with_attr error_message("ERC1155: approved is not a Cairo boolean"):
    assert approved * (1 - approved) = 0
  end

  ERC1155_operator_approvals.write(owner=caller, operator=operator, value=approved)
  ApprovalForAll.emit(caller, operator, approved)
  return ()
end

func ERC1155_approve{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(to: felt, token_id: Uint256, amount: Uint256):
  alloc_locals
  with_attr error_mesage("ERC1155: token_id is not a valid Uint256"):
    uint256_check(token_id)
  end

  # Checks caller is not zero address
  let (local caller) = get_caller_address()
  with_attr error_message("ERC1155: cannot approve from the zero address"):
    assert_not_zero(caller)
  end

  # Ensures 'caller' hold enough tokens
  let (balance) = ERC1155_balances.read(caller, token_id)
  with_attr error_message("ERC1155: approval amount cannot be higher than caller balance"):
    let (valid_amount) = uint256_le(amount, balance)
    assert valid_amount = TRUE
  end

  # Ensure 'caller' does not equal 'to'
  with_attr error_message("ERC1155: approval to current owner"):
    assert_not_equal(caller, to)
  end

  _approve(owner=caller, operator=to, token_id=token_id, amount=amount)
  return ()
end

#
# Internals
#

func _approve{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(owner: felt, operator: felt, token_id: Uint256, amount: Uint256):
  ERC1155_token_approval_operator.write(owner, token_id, operator)
  ERC1155_token_approval_amount.write(owner, token_id, amount)
  Approval.emit(owner, operator, token_id, amount)
  return ()
end

func _is_approved_or_owner{
    pedersen_ptr: HashBuiltin*,
    syscall_ptr: felt*,
    range_check_ptr
  }(owner: felt, spender: felt, token_id: Uint256, amount: Uint256) -> (res: felt):
  alloc_locals

  # Ensures 'owner' hold enough tokens
  let (balance) = ERC1155_balances.read(owner, token_id)
  let (valid_amount) = uint256_le(amount, balance)
  if valid_amount == FALSE:
    return (FALSE)
  end

  if owner == spender:
    return (TRUE)
  end

  let (is_operator) = ERC1155_approved_for_all(owner, spender)
  if is_operator == TRUE:
      return (TRUE)
  end

  let (operator, approved_amount) = ERC1155_approved(owner, token_id)
  if operator == spender:
    let (valid_amount) = uint256_le(approved_amount, amount)
    return (valid_amount)
  end

  return (FALSE)
end

# Transfer

func _transfer{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(_from: felt, to: felt, token_id: Uint256, amount: Uint256):
  alloc_locals

  # ownerOf ensures 'from_' is not the zero address
  with_attr error_message("ERC1155: cannot transfer to the zero address"):
    assert_not_zero(to)
  end

  # Decrease owner balance
  let (owner_balance) = ERC1155_balances.read(_from, token_id)
  let (new_balance: Uint256) = uint256_checked_sub_le(owner_balance, amount)
  ERC1155_balances.write(_from, token_id, new_balance)

  # Increase receiver balance
  let (receiver_balance) = ERC1155_balances.read(to, token_id)
  let (new_balance: Uint256) = uint256_checked_add(receiver_balance, amount)
  ERC1155_balances.write(to, token_id, receiver_balance)

  # Update approval
  let (local operator) = ERC1155_token_approval_operator.read(_from, token_id)
  let (approved_amount) = ERC1155_token_approval_amount.read(_from, token_id)
  let (approved_amount_too_high) = uint256_lt(amount, approved_amount)

  if approved_amount_too_high == TRUE:
    _approve(owner=_from, operator=operator, token_id=token_id, amount=amount)
    tempvar syscall_ptr = syscall_ptr
    tempvar pedersen_ptr = pedersen_ptr
    tempvar range_check_ptr = range_check_ptr
  else:
    tempvar syscall_ptr = syscall_ptr
    tempvar pedersen_ptr = pedersen_ptr
    tempvar range_check_ptr = range_check_ptr
  end

  Transfer.emit(_from, to, token_id, amount)
  return ()
end

func _safe_transfer{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(_from: felt, to: felt, token_id: Uint256, amount: Uint256, data_len: felt, data: felt*):
  _transfer(_from, to, token_id, amount)
  _safe_transfer_acceptance_check(_from, to, token_id, amount, data_len, data)
  return ()
end

# Acceptance check

func _safe_transfer_acceptance_check{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(_from: felt, to: felt, token_id: Uint256, amount: Uint256, data_len: felt, data: felt*):
  # If `to` refers to a smart contract, it must implement {IERC1155_Receiver-onERC1155Received}
  # and return the acceptance magic value.
  let (success) = _check_onERC1155Received(_from, to, token_id, amount, data_len, data)
  with_attr error_message("ERC1155: transfer to non ERC1155Receiver implementer"):
    assert success = TRUE
  end

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
    amount: Uint256,
    data_len: felt,
    data: felt*
  ) -> (success: felt):
  let (caller) = get_caller_address()
  let (is_supported) = IERC165.supportsInterface(to, IERC1155_RECEIVER_ID)

  if is_supported == TRUE:
    let (selector) = IERC1155_Receiver.onERC1155Received(
      to,
      caller,
      _from,
      token_id,
      amount,
      data_len,
      data
    )

    assert selector = IERC1155_ACCEPTED_ID
    return (TRUE)
  end

  let (is_account) = IERC165.supportsInterface(to, IACCOUNT_ID)
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
    amounts_len: felt,
    amounts: Uint256*,
    data_len: felt,
    data: felt*
  ) -> (success: felt):
  let (caller) = get_caller_address()
  let (is_supported) = IERC165.supportsInterface(to, IERC1155_RECEIVER_ID)

  if is_supported == TRUE:
    let (selector) = IERC1155_Receiver.onERC1155BatchReceived(
      to,
      caller,
      _from,
      ids_len,
      ids,
      amounts_len,
      amounts,
      data_len,
      data
    )

    assert selector = IERC1155_BATCH_ACCEPTED_ID
    return (TRUE)
  end

  let (is_account) = IERC165.supportsInterface(to, IACCOUNT_ID)
  return (is_account)
end
