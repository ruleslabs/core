%lang starknet

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import (
  Uint256,
  uint256_lt,
  uint256_add,
  uint256_check,
  uint256_le,
  uint256_sub
)
from starkware.cairo.common.math import assert_not_zero, assert_not_equal
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.alloc import alloc

// Interfaces

from openzeppelin.introspection.erc165.IERC165 import IERC165
from ruleslabs.libraries.ERC1155.IERC1155Receiver import IERC1155Receiver

// Libraries

from openzeppelin.introspection.erc165.library import ERC165

// Constants

from ruleslabs.utils.constants import (
  IACCOUNT_ID,
  IERC1155_ID,
  IERC1155_ACCEPTED_ID,
  IERC1155_BATCH_ACCEPTED_ID,
  IERC1155_RECEIVER_ID
)

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

//
// Storage
//

@storage_var
func ERC1155_storage_uri(index: felt) -> (res: felt) {
}

@storage_var
func ERC1155_storage_uri_len() -> (res: felt) {
}

@storage_var
func ERC1155_balances(owner: felt, token_id: Uint256) -> (balance: Uint256) {
}

@storage_var
func ERC1155_operator_approvals(owner: felt, operator: felt) -> (res: felt) {
}

@storage_var
func ERC1155_marketplace() -> (marketplace: felt) {
}

namespace ERC1155 {

  // Init

