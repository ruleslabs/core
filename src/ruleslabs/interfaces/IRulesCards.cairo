%lang starknet

from starkware.cairo.common.uint256 import Uint256

from ruleslabs.utils.metadata import Metadata
from ruleslabs.utils.card import Card

@contract_interface
namespace IRulesCards {

  // Getters

  func cardExists(card_id: Uint256) -> (exists: felt) {
  }

  func getCard(card_id: Uint256) -> (card: Card, metadata: Metadata) {
  }
}
