%lang starknet

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import (
  Uint256,
  uint256_lt,
  uint256_add,
  uint256_check,
  uint256_le,
)
from starkware.cairo.common.math import assert_not_zero, assert_not_equal
from starkware.starknet.common.syscalls import get_caller_address

// External namespaces

from openzeppelin.security.safemath.library import SafeUint256
from openzeppelin.introspection.erc165.library import ERC165

// Constants

from ruleslabs.utils.constants.library import (
  IERC1155_ID,
  IERC1155_ACCEPTED_ID,
  IERC1155_BATCH_ACCEPTED_ID,
  IERC1155_RECEIVER_ID,
)

from openzeppelin.utils.constants.library import IACCOUNT_ID

//
// Import interfaces
//

from openzeppelin.introspection.erc165.IERC165 import IERC165
from ruleslabs.token.ERC1155.IERC1155_Receiver import IERC1155_Receiver

//
// Events
//

@event
func TransferSingle(operator: felt, _from: felt, to: felt, token_id: Uint256, amount: Uint256) {
}

@event
func TransferBatch(
  operator: felt,
  _from: felt,
  to: felt,
  ids_len: felt,
  ids: Uint256*,
  amounts_len: felt,
  amounts: Uint256*,
) {
}

@event
func ApprovalForAll(owner: felt, operator: felt, approved: felt) {
}

@event
func Approval(owner: felt, operator: felt, token_id: Uint256, amount: Uint256) {
}

//
// Storage
//

@storage_var
func ERC1155_name_() -> (name: felt) {
}

@storage_var
func ERC1155_symbol_() -> (symbol: felt) {
}

@storage_var
func ERC1155_balances(owner: felt, token_id: Uint256) -> (balance: Uint256) {
}

@storage_var
func ERC1155_operator_approvals(owner: felt, operator: felt) -> (res: felt) {
}

@storage_var
func ERC1155_token_approval_operator(owner: felt, token_id: Uint256) -> (operator: felt) {
}

@storage_var
func ERC1155_token_approval_amount(owner: felt, token_id: Uint256) -> (amount: Uint256) {
}

//
// Initializer
//

func ERC1155_initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  name: felt, symbol: felt
) {
  ERC1155_name_.write(name);
  ERC1155_symbol_.write(symbol);

  ERC165.register_interface(IERC1155_ID);
  return ();
}

//
// Getters
//

func ERC1155_name{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
  name: felt
) {
  let (name) = ERC1155_name_.read();
  return (name,);
}

func ERC1155_symbol{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
  symbol: felt
) {
  let (symbol) = ERC1155_symbol_.read();
  return (symbol,);
}

func ERC1155_balance_of{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  account: felt, token_id: Uint256
) -> (balance: Uint256) {
  with_attr error_message("ERC1155: token_id is not a valid Uint256") {
    uint256_check(token_id);
  }

  let (balance: Uint256) = ERC1155_balances.read(account, token_id);
  return (balance,);
}

func ERC1155_approved_for_all{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  owner: felt, operator: felt
) -> (is_approved: felt) {
  let (is_approved) = ERC1155_operator_approvals.read(owner, operator);
  return (is_approved,);
}

func ERC1155_approved{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  owner: felt, token_id: Uint256
) -> (operator: felt, amount: Uint256) {
  let (operator) = ERC1155_token_approval_operator.read(owner, token_id);
  let (amount) = ERC1155_token_approval_amount.read(owner, token_id);
  return (operator, amount);
}

//
// Business logic
//

// Mint

func ERC1155_safe_mint{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  to: felt, token_id: Uint256, amount: Uint256, data_len: felt, data: felt*
) {
  alloc_locals;
  with_attr error_message("ERC1155: token_id is not a valid Uint256") {
    uint256_check(token_id);
  }

  let (caller) = get_caller_address();
  with_attr error_message("ERC1155: minting to null address or from null caller is not allowed") {
    assert_not_zero(to * caller);
  }

  let (is_amount_valid) = uint256_lt(Uint256(0, 0), amount);
  with_attr error_message("ERC1155: minting null amount is not allowed") {
    assert is_amount_valid = TRUE;
  }

  // Update balances
  let (balance: Uint256) = ERC1155_balances.read(to, token_id);

  let (new_balance: Uint256, _) = uint256_add(balance, amount);
  ERC1155_balances.write(to, token_id, new_balance);

  TransferSingle.emit(caller, 0, to, token_id, amount);

  _safe_transfer_acceptance_check(
    _from=0, to=to, token_id=token_id, amount=amount, data_len=data_len, data=data
  );
  return ();
}

