%lang starknet
%builtins pedersen range_check bitwise

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.math import assert_le

// Libraries

from ruleslabs.libraries.ERC1155.ERC1155 import ERC1155
from ruleslabs.libraries.ERC1155.ERC1155ContractURI import ERC1155ContractURI
from ruleslabs.libraries.Ownable import Ownable
from ruleslabs.libraries.AccessControl import AccessControl
from ruleslabs.libraries.Upgradeable import Upgradeable
from ruleslabs.libraries.Cards import Cards
from ruleslabs.libraries.Packs import Packs
from ruleslabs.libraries.Scarcity import Scarcity

// Utils

from ruleslabs.utils.metadata import Metadata, FeltMetadata
from ruleslabs.utils.card import Card

// Constants

from ruleslabs.utils.constants import MINTER_ROLE_ID, CAPPER_ROLE_ID, IDENTITY

// Init

@external
func initialize{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  uri_len: felt,
  uri: felt*,
  owner: felt
) {
  ERC1155.initialize(uri_len, uri);

  Ownable.initialize(owner);

  AccessControl.initialize(owner);
  AccessControl._grant_role(MINTER_ROLE_ID, owner);
  AccessControl._grant_role(CAPPER_ROLE_ID, owner);

  Upgradeable.initialize();

  return ();
}

// Upgrade

