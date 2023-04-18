%lang starknet
%builtins pedersen range_check

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from ruleslabs.models.card import CardModel
from ruleslabs.models.metadata import Metadata

// Libraries

from ruleslabs.contracts.RulesPacks.library import RulesPacks

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
  owner: felt, _rules_data_address: felt, _rules_cards_address: felt
) {
  Ownable_initializer(owner);
  AccessControl_initializer(owner);
  Minter_initializer(owner);

  RulesPacks.initializer(_rules_data_address, _rules_cards_address);
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
  RulesPacks.upgrade(implementation);
  return ();
}

//
// Getters
//

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
func getPackMaxSupply{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  pack_id: Uint256
) -> (quantity: felt) {
  let (max_supply) = RulesPacks.pack_max_supply(pack_id);
  return (max_supply,);
}

@view
func packExists{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  pack_id: Uint256
) -> (res: felt) {
  let (exists) = RulesPacks.pack_exists(pack_id);
  return (exists,);
}

@view
func getPack{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(pack_id: Uint256) -> (
  metadata: Metadata
) {
  let (metadata) = RulesPacks.pack(pack_id);
  return (metadata,);
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

@external
func createPack{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  max_supply: felt,
  metadata: Metadata
) -> (pack_id: Uint256) {
  Minter_only_minter();
  let (pack_id) = RulesPacks.create_pack(max_supply, metadata);
  return (pack_id,);
}

@external
func createCommonPack{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  season: felt, metadata: Metadata
) -> (pack_id: Uint256) {
  Minter_only_minter();
  let (pack_id) = RulesPacks.create_common_pack(season, metadata);
  return (pack_id,);
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