func ERC1155_safe_mint_batch{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  to: felt,
  ids_len: felt,
  ids: Uint256*,
  amounts_len: felt,
  amounts: Uint256*,
  data_len: felt,
  data: felt*,
) {
  alloc_locals;
  with_attr error_message("ERC1155: different amounts_len and ids_len") {
    assert amounts_len = ids_len;
  }

  let (caller) = get_caller_address();
  with_attr error_message("ERC1155: minting to null address or from null caller is not allowed") {
    assert_not_zero(to * caller);
  }

  _safe_mint_batch(
    operator=caller,
    to=to,
    ids_len=ids_len,
    ids=ids,
    amounts_len=amounts_len,
    amounts=amounts,
    data_len=data_len,
    data=data,
  );
  return ();
}

func ERC1155_mint_batch{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  to: felt,
  ids_len: felt,
  ids: Uint256*,
  amounts_len: felt,
  amounts: Uint256*,
  data_len: felt,
  data: felt*,
) {
  alloc_locals;
  with_attr error_message("ERC1155: different amounts_len and ids_len") {
    assert amounts_len = ids_len;
  }

  let (caller) = get_caller_address();
  with_attr error_message("ERC1155: minting to null address or from null caller is not allowed") {
    assert_not_zero(to * caller);
  }

  _safe_mint_batch(
    operator=caller,
    to=to,
    ids_len=ids_len,
    ids=ids,
    amounts_len=amounts_len,
    amounts=amounts,
    data_len=data_len,
    data=data,
  );
  return ();
}

// Transfer

func ERC1155_safe_transfer_from{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  _from: felt, to: felt, token_id: Uint256, amount: Uint256, data_len: felt, data: felt*
) {
  alloc_locals;
  with_attr error_message("ERC1155: token_id is not a valid Uint256") {
    uint256_check(token_id);
  }

  let (caller) = get_caller_address();
  let (is_approved) = _is_approved_or_owner(
    owner=_from, spender=caller, token_id=token_id, amount=amount
  );
  with_attr error_message("ERC1155: either is not approved or the caller is the zero address") {
    assert_not_zero(caller * is_approved);
  }

  _safe_transfer(
    operator=caller,
    _from=_from,
    to=to,
    token_id=token_id,
    amount=amount,
    data_len=data_len,
    data=data,
  );
  return ();
}