  func initialize{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(uri_len: felt, uri: felt*) {
    set_uri(uri_len, uri);

    ERC165.register_interface(IERC1155_ID);
    return ();
  }

  // Getters

  func uri{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (uri_len: felt, uri: felt*) {
    alloc_locals;

    let (local uri) = alloc();
    let (local uri_len) = ERC1155_storage_uri_len.read();

    _load_uri(uri_len, uri);

    return (uri_len, uri);
  }

  func balance_of{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    account: felt,
    token_id: Uint256
  ) -> (balance: Uint256) {
    with_attr error_message("ERC1155: token_id is not a valid Uint256") {
      uint256_check(token_id);
    }

    let (balance: Uint256) = ERC1155_balances.read(account, token_id);
    return (balance,);
  }

  func approved_for_all{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt,
    operator: felt
  ) -> (is_approved: felt) {
    let (is_approved) = ERC1155_operator_approvals.read(owner, operator);
    return (is_approved,);
  }

  func marketplace{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (marketplace: felt) {
    let (marketplace) = ERC1155_marketplace.read();
    return (marketplace,);
  }

  //
  // Setters
  //

  func set_uri{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(uri_len: felt, uri: felt*) {
    _set_uri(uri_len, uri);
    ERC1155_storage_uri_len.write(uri_len);
    return ();
  }

  func set_approve_for_all{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    operator: felt,
    approved: felt
  ) {
    // Ensures operator is not null
    with_attr error_message("ERC1155: operator cannot be null") {
      assert_not_zero(operator);
    }

    let (caller) = get_caller_address();
    with_attr error_message("ERC1155: caller cannot approve itself") {
      assert_not_equal(caller, operator);
    }

    // Make sure `approved` is a boolean (0 or 1)
    with_attr error_message("ERC1155: approved is not a Cairo boolean") {
      assert approved * (1 - approved) = 0;
    }

    // store approval
    ERC1155_operator_approvals.write(owner=caller, operator=operator, value=approved);

    // emit event
    ApprovalForAll.emit(caller, operator, approved);

    return ();
  }

  func set_marketplace{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(marketplace: felt) {
    ERC1155_marketplace.write(marketplace);
    return ();
  }

  //
  // Business logic
  //

  // Transfer

  func safe_transfer_from{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _from: felt,
    to: felt,
    token_id: Uint256,
    amount: Uint256,
    data_len: felt,
    data: felt*
  ) {
    alloc_locals;

    with_attr error_message("ERC1155: caller is not token owner or approved") {
      let (is_approved_or_owner) = _is_approved_or_owner(_from);
      assert is_approved_or_owner = TRUE;
    }

    // execute transfer
    let (local caller) = get_caller_address();

    _safe_transfer(_from, to, token_id, amount, data_len, data);

    // emit event
    TransferSingle.emit(operator=caller, _from=_from, to=to, token_id=token_id, amount=amount);

    return ();
  }

  func safe_batch_transfer_from{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
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

    with_attr error_message("ERC1155: caller is not token owner or approved") {
      let (is_approved_or_owner) = _is_approved_or_owner(_from);
      assert is_approved_or_owner = TRUE;
    }

    // execute transfer
    let (local caller) = get_caller_address();

    _safe_batch_transfer(_from, to, ids_len, ids, amounts_len, amounts, data_len, data);

    // emit event
    TransferBatch.emit(
      operator=caller,
      _from=_from,
      to=to,
      ids_len=ids_len,
      ids=ids,
      amounts_len=amounts_len,
      amounts=amounts
    );

    return ();
  }

  // Mint

  // must be unsafe to avoid user interaction during pack or card delivery
  func mint{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    to: felt, token_id: Uint256, amount: Uint256, data_len: felt, data: felt*
  ) {
    with_attr error_message("ERC1155: minting to null address is not allowed") {
      assert_not_zero(to);
    }

    // execute mint
    _mint(to, token_id, amount);

    // emit event
    let (caller) = get_caller_address();
    TransferSingle.emit(operator=caller, _from=0, to=to, token_id=token_id, amount=amount);

    return ();
  }

  func mint_batch{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
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

    with_attr error_message("ERC1155: minting to null address is not allowed") {
      assert_not_zero(to);
    }

    // execute mint
    let (local caller) = get_caller_address();

    _mint_batch(to, ids_len, ids, amounts);

    // emit event
    TransferBatch.emit(
      operator=caller,
      _from=0,
      to=to,
      ids_len=ids_len,
      ids=ids,
      amounts_len=amounts_len,
      amounts=amounts
    );

    return ();
  }

  // Burn

  func burn{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _from: felt, token_id: Uint256, amount: Uint256
  ) {
    // execute burn
    _burn(_from, token_id, amount);

    // emit event
    let (caller) = get_caller_address();
    TransferSingle.emit(operator=caller, _from=_from, to=0, token_id=token_id, amount=amount);

    return ();
  }

  // Internals

  // uri

  func _load_uri{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(uri_len: felt, uri: felt*) {
    // loop condition
    if (uri_len == 0) {
      return ();
    }

    let (base) = ERC1155_storage_uri.read(index=uri_len);
    assert [uri] = base;

    // iterate
    _load_uri(uri_len=uri_len - 1, uri=uri + 1);
    return ();
  }

  func _set_uri{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
  }(uri_len: felt, uri: felt*) {
    if (uri_len == 0) {
      return ();
    }

    ERC1155_storage_uri.write(index=uri_len, value=[uri]);
    set_uri(uri_len=uri_len - 1, uri=uri + 1);
    return ();
  }

  // approve or owner

  func _is_approved_or_owner{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    owner: felt
  ) -> (res: felt) {
    let (caller) = get_caller_address();

    // is owner?
    if (owner == caller) {
      return (TRUE,);
    }

    // is approved?
    let (is_approved) = approved_for_all(owner=owner, operator=caller);
    if (is_approved == TRUE) {
      return (TRUE,);
    }

    // is marketplace?
    let (marketplace_address) = marketplace(); // TODO: Replace with signatures mechanism
    if (marketplace_address == caller) {
      return (TRUE,);
    } else {
      return (FALSE,);
    }
  }

  // Transfer

  func _transfer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _from: felt,
    to: felt,
    token_id: Uint256,
    amount: Uint256
  ) {
    with_attr error_message("ERC1155: token_id is not a valid Uint256") {
      uint256_check(token_id);
    }
    // ensures 'to' is not the zero address
    with_attr error_message("ERC1155: cannot transfer to the zero address") {
      assert_not_zero(to);
    }

    // Ensures `_from` hold enough tokens
    let (owner_balance) = ERC1155_balances.read(_from, token_id);
    with_attr error_message("ERC1155: Insuffisant balance") {
      let (valid_amount) = uint256_le(amount, owner_balance);
      assert valid_amount = TRUE;
    }

    // Decrease owner balance
    let (new_owner_balance: Uint256) = uint256_sub(owner_balance, amount);
    ERC1155_balances.write(_from, token_id, new_owner_balance);

    // Increase receiver balance
    let (receiver_balance) = ERC1155_balances.read(to, token_id);
    let (new_receiver_balance: Uint256, _) = uint256_add(receiver_balance, amount);
    ERC1155_balances.write(to, token_id, new_receiver_balance);

    return ();
  }

  func _safe_transfer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _from: felt,
    to: felt,
    token_id: Uint256,
    amount: Uint256,
    data_len: felt,
    data: felt*,
  ) {
    _transfer(_from, to, token_id, amount);

    // safety check
    let (success) = _check_onERC1155Received(_from, to, token_id, amount, data_len, data);
    with_attr error_message("ERC1155: transfer to non ERC1155Receiver implementer") {
      assert success = TRUE;
    }

    return ();
  }

  // Batch transfer

  func _safe_batch_transfer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _from: felt,
    to: felt,
    ids_len: felt,
    ids: Uint256*,
    amounts_len: felt,
    amounts: Uint256*,
    data_len: felt,
    data: felt*,
  ) {
    _safe_batch_transfer_loop(_from, to, ids_len, ids, amounts);

    // safety check
    with_attr error_message("ERC1155: transfer to non ERC1155BatchReceiver implementer") {
      let (success) = _check_onERC1155BatchReceived(_from, to, ids_len, ids, amounts_len, amounts, data_len, data);
      assert success = TRUE;
    }

    return ();
  }

  func _safe_batch_transfer_loop{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _from: felt,
    to: felt,
    ids_len: felt,
    ids: Uint256*,
    amounts: Uint256*
  ) {
    // condition
    if (ids_len == 0) {
      return ();
    }

    _transfer(_from, to, [ids], [amounts]);

    // iterate
    _safe_batch_transfer_loop(_from, to, ids_len - 1, ids + Uint256.SIZE, amounts + Uint256.SIZE);
    return ();
  }

  // Mint

  func _mint{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    to: felt,
    token_id: Uint256,
    amount: Uint256,
  ) {
    with_attr error_message("ERC1155: token_id is not a valid Uint256") {
      uint256_check(token_id);
    }

    with_attr error_message("ERC1155: minting null amount is not allowed") {
      let (is_amount_valid) = uint256_lt(Uint256(0, 0), amount);
      assert is_amount_valid = TRUE;
    }

    // Update balances
    let (balance: Uint256) = ERC1155_balances.read(to, token_id);

    let (new_balance: Uint256, _) = uint256_add(balance, amount);
    ERC1155_balances.write(to, token_id, new_balance);

    return ();
  }

  func _mint_batch{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    to: felt,
    ids_len: felt,
    ids: Uint256*,
    amounts: Uint256*,
  ) {
    // condition
    if (ids_len == 0) {
      return ();
    }

    _mint(to, [ids], [amounts]);

    // iterate
    _mint_batch(to, ids_len=ids_len - 1, ids=ids + Uint256.SIZE, amounts=amounts + Uint256.SIZE);
    return ();
  }

  // Burn

  func _burn{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _from: felt,
    token_id: Uint256,
    amount: Uint256,
  ) {
    with_attr error_message("ERC1155: token_id is not a valid Uint256") {
      uint256_check(token_id);
    }

    with_attr error_message("ERC1155: burning null amount is not allowed") {
      let (is_amount_valid) = uint256_lt(Uint256(0, 0), amount);
      assert is_amount_valid = TRUE;
    }

    // Ensures `_from` hold enough tokens
    let (balance) = ERC1155_balances.read(_from, token_id);
    with_attr error_message("ERC1155: Insuffisant balance") {
      let (valid_amount) = uint256_le(amount, balance);
      assert valid_amount = TRUE;
    }

    let (new_balance: Uint256) = uint256_sub(balance, amount);
    ERC1155_balances.write(_from, token_id, new_balance);

    return ();
  }

  // Safety checks

  func _check_onERC1155Received{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _from: felt,
    to: felt,
    token_id: Uint256,
    amount: Uint256,
    data_len: felt,
    data: felt*
  ) -> (success: felt) {
    let (is_supported) = IERC165.supportsInterface(to, IERC1155_RECEIVER_ID);

    if (is_supported == TRUE) {
      let (caller) = get_caller_address();
      let (selector) = IERC1155Receiver.onERC1155Received(to, caller, _from, token_id, amount, data_len, data);

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
    let (is_supported) = IERC165.supportsInterface(to, IERC1155_RECEIVER_ID);

    if (is_supported == TRUE) {
      let (caller) = get_caller_address();

      let (selector) = IERC1155Receiver.onERC1155BatchReceived(
        to, caller, _from, ids_len, ids, amounts_len, amounts, data_len, data
      );

      assert selector = IERC1155_BATCH_ACCEPTED_ID;
      return (TRUE,);
    }

    let (is_account) = IERC165.supportsInterface(to, IACCOUNT_ID);
    return (is_account,);
  }
}
