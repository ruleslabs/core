%lang starknet

from starkware.cairo.common.uint256 import Uint256

from ruleslabs.models.card import CardModel
from ruleslabs.models.metadata import Metadata

@contract_interface
namespace IRulesPacks {
  func getPack(pack_id: Uint256) -> (cards_per_pack: felt, metadata: Metadata) {
  }

  func packExists(pack_id: Uint256) -> (res: felt) {
  }

  func getPackMaxSupply(pack_id: Uint256) -> (quantity: felt) {
  }

  func getPackCardModelQuantity(pack_id: Uint256, card_model: CardModel) -> (quantity: felt) {
  }
}