func ERC1155_safe_batch_transfer_from{
  syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(
  _from: felt,
  to: felt,
  ids_len: felt,
  ids: Uint256*,
  amounts_len: felt,
  amounts: Uint256*,
  data_len: felt,
  data: felt*,
) {
  alloc_locals;
  with_attr error_message("ERC1155: different amounts_len and ids_len") {
    assert amounts_len = ids_len;
  }

  let (local caller) = get_caller_address();
  let (is_approved) = _is_approved_or_owner_of_batch(
    owner=_from,
    spender=caller,
    ids_len=ids_len,
    ids=ids,
    amounts_len=amounts_len,
    amounts=amounts,
  );
  with_attr error_message("ERC1155: either is not approved or the caller is the zero address") {
    assert_not_zero(caller * is_approved);
  }

  _safe_batch_transfer(
    operator=caller,
    _from=_from,
    to=to,
    ids_len=ids_len,
    ids=ids,
    amounts_len=amounts_len,
    amounts=amounts,
    data_len=data_len,
    data=data,
  );
  return ();
}

// Approval

func ERC1155_set_approve_for_all{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  operator: felt, approved: felt
) {
  // Ensures caller is neither zero address nor operator
  let (caller) = get_caller_address();
  with_attr error_message("ERC1155: either the caller or operator is the zero address") {
    assert_not_zero(caller * operator);
  }

  with_attr error_message("ERC1155: approve to caller") {
    assert_not_equal(caller, operator);
  }

  // Make sure `approved` is a boolean (0 or 1)
  with_attr error_message("ERC1155: approved is not a Cairo boolean") {
    assert approved * (1 - approved) = 0;
  }

  ERC1155_operator_approvals.write(owner=caller, operator=operator, value=approved);
  ApprovalForAll.emit(caller, operator, approved);
  return ();
}

func ERC1155_approve{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  to: felt, token_id: Uint256, amount: Uint256
) {
  alloc_locals;
  with_attr error_message("ERC1155: token_id is not a valid Uint256") {
    uint256_check(token_id);
  }

  // Checks caller is not zero address
  let (local caller) = get_caller_address();
  with_attr error_message("ERC1155: cannot approve from the zero address") {
    assert_not_zero(caller);
  }

  // Ensures 'caller' hold enough tokens
  let (balance) = ERC1155_balances.read(caller, token_id);
  with_attr error_message("ERC1155: approval amount cannot be higher than caller balance") {
    let (valid_amount) = uint256_le(amount, balance);
    assert valid_amount = TRUE;
  }

  // Ensure 'caller' does not equal 'to'
  with_attr error_message("ERC1155: approval to current owner") {
    assert_not_equal(caller, to);
  }

  _approve(owner=caller, operator=to, token_id=token_id, amount=amount);
  return ();
}

func ERC1155_burn{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  _from: felt, token_id: Uint256, amount: Uint256
) {
  alloc_locals;
  let (caller) = get_caller_address();

  // Decrease owner balance
  let (owner_balance) = ERC1155_balances.read(_from, token_id);
  let (new_balance: Uint256) = SafeUint256.sub_le(owner_balance, amount);
  ERC1155_balances.write(_from, token_id, new_balance);

  // Emit transfer before update approval to avoid revoked implicit arguments
  TransferSingle.emit(caller, _from, 0, token_id, amount);

  // Update approval
  let (operator) = ERC1155_token_approval_operator.read(_from, token_id);
  let (approved_amount) = ERC1155_token_approval_amount.read(_from, token_id);

  let (approved_amount_too_high) = uint256_lt(new_balance, approved_amount);
  if (approved_amount_too_high == TRUE) {
    _approve(owner=_from, operator=operator, token_id=token_id, amount=new_balance);
    return ();
  }

  return ();
}

//
// Internals
//

func _approve{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  owner: felt, operator: felt, token_id: Uint256, amount: Uint256
) {
  ERC1155_token_approval_operator.write(owner, token_id, operator);
  ERC1155_token_approval_amount.write(owner, token_id, amount);
  Approval.emit(owner, operator, token_id, amount);
  return ();
}

func _is_approved_or_owner{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
  owner: felt, spender: felt, token_id: Uint256, amount: Uint256
) -> (res: felt) {
  alloc_locals;

  // Ensures 'owner' hold enough tokens
  let (balance) = ERC1155_balances.read(owner, token_id);
  let (valid_amount) = uint256_le(amount, balance);
  if (valid_amount == FALSE) {
    return (FALSE,);
  }

  if (owner == spender) {
    return (TRUE,);
  }

  let (is_operator) = ERC1155_approved_for_all(owner, spender);
  if (is_operator == TRUE) {
    return (TRUE,);
  }

  let (operator, approved_amount) = ERC1155_approved(owner, token_id);
  if (operator == spender) {
    let (valid_amount) = uint256_le(amount, approved_amount);
    return (valid_amount,);
  }

  return (FALSE,);
}

func _is_approved_or_owner_of_batch{
  pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr
}(
  owner: felt, spender: felt, ids_len: felt, ids: Uint256*, amounts_len: felt, amounts: Uint256*
) -> (res: felt) {
  alloc_locals;

  if (ids_len == 0) {
    return (TRUE,);
  }

  alloc_locals;
  with_attr error_message("ERC1155: token_id is not a valid Uint256") {
    uint256_check([ids]);
  }

  let (is_approved) = _is_approved_or_owner(owner, spender, [ids], [amounts]);
  if (is_approved == FALSE) {
    return (FALSE,);
  }

  let (is_approved) = _is_approved_or_owner_of_batch(
    owner, spender, ids_len - 1, ids + Uint256.SIZE, amounts_len - 1, amounts + Uint256.SIZE
  );
  return (is_approved,);
}

// Transfer

func _transfer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  operator: felt, _from: felt, to: felt, token_id: Uint256, amount: Uint256
) {
  alloc_locals;

  // ensures 'to' is not the zero address
  with_attr error_message("ERC1155: cannot transfer to the zero address") {
    assert_not_zero(to);
  }

  // Decrease owner balance
  let (owner_balance) = ERC1155_balances.read(_from, token_id);
  let (new_owner_balance: Uint256) = SafeUint256.sub_le(owner_balance, amount);
  ERC1155_balances.write(_from, token_id, new_owner_balance);

  // Increase receiver balance
  let (receiver_balance) = ERC1155_balances.read(to, token_id);
  let (new_receiver_balance: Uint256) = SafeUint256.add(receiver_balance, amount);
  ERC1155_balances.write(to, token_id, new_receiver_balance);

  // Emit transfer before update approval to avoid revoked implicit arguments
  TransferSingle.emit(operator, _from, to, token_id, amount);

  // Update approval
  let (caller) = get_caller_address();
  let (local operator) = ERC1155_token_approval_operator.read(_from, token_id);
  let (approved_amount) = ERC1155_token_approval_amount.read(_from, token_id);

  if (operator == caller) {
    let (new_approved_amount) = SafeUint256.sub_le(approved_amount, amount);
    _approve(owner=_from, operator=operator, token_id=token_id, amount=new_approved_amount);
    return ();
  } else {
    let (approved_amount_too_high) = uint256_lt(new_owner_balance, approved_amount);
    if (approved_amount_too_high == TRUE) {
      _approve(owner=_from, operator=operator, token_id=token_id, amount=new_owner_balance);
      return ();
    }
  }

  return ();
}

