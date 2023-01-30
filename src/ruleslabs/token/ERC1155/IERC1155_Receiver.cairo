%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IERC1155_Receiver {
  func onERC1155Received(
    operator: felt, _from: felt, id: Uint256, value: Uint256, data_len: felt, data: felt*
  ) -> (selector: felt) {
  }

  func onERC1155BatchReceived(
    operator: felt,
    _from: felt,
    ids_len: felt,
    ids: felt*,
    values_len: felt,
    values: felt*,
    data_len: felt,
    data: felt*,
  ) -> (selector: felt) {
  }

  // ERC1155's `safeTransferFrom` requires a means of differentiating between account and
  // non-account contracts. Currently, StarkNet does not support error handling from the
  // contract level; therefore, this ERC1155 implementation requires that all contracts that
  // support safe ERC1155 transfers (both accounts and non-accounts) include the `is_account`
  // method. This method should return `0` since it's NOT an account.
  func is_account() -> (res: felt) {
  }
}
