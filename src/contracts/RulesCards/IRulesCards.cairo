%lang starknet

from starkware.cairo.common.uint256 import Uint256

from models.metadata import Metadata
from models.card import Card
from models.pack import PackCardModel

@contract_interface
namespace IRulesCards:

  #
  # Getters
  #

  func getCard(card_id: Uint256) -> (card: Card, metadata: Metadata):
  end

  func cardExists(card_id: Uint256) -> (res: felt):
  end

  func productionStoppedForSeasonAndScarcity(season: felt, scarcity: felt) -> (stopped: felt):
  end

  #
  # Business logic
  #

  func createCard(card: Card, metadata: Metadata) -> (card_id: Uint256):
  end

  func packCardModel(pack_card_model: PackCardModel):
  end
end
