%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IERC1155_MetadataURI {
  // Returns the URI for token type `id`.
  //
  // If the `\{id\}` substring is present in the URI, it must be replaced by
  // clients with the actual token type ID.
  func uri(tokenId: Uint256) -> (uri_len: felt, uri: felt*) {
  }
}