@external
func upgrade{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(implementation: felt) {
  Ownable.only_owner();
  Upgradeable.upgrade(implementation);
  return ();
}

// Getters

@view
func getIdentity() -> (role: felt) {
  return (IDENTITY,); // Rules
}

// URI

//  This implementation returns the same URI for all token types. It relies
//  on the token type ID substitution mechanism
//  https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
//
//  Clients calling this function must replace the `\{id\}` substring with the
//  actual token type ID.
@view
func uri{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(id: Uint256) -> (uri_len: felt, uri: felt*) {
  let (uri_len, uri) = ERC1155.uri();
  return (uri_len, uri);
}

@view
func contractURI{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
  contractURI_len: felt,
  contractURI: felt*
) {
  let (contract_uri_len, contract_uri) = ERC1155ContractURI.contract_uri();
  return (contract_uri_len, contract_uri);
}

// Roles

@view
func MINTER_ROLE() -> (role: felt) {
  return (MINTER_ROLE_ID,);
}

@view
func CAPPER_ROLE() -> (role: felt) {
  return (CAPPER_ROLE_ID,);
}

@view
func owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (owner: felt) {
  let (owner) = Ownable.owner();
  return (owner,);
}

@view
func roleMember{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  role: felt,
  index: felt
) -> (account: felt) {
  let (account) = AccessControl.role_member(role, index);
  return (account,);
}

@view
func roleMembersCount{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(role: felt) -> (count: felt) {
  let (count) = AccessControl.roles_count(role);
  return (count,);
}

@view
func hasRole{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  role: felt,
  account: felt
) -> (has_role: felt) {
  let (has_role) = AccessControl.has_role(role, account);
  return (has_role,);
}

// cards

@view
func card{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(
  card_id: Uint256
) -> (card: Card, metadata: FeltMetadata) {
  let (card, metadata) = Cards.card(card_id);
  return (card, metadata);
}

@view
func oldCard{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(
  card_id: Uint256
) -> (card: Card, metadata: Metadata) {
  let (card, metadata) = Cards.old_card(card_id);
  return (card, metadata);
}

@view
func cardId{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(card: Card) -> (card_id: Uint256) {
  let (card_id) = Cards.cardId(card);
  return (card_id,);
}

@view
func cardExists{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(card_id: Uint256) -> (res: felt) {
  let (exists) = Cards.card_exists(card_id);
  return (exists,);
}

// packs

@view
func pack{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  pack_id: Uint256
) -> (max_supply: felt, metadata: Metadata) {
  let (max_supply, metadata) = Packs.pack(pack_id);
  return (max_supply, metadata);
}

@view
func packExists{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(pack_id: Uint256) -> (res: felt) {
  let (exists) = Packs.pack_exists(pack_id);
  return (exists,);
}

// Balance and supply

@view
func balanceOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  account: felt, token_id: Uint256
) -> (balance: Uint256) {
  let (balance) = ERC1155.balance_of(account, token_id);
  return (balance,);
}

@view
func scarcityMaxSupply{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  season: felt,
  scarcity: felt
) -> (max_supply: felt) {
  let (max_supply) = Scarcity.max_supply(season, scarcity);
  return (max_supply,);
}

// Approval

@view
func isApprovedForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  owner: felt,
  operator: felt
) -> (is_approved: felt) {
  let (is_approved) = ERC1155.approved_for_all(owner, operator);
  return (is_approved,);
}

@view
func getUnlocked{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  owner: felt,
  token_id: Uint256
) -> (amount: felt) {
  let (amount) = Packs.unlocked(owner, token_id);
  return (amount,);
}

@view
func marketplace{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (marketplace: felt) {
  let (marketplace) = ERC1155.marketplace();
  return (marketplace,);
}

//
// Setters
//

@external
func setUri{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(uri_len: felt, uri: felt*) {
  // modifiers
  Ownable.only_owner();

  // body
  ERC1155.set_uri(uri_len, uri);
  return ();
}

@external
func setContractURI{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  contract_uri_len: felt,
  contract_uri: felt*
) {
  // modifiers
  Ownable.only_owner();

  // body
  ERC1155ContractURI.set_contract_uri(contract_uri_len, contract_uri);
  return ();
}

// Approval

@external
func setApprovalForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  operator: felt,
  approved: felt
) {
  ERC1155.set_approve_for_all(operator, approved);
  return ();
}

@external
func setMarketplace{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(marketplace: felt) {
  // modifiers
  Ownable.only_owner();

  // body
  ERC1155.set_marketplace(marketplace);
  return ();
}

// Business logic

// MINTER

@external
func addMinter{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(account: felt) {
  AccessControl.grant_role(MINTER_ROLE_ID, account);
  return ();
}

@external
func revokeMinter{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(account: felt) {
  AccessControl.revoke_role(MINTER_ROLE_ID, account);
  return ();
}

// CAPPER

@external
func addCapper{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(account: felt) {
  AccessControl.grant_role(CAPPER_ROLE_ID, account);
  return ();
}

@external
func revokeCapper{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(account: felt) {
  AccessControl.revoke_role(CAPPER_ROLE_ID, account);
  return ();
}

// Cards

@external
func createAndMintCard{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  to: felt,
  card: Card,
  metadata: FeltMetadata
) {
  // modifiers
  AccessControl.only_role(MINTER_ROLE_ID);

  // body

  // create card
  let (card_id) = Cards.create_card(card, metadata);

  // mint card
  let data = cast(0, felt*);
  ERC1155.mint(to, card_id, amount=Uint256(1, 0), data_len=0, data=data);

  return ();
}

// Packs

@external
func createPack{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  max_supply: felt,
  metadata: Metadata
) -> (pack_id: Uint256) {
  // modifiers
  AccessControl.only_role(MINTER_ROLE_ID);

  // body
  let (pack_id) = Packs.create_pack(max_supply, metadata);
  return (pack_id,);
}

@external
func createCommonPack{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  season: felt,
  metadata: Metadata
) -> (pack_id: Uint256) {
  // modifiers
  AccessControl.only_role(MINTER_ROLE_ID);

  // body
  let (pack_id) = Packs.create_common_pack(season, metadata);
  return (pack_id,);
}

@external
func mintPack{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  to: felt,
  pack_id: Uint256,
  amount: felt, // a Uint256 would be overkill
  unlocked: felt
) {
  // modifiers
  AccessControl.only_role(MINTER_ROLE_ID);

  // body
  Packs.decrease_available_pack_supply(pack_id, amount);

  let data = cast(0, felt*);
  ERC1155.mint(to, pack_id, amount=Uint256(amount, 0), data_len=0, data=data);

  if (unlocked == TRUE) {
  Packs.unlock(to, pack_id, amount);
  return ();
  }

  return ();
}

@external
func openPackFrom{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  _from: felt,
  pack_id: Uint256,
  cards_len: felt,
  cards: Card*,
  metadata_len: felt,
  metadata: FeltMetadata*
) {
  // modifiers
  AccessControl.only_role(MINTER_ROLE_ID);

  // body
  Packs.open_pack_from(_from, pack_id, cards_len, cards, metadata_len, metadata);
  return ();
}

// Scarcities

@external
func addScarcityForSeason{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  season: felt,
  supply: felt
) -> (scarcity: felt) {
  // modifiers
  AccessControl.only_role(CAPPER_ROLE_ID);

  let (scarcity) = Scarcity.add_scarcity(season, supply);
  return (scarcity,);
}

// Transfer

@external
func safeTransferFrom{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  _from: felt,
  to: felt,
  token_id: Uint256,
  amount: Uint256,
  data_len: felt,
  data: felt*
) {
  // assert there token is not a locked pack
  _transfer_lock(_from, to, token_id, amount);

  ERC1155.safe_transfer_from(_from, to, token_id, amount, data_len, data);
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
  // assert there is not locked pack in the batch
  _transfer_lock_batch(_from, to, ids_len, ids, amounts);

  ERC1155.safe_batch_transfer_from(_from, to, ids_len, ids, amounts_len, amounts, data_len, data);
  return ();
}

// Ownership

@external
func transferOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  new_owner: felt
) -> (new_owner: felt) {
  Ownable.transfer_ownership(new_owner);
  return (new_owner,);
}

@external
func renounceOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
  Ownable.renounce_ownership();
  return ();
}

// Internals

func _transfer_lock{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  _from: felt,
  to: felt,
  token_id: Uint256,
  amount: Uint256
) {
  if (token_id.low * token_id.high != 0) {
  return ();
  }

  Packs.lock(_from, token_id, amount.low);
  Packs.unlock(to, token_id, amount.low);

  return ();
}

func _transfer_lock_batch{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  _from: felt,
  to: felt,
  ids_len: felt,
  ids: Uint256*,
  amounts: Uint256*,
) {
  // condition
  if (ids_len == 0) {
  return ();
  }

  _transfer_lock(_from, to, [ids], [amounts]);

  // iterate
  _transfer_lock_batch(_from, to, ids_len - 1, ids + Uint256.SIZE, amounts + Uint256.SIZE);
  return ();
}
