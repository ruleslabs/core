%lang starknet

from starkware.cairo.common.uint256 import Uint256

from contracts.models.card import Card

@contract_interface
namespace IRavageCards:
  func getCard(card_id: Uint256) -> (card: Card):
  end

  func createCard(card: Card) -> (card_id: Uint256):
  end

  func cardExists(card_id: Uint256) -> (res: felt):
  end
end
