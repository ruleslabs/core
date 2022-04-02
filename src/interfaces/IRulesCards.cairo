%lang starknet

from starkware.cairo.common.uint256 import Uint256

from models.card import Card, CardMetadata

@contract_interface
namespace IRulesCards:
  func getCard(card_id: Uint256) -> (card: Card, metadata: CardMetadata):
  end

  func createCard(card: Card, metadata: CardMetadata) -> (card_id: Uint256):
  end

  func cardExists(card_id: Uint256) -> (res: felt):
  end
end
