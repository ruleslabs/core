%lang starknet
%builtins pedersen range_check bitwise

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256

from ruleslabs.models.metadata import Metadata
from ruleslabs.models.card import Card, CardModel
from ruleslabs.models.pack import PackCardModel

// Libraries

from ruleslabs.contracts.RulesCards.library import RulesCards

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

from ruleslabs.lib.roles.capper import (
  Capper_role,
  Capper_initializer,
  Capper_only_capper,
  Capper_grant,
  Capper_revoke,
)

from ruleslabs.lib.roles.packer import (
  Packer_role,
  Packer_initializer,
  Packer_only_packer,
  Packer_grant,
  Packer_revoke,
)

from ruleslabs.lib.scarcity.Scarcity_base import (
  Scarcity_max_supply,
  Scarcity_productionStopped,
  Scarcity_addScarcity,
  Scarcity_stopProduction,
)

// Interfaces

from ruleslabs.contracts.RulesData.IRulesData import IRulesData

//
// Initializer
//

@external
func initialize{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  owner: felt, _rules_data_address: felt
) {
  Ownable_initializer(owner);
  AccessControl_initializer(owner);
  Capper_initializer(owner);
  Packer_initializer(owner);
  Minter_initializer(owner);

  RulesCards.initializer(_rules_data_address);
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
  RulesCards.upgrade(implementation);
  return ();
}

//
// Getters
//

// Roles

@view
func CAPPER_ROLE{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
  role: felt
) {
  let (role) = Capper_role();
  return (role,);
}

@view
func PACKER_ROLE{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
  role: felt
) {
  let (role) = Packer_role();
  return (role,);
}

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
func cardExists{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  card_id: Uint256
) -> (res: felt) {
  let (exists) = RulesCards.card_exists(card_id);
  return (exists,);
}

@view
func getCard{
  syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(card_id: Uint256) -> (card: Card, metadata: Metadata) {
  let (card, metadata) = RulesCards.card(card_id);
  return (card, metadata);
}

@view
func getCardId{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(card: Card) -> (
  card_id: Uint256
) {
  let (card_id) = RulesCards.card_id(card);
  return (card_id,);
}

// Supply

@view
func getSupplyForSeasonAndScarcity{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  season: felt, scarcity: felt
) -> (supply: felt) {
  let (supply) = Scarcity_max_supply(season, scarcity);
  return (supply,);
}

@view
func productionStoppedForSeasonAndScarcity{
  syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(season: felt, scarcity: felt) -> (stopped: felt) {
  let (stopped) = Scarcity_productionStopped(season, scarcity);
  return (stopped,);
}

@view
func getCardModelAvailableSupply{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  card_model: CardModel
) -> (supply: felt) {
  let (supply) = RulesCards.card_model_available_supply(card_model);
  return (supply,);
}

// Other contracts

@view
func rulesData{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
  address: felt
) {
  let (address) = RulesCards.rules_data();
  return (address,);
}

//
// Externals
//

// Roles

@external
func addCapper{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(account: felt) {
  Capper_grant(account);
  return ();
}

@external
func addPacker{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(account: felt) {
  Packer_grant(account);
  return ();
}

@external
func addMinter{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(account: felt) {
  Minter_grant(account);
  return ();
}

@external
func revokeCapper{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(account: felt) {
  Capper_revoke(account);
  return ();
}

@external
func revokePacker{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(account: felt) {
  Packer_revoke(account);
  return ();
}

@external
func revokeMinter{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(account: felt) {
  Minter_revoke(account);
  return ();
}

// Supply

@external
func addScarcityForSeason{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  season: felt, supply: felt
) -> (scarcity: felt) {
  Capper_only_capper();

  let (scarcity) = Scarcity_addScarcity(season, supply);
  return (scarcity,);
}

@external
func stopProductionForSeasonAndScarcity{
  syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(season: felt, scarcity: felt) {
  Capper_only_capper();

  Scarcity_stopProduction(season, scarcity);
  return ();
}

// Cards

@external
func createCard{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  card: Card, metadata: Metadata, packed: felt
) -> (card_id: Uint256) {
  Minter_only_minter();

  let (card_id) = RulesCards.create_card(card, metadata, packed);
  return (card_id,);
}

@external
func packCardModel{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  pack_card_model: PackCardModel
) {
  Packer_only_packer();
  RulesCards.pack_card_model(pack_card_model);
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
