%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc

// Storage

@storage_var
func ERC1155ContractURI_uri_words(index: felt) -> (res: felt) {
}

@storage_var
func ERC1155ContractURI_uri_len() -> (res: felt) {
}

namespace ERC1155ContractURI {

  // getters

  func contract_uri{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    contract_uri_len: felt,
    contract_uri: felt*
  ) {
    alloc_locals;

    let (local contract_uri) = alloc();
    let (local contract_uri_len) = ERC1155ContractURI_uri_len.read();

    _load_contract_uri(contract_uri_len, contract_uri);

    return (contract_uri_len, contract_uri);
  }

  // setters

  func set_contract_uri{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    contract_uri_len: felt,
    contract_uri: felt*
  ) {
    _set_contract_uri(contract_uri_len, contract_uri);
    ERC1155ContractURI_uri_len.write(contract_uri_len);

    return ();
  }

  // Internals

  func _load_contract_uri{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    contract_uri_len: felt,
    contract_uri: felt*
  ) {
    // condition
    if (contract_uri_len == 0) {
      return ();
    }

    let (contract_uri_word) = ERC1155ContractURI_uri_words.read(index=contract_uri_len);
    assert [contract_uri] = contract_uri_word;

    // iterate
    _load_contract_uri(contract_uri_len=contract_uri_len - 1, contract_uri=contract_uri + 1);
    return ();
  }

  func _set_contract_uri{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    contract_uri_len: felt,
    contract_uri: felt*
  ) {
    // condition
    if (contract_uri_len == 0) {
      return ();
    }

    ERC1155ContractURI_uri_words.write(index=contract_uri_len, value=[contract_uri]);

    // iterate
    _set_contract_uri(contract_uri_len=contract_uri_len - 1, contract_uri=contract_uri + 1);
    return ();
  }
}
