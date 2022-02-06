%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IRulesData:
  func createArtist(artist_name: Uint256):
  end

  func artistExists(artist_name: Uint256) -> (res: felt):
  end
end
