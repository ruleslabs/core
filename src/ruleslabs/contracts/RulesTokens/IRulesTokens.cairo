%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IRulesTokens:

  func safeTransferFrom(_from: felt, to: felt, token_id: Uint256, amount: Uint256, data_len: felt, data: felt*):
  end

  func openPackTo(to: felt, pack_id: Uint256, cards_len: felt, cards: Card*, metadata_len: felt, metadata: Metadata*):
  end
end