func _safe_transfer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  operator: felt,
  _from: felt,
  to: felt,
  token_id: Uint256,
  amount: Uint256,
  data_len: felt,
  data: felt*,
) {
  _transfer(operator, _from, to, token_id, amount);
  _safe_transfer_acceptance_check(_from, to, token_id, amount, data_len, data);
  return ();
}

func _safe_batch_transfer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  operator: felt,
  _from: felt,
  to: felt,
  ids_len: felt,
  ids: Uint256*,
  amounts_len: felt,
  amounts: Uint256*,
  data_len: felt,
  data: felt*,
) {
  alloc_locals;
  _safe_batch_transfer_loop(_from, to, ids_len, ids, amounts_len, amounts);

  TransferBatch.emit(operator, _from, to, ids_len, ids, amounts_len, amounts);
  _safe_batch_transfer_acceptance_check(
    _from, to, ids_len, ids, amounts_len, amounts, data_len, data
  );
  return ();
}

func _safe_batch_transfer_loop{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  _from: felt, to: felt, ids_len: felt, ids: Uint256*, amounts_len: felt, amounts: Uint256*
) {
  alloc_locals;

  if (ids_len == 0) {
    return ();
  }

  // ensures 'to' is not the zero address
  with_attr error_message("ERC1155: cannot transfer to the zero address") {
    assert_not_zero(to);
  }

  // Decrease owner balance
  let (owner_balance) = ERC1155_balances.read(_from, [ids]);
  let (new_balance: Uint256) = SafeUint256.sub_le(owner_balance, [amounts]);
  ERC1155_balances.write(_from, [ids], new_balance);

  // Increase receiver balance
  let (receiver_balance) = ERC1155_balances.read(to, [ids]);
  let (new_balance: Uint256) = SafeUint256.add(receiver_balance, [amounts]);
  ERC1155_balances.write(to, [ids], new_balance);

  // Update approval
  let (caller) = get_caller_address();
  let (local operator) = ERC1155_token_approval_operator.read(_from, [ids]);
  let (approved_amount) = ERC1155_token_approval_amount.read(_from, [ids]);

  if (operator == caller) {
    let (new_approved_amount) = SafeUint256.sub_le(approved_amount, [amounts]);
    _approve(owner=_from, operator=operator, token_id=[ids], amount=new_approved_amount);

    tempvar syscall_ptr = syscall_ptr;
    tempvar pedersen_ptr = pedersen_ptr;
    tempvar range_check_ptr = range_check_ptr;
  } else {
    let (approved_amount_too_high) = uint256_lt([amounts], approved_amount);
    if (approved_amount_too_high == TRUE) {
      _approve(owner=_from, operator=operator, token_id=[ids], amount=[amounts]);

      tempvar syscall_ptr = syscall_ptr;
      tempvar pedersen_ptr = pedersen_ptr;
      tempvar range_check_ptr = range_check_ptr;
    } else {
      tempvar syscall_ptr = syscall_ptr;
      tempvar pedersen_ptr = pedersen_ptr;
      tempvar range_check_ptr = range_check_ptr;
    }
  }

  _safe_batch_transfer_loop(
    _from, to, ids_len - 1, ids + Uint256.SIZE, amounts_len - 1, amounts + Uint256.SIZE
  );
  return ();
}

// Mint

