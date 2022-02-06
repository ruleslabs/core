%lang starknet
%builtins pedersen range_check bitwise

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.uint256 import Uint256

from contracts.models.card import (
  Card, CardMetadata, get_card_id_from_card, card_is_null
)

from contracts.lib.Ownable_base import (
  Ownable_get_owner,

  Ownable_initializer,
  Ownable_only_owner
)

from contracts.lib.roles.AccessControl_base import (
  AccessControl_has_role,
  AccessControl_roles_count,
  AccessControl_get_role_member,

  AccessControl_initializer
)

from contracts.lib.roles.minter import (
  Minter_role,

  Minter_initializer,
  Minter_only_minter,
  Minter_grant,
  Minter_revoke
)

from contracts.lib.roles.capper import (
  Capper_role,

  Capper_initializer,
  Capper_only_capper,
  Capper_grant,
  Capper_revoke
)

from contracts.interfaces.IRulesData import IRulesData

const TRUE = 1
const FALSE = 0

#
# Storage
#

@storage_var
func cards_storage(card_id: Uint256) -> (card: Card):
end

@storage_var
func rules_data_address_storage() -> (rules_data_address: felt):
end

#
# Constructor
#

@constructor
func constructor{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    bitwise_ptr: BitwiseBuiltin*,
    range_check_ptr
  }(owner: felt, _rules_data_address: felt):
  rules_data_address_storage.write(_rules_data_address)

  Ownable_initializer(owner)
  AccessControl_initializer(owner)
  Capper_initializer(owner)
  Minter_initializer(owner)

  return ()
end

#
# Getters
#

# Roles

@view
func CAPPER_ROLE{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }() -> (role: felt):
  let (role) = Capper_role()
  return (role)
end

@view
func MINTER_ROLE{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }() -> (role: felt):
  let (role) = Minter_role()
  return (role)
end

@view
func owner{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }() -> (owner: felt):
  let (owner) = Ownable_get_owner()
  return (owner)
end

@view
func getRoleMember{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(role: felt, index: felt) -> (account: felt):
  let (account) = AccessControl_get_role_member(role, index)
  return (account)
end

@view
func getRoleMemberCount{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(role: felt) -> (count: felt):
  let (count) = AccessControl_roles_count(role)
  return (count)
end

@view
func hasRole{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(role: felt, account: felt) -> (has_role: felt):
  let (has_role) = AccessControl_has_role(role, account)
  return (has_role)
end

@view
func cardExists{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(card_id: Uint256) -> (res: felt):
  let (card) = cards_storage.read(card_id)
  let (is_null) = card_is_null(card)

  tempvar syscall_ptr = syscall_ptr
  tempvar pedersen_ptr = pedersen_ptr
  tempvar range_check_ptr = range_check_ptr

  if is_null == 1:
      return (FALSE)
  else:
      return (TRUE)
  end
end

@view
func getCard{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(card_id: Uint256) -> (card: Card):
  let (card) = cards_storage.read(card_id)

  return (card)
end

@view
func getCardId{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    bitwise_ptr: BitwiseBuiltin*,
    range_check_ptr
  }(card: Card) -> (card_id: Uint256):
  let (card_id) = get_card_id_from_card(card)

  return (card_id)
end

#
# Externals
#

# Roles

@external
func addCapper{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(account: felt):
  Capper_grant(account)
  return ()
end

@external
func addMinter{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(account: felt):
  Minter_grant(account)
  return ()
end

@external
func revokeCapper{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(account: felt):
  Capper_revoke(account)
  return ()
end

@external
func revokeMinter{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(account: felt):
  Minter_revoke(account)
  return ()
end

@external
func createCard{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    bitwise_ptr: BitwiseBuiltin*,
    range_check_ptr
  }(card: Card) -> (card_id: Uint256):
  alloc_locals

  let (rules_data_address) = rules_data_address_storage.read()

  let (artist_exists) = IRulesData.artistExists(rules_data_address, card.artist_name)
  assert_not_zero(artist_exists) # Unknown artist

  let (local card_id) = get_card_id_from_card(card)

  let (exists) = cardExists(card_id)
  assert exists = FALSE # Card already exists

  cards_storage.write(card_id, card)

  return (card_id)
end
