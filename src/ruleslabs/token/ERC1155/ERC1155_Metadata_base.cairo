%lang starknet

from starkware.cairo.common.bool import TRUE
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.alloc import alloc

from ruleslabs.lib.HexString import uint256_to_hs
from ruleslabs.lib.Array import concat_arr

//
// Storage
//

@storage_var
func ERC1155_base_token_uri(index: felt) -> (res: felt) {
}

@storage_var
func ERC1155_base_token_uri_len() -> (res: felt) {
}

//
// Getters
//

func ERC1155_Metadata_token_uri{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  token_id: Uint256
) -> (token_uri_len: felt, token_uri: felt*) {
  alloc_locals;

  let (base_token_uri_len, base_token_uri) = ERC1155_Metadata_base_token_uri();

  let (token_id_ss_len, token_id_ss) = uint256_to_hs(token_id);
  let (token_uri, token_uri_len) = concat_arr(
    base_token_uri_len, base_token_uri, token_id_ss_len, token_id_ss
  );

  return (token_uri_len=token_uri_len, token_uri=token_uri);
}

func ERC1155_Metadata_base_token_uri{
  syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() -> (base_token_uri_len: felt, base_token_uri: felt*) {
  alloc_locals;

  let (local base_token_uri) = alloc();
  let (local base_token_uri_len) = ERC1155_base_token_uri_len.read();

  _ERC1155_Metadata_base_token_uri(base_token_uri_len, base_token_uri);

  return (base_token_uri_len, base_token_uri);
}

//
// Externals
//

func ERC1155_Metadata_set_base_token_uri{
  syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(base_token_uri_len: felt, base_token_uri: felt*) {
  _ERC1155_Metadata_set_base_token_uri(base_token_uri_len, base_token_uri);
  ERC1155_base_token_uri_len.write(base_token_uri_len);
  return ();
}

//
// Internals
//

func _ERC1155_Metadata_base_token_uri{
  syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(base_token_uri_len: felt, base_token_uri: felt*) {
  if (base_token_uri_len == 0) {
    return ();
  }

  let (base) = ERC1155_base_token_uri.read(index=base_token_uri_len);
  assert [base_token_uri] = base;
  _ERC1155_Metadata_base_token_uri(
    base_token_uri_len=base_token_uri_len - 1, base_token_uri=base_token_uri + 1
  );
  return ();
}

func _ERC1155_Metadata_set_base_token_uri{
  syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(base_token_uri_len: felt, base_token_uri: felt*) {
  if (base_token_uri_len == 0) {
    return ();
  }

  ERC1155_base_token_uri.write(index=base_token_uri_len, value=[base_token_uri]);
  _ERC1155_Metadata_set_base_token_uri(
    base_token_uri_len=base_token_uri_len - 1, base_token_uri=base_token_uri + 1
  );
  return ();
}