func _safe_mint_batch{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  operator: felt,
  to: felt,
  ids_len: felt,
  ids: Uint256*,
  amounts_len: felt,
  amounts: Uint256*,
  data_len: felt,
  data: felt*,
) {
  alloc_locals;
  _mint_batch_loop(to, ids_len, ids, amounts);

  TransferBatch.emit(
    operator, _from=0, to=to, ids_len=ids_len, ids=ids, amounts_len=amounts_len, amounts=amounts
  );
  _safe_batch_transfer_acceptance_check(
    _from=0,
    to=to,
    ids_len=ids_len,
    ids=ids,
    amounts_len=amounts_len,
    amounts=amounts,
    data_len=data_len,
    data=data,
  );
  return ();
}

func _mint_batch{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  operator: felt,
  to: felt,
  ids_len: felt,
  ids: Uint256*,
  amounts_len: felt,
  amounts: Uint256*,
  data_len: felt,
  data: felt*,
) {
  alloc_locals;
  _mint_batch_loop(to, ids_len, ids, amounts);

  TransferBatch.emit(
    operator, _from=0, to=to, ids_len=ids_len, ids=ids, amounts_len=amounts_len, amounts=amounts
  );
  return ();
}

func _mint_batch_loop{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  to: felt, ids_len: felt, ids: Uint256*, amounts: Uint256*
) {
  if (ids_len == 0) {
    return ();
  }

  with_attr error_message("ERC1155: token_id is not a valid Uint256") {
    uint256_check([ids]);
  }

  let (is_amount_valid) = uint256_lt(Uint256(0, 0), [amounts]);
  with_attr error_message("ERC1155: minting null amount is not allowed") {
    assert is_amount_valid = TRUE;
  }

  // Update balances
  let (balance: Uint256) = ERC1155_balances.read(to, [ids]);

  let (new_balance: Uint256, _) = uint256_add(balance, [amounts]);
  ERC1155_balances.write(to, [ids], new_balance);

  _mint_batch_loop(
    to, ids_len=ids_len - 1, ids=ids + Uint256.SIZE, amounts=amounts + Uint256.SIZE
  );
  return ();
}

// Acceptance check

func _safe_transfer_acceptance_check{
  syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(_from: felt, to: felt, token_id: Uint256, amount: Uint256, data_len: felt, data: felt*) {
  // If `to` refers to a smart contract, it must implement {IERC1155_Receiver-onERC1155Received}
  // and return the acceptance magic value.
  let (success) = _check_onERC1155Received(_from, to, token_id, amount, data_len, data);
  with_attr error_message("ERC1155: transfer to non ERC1155Receiver implementer") {
    assert success = TRUE;
  }

  return ();
}

func _safe_batch_transfer_acceptance_check{
  syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(
  _from: felt,
  to: felt,
  ids_len: felt,
  ids: Uint256*,
  amounts_len: felt,
  amounts: Uint256*,
  data_len: felt,
  data: felt*,
) {
  // If `to` refers to a smart contract, it must implement {IERC1155_Receiver-onERC1155Received}
  // and return the acceptance magic value.
  let (success) = _check_onERC1155BatchReceived(
    _from, to, ids_len, ids, amounts_len, amounts, data_len, data
  );
  with_attr error_message("ERC1155: transfer to non ERC1155BatchReceiver implementer") {
    assert success = TRUE;
  }

  return ();
}

func _check_onERC1155Received{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  _from: felt, to: felt, token_id: Uint256, amount: Uint256, data_len: felt, data: felt*
) -> (success: felt) {
  let (caller) = get_caller_address();
  let (is_supported) = IERC165.supportsInterface(to, IERC1155_RECEIVER_ID);

  if (is_supported == TRUE) {
    let (selector) = IERC1155_Receiver.onERC1155Received(
      to, caller, _from, token_id, amount, data_len, data
    );

    assert selector = IERC1155_ACCEPTED_ID;
    return (TRUE,);
  }

  let (is_account) = IERC165.supportsInterface(to, IACCOUNT_ID);
  return (is_account,);
}

func _check_onERC1155BatchReceived{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  _from: felt,
  to: felt,
  ids_len: felt,
  ids: Uint256*,
  amounts_len: felt,
  amounts: Uint256*,
  data_len: felt,
  data: felt*,
) -> (success: felt) {
  let (caller) = get_caller_address();
  let (is_supported) = IERC165.supportsInterface(to, IERC1155_RECEIVER_ID);

  if (is_supported == TRUE) {
    let (selector) = IERC1155_Receiver.onERC1155BatchReceived(
      to, caller, _from, ids_len, ids, amounts_len, amounts, data_len, data
    );

    assert selector = IERC1155_BATCH_ACCEPTED_ID;
    return (TRUE,);
  }

  let (is_account) = IERC165.supportsInterface(to, IACCOUNT_ID);
  return (is_account,);
}
