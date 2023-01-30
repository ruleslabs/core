%lang starknet

from starkware.cairo.common.uint256 import Uint256

from ruleslabs.models.metadata import Metadata
from ruleslabs.models.card import Card

@contract_interface
namespace IRulesTokens {
  func safeTransferFrom(
    _from: felt, to: felt, token_id: Uint256, amount: Uint256, data_len: felt, data: felt*
  ) {
  }

  func openPackTo(
    to: felt,
    pack_id: Uint256,
    cards_len: felt,
    cards: Card*,
    metadata_len: felt,
    metadata: Metadata*,
  ) {
  }

  func getApproved(owner: felt, token_id: Uint256) -> (operator: felt, amount: Uint256) {
  }
}
