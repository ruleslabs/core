%lang starknet
%builtins pedersen range_check bitwise

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256

from ruleslabs.models.metadata import Metadata
from ruleslabs.models.card import Card

// Libraries

from ruleslabs.contracts.RulesTokens.library import RulesTokens

from ruleslabs.token.ERC1155.ERC1155_base import (
  ERC1155_set_uri,
  ERC1155_uri,
  ERC1155_balance_of,
  ERC1155_approved_for_all,
  ERC1155_approved,
  ERC1155_initializer,
  ERC1155_set_approve_for_all,
  ERC1155_approve,
)

from ruleslabs.token.ERC1155.ERC1155_Metadata_base import (
  ERC1155_Metadata_base_token_uri,
  ERC1155_Metadata_set_base_token_uri,
)

from ruleslabs.token.ERC1155.ERC1155_Supply_base import ERC1155_Supply_total_supply

from ruleslabs.lib.Ownable_base import (
  Ownable_get_owner,
  Ownable_initializer,
  Ownable_only_owner,
  Ownable_transfer_ownership,
)

from ruleslabs.lib.roles.AccessControl_base import (
  AccessControl_has_role,
  AccessControl_roles_count,
  AccessControl_role_member,
  AccessControl_initializer,
)

from ruleslabs.lib.roles.minter import (
  Minter_role,
  Minter_initializer,
  Minter_only_minter,
  Minter_grant,
  Minter_revoke,
)

//
// Initializer
//

@external
func initialize{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  uri_len: felt, uri: felt*, owner: felt, _rules_cards_address: felt, _rules_packs_address: felt
) {
  ERC1155_initializer(uri_len, uri);
  Ownable_initializer(owner);
  AccessControl_initializer(owner);
  Minter_initializer(owner);

  RulesTokens.initializer(_rules_cards_address, _rules_packs_address);
  return ();
}

//
// Upgrade
//

@external
func upgrade{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  implementation: felt
) {
  Ownable_only_owner();
  RulesTokens.upgrade(implementation);
  return ();
}

//
// Getters
//

// URI
     
//  This implementation returns the same URI for all token types. It relies
//  on the token type ID substitution mechanism
//  https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
// 
//  Clients calling this function must replace the `\{id\}` substring with the
//  actual token type ID.
@view
func uri{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  id: Uint256
) -> (uri_len: felt, uri: felt*) {
  let (uri_len, uri) = ERC1155_uri();
  return (uri_len, uri);
}

// Roles

@view
func MINTER_ROLE{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
  role: felt
) {
  let (role) = Minter_role();
  return (role,);
}

@view
func owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (owner: felt) {
  let (owner) = Ownable_get_owner();
  return (owner,);
}

@view
func getRoleMember{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  role: felt, index: felt
) -> (account: felt) {
  let (account) = AccessControl_role_member(role, index);
  return (account,);
}

@view
func getRoleMemberCount{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  role: felt
) -> (count: felt) {
  let (count) = AccessControl_roles_count(role);
  return (count,);
}

@view
func hasRole{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  role: felt, account: felt
) -> (has_role: felt) {
  let (has_role) = AccessControl_has_role(role, account);
  return (has_role,);
}

@view
func getCard{
  syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(card_id: Uint256) -> (card: Card, metadata: Metadata) {
  let (card, metadata) = RulesTokens.card(card_id);
  return (card, metadata);
}

// Other contracts

@view
func rulesCards{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
  address: felt
) {
  let (address) = RulesTokens.rules_cards();
  return (address,);
}

@view
func rulesPacks{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
  address: felt
) {
  let (address) = RulesTokens.rules_packs();
  return (address,);
}

// Balance and supply

@view
func balanceOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  account: felt, token_id: Uint256
) -> (balance: Uint256) {
  let (balance) = ERC1155_balance_of(account, token_id);
  return (balance,);
}

@view
func totalSupply{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  token_id: Uint256
) -> (supply: Uint256) {
  let (supply) = ERC1155_Supply_total_supply(token_id);
  return (supply,);
}

// Approval

@view
func isApprovedForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  owner: felt, operator: felt
) -> (is_approved: felt) {
  let (is_approved) = ERC1155_approved_for_all(owner, operator);
  return (is_approved,);
}

@view
func getApproved{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  owner: felt, token_id: Uint256
) -> (operator: felt, amount: Uint256) {
  let (operator, amount) = ERC1155_approved(owner, token_id);
  return (operator, amount);
}

@view
func getUnlocked{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  owner: felt, token_id: Uint256
) -> (amount: Uint256) {
  let (amount) = RulesTokens.unlocked(owner, token_id);
  return (amount,);
}

//
// Setters
//

@external
func setUri{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  uri_len: felt, uri: felt*
) {
  Ownable_only_owner();
  ERC1155_set_uri(uri_len, uri);
  return ();
}

// Approval

@external
func setApprovalForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  operator: felt, approved: felt
) {
  ERC1155_set_approve_for_all(operator, approved);
  return ();
}

@external
func approve{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  to: felt, token_id: Uint256, amount: Uint256
) {
  ERC1155_approve(to, token_id, amount);
  return ();
}

//
// Business logic
//

// Roles

@external
func addMinter{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(account: felt) {
  Minter_grant(account);
  return ();
}

@external
func revokeMinter{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(account: felt) {
  Minter_revoke(account);
  return ();
}

// Cards

@external
func createAndMintCard{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  card: Card, metadata: Metadata, to: felt
) -> (token_id: Uint256) {
  Minter_only_minter();
  let (token_id) = RulesTokens.create_and_mint_card(card, metadata, to);
  return (token_id,);
}

@external
func mintCard{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  card_id: Uint256, to: felt
) -> (token_id: Uint256) {
  Minter_only_minter();
  let (token_id) = RulesTokens.mint_card(card_id, to);
  return (token_id,);
}

// Packs

@external
func mintPack{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  pack_id: Uint256, to: felt, amount: felt, unlocked: felt
) -> (token_id: Uint256) {
  Minter_only_minter();
  let (token_id) = RulesTokens.mint_pack(pack_id, to, amount, unlocked);
  return (token_id,);
}

@external
func openPackFrom{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  _from: felt,
  pack_id: Uint256,
  cards_len: felt,
  cards: Card*,
  metadata_len: felt,
  metadata: Metadata*,
) {
  Minter_only_minter();
  RulesTokens.open_pack_from(_from, pack_id, cards_len, cards, metadata_len, metadata);
  return ();
}

// Transfer

@external
func safeTransferFrom{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  _from: felt, to: felt, token_id: Uint256, amount: Uint256, data_len: felt, data: felt*
) {
  RulesTokens.safe_transfer_from(_from, to, token_id, amount, data_len, data);
  return ();
}

@external
func safeBatchTransferFrom{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  _from: felt,
  to: felt,
  ids_len: felt,
  ids: Uint256*,
  amounts_len: felt,
  amounts: Uint256*,
  data_len: felt,
  data: felt*,
) {
  RulesTokens.safe_batch_transfer_from(_from, to, ids_len, ids, amounts_len, amounts, data_len, data);
  return ();
}

// Ownership

@external
func transferOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  new_owner: felt
) -> (new_owner: felt) {
  Ownable_transfer_ownership(new_owner);
  return (new_owner,);
}

@external
func renounceOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
  Ownable_transfer_ownership(0);
  return ();
}
