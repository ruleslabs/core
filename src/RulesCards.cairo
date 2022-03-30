%lang starknet
%builtins pedersen range_check bitwise

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import assert_not_zero, assert_le
from starkware.cairo.common.math_cmp import is_not_zero
from starkware.cairo.common.uint256 import Uint256

from models.card import (
  Card, CardMetadata, get_card_id_from_card, card_is_null
)

# AccessControl/Ownable

from lib.Ownable_base import (
  Ownable_get_owner,

  Ownable_initializer,
  Ownable_only_owner,
  Ownable_transfer_ownership
)

from lib.roles.AccessControl_base import (
  AccessControl_hasRole,
  AccessControl_rolesCount,
  AccessControl_getRoleMember,

  AccessControl_initializer
)

from lib.roles.minter import (
  Minter_role,

  Minter_initializer,
  Minter_onlyMinter,
  Minter_grant,
  Minter_revoke
)

from lib.roles.capper import (
  Capper_role,

  Capper_initializer,
  Capper_onlyCapper,
  Capper_grant,
  Capper_revoke
)

# Supply

from lib.scarcity.Scarcity_base import (
  Scarcity_supply,
  Scarcity_productionStopped,

  Scarcity_addScarcity,
  Scarcity_stopProduction
)

# Constants

from openzeppelin.utils.constants import TRUE, FALSE

#
# Import interfaces
#

from interfaces.IRulesData import IRulesData

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
  let (account) = AccessControl_getRoleMember(role, index)
  return (account)
end

@view
func getRoleMemberCount{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(role: felt) -> (count: felt):
  let (count) = AccessControl_rolesCount(role)
  return (count)
end

@view
func hasRole{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(role: felt, account: felt) -> (has_role: felt):
  let (has_role) = AccessControl_hasRole(role, account)
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

# Supply

@view
func getSupplyForSeasonAndScarcity{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(season: felt, scarcity: felt) -> (supply: felt):
  let (supply) = Scarcity_supply(season, scarcity)
  return (supply)
end

@view
func productionStoppedForSeasonAndScarcity{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(season: felt, scarcity: felt) -> (stopped: felt):
  let (stopped) = Scarcity_productionStopped(season, scarcity)
  return (stopped)
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

# Supply

@external
func addScarcityForSeason{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(season: felt, supply: felt) -> (scarcity: felt):
  Capper_onlyCapper()

  let (scarcity) = Scarcity_addScarcity(season, supply)
  return (scarcity)
end

@external
func stopProductionForSeasonAndScarcity{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(season: felt, scarcity: felt):
  Capper_onlyCapper()

  Scarcity_stopProduction(season, scarcity)
  return ()
end

# Cards

@external
func createCard{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    bitwise_ptr: BitwiseBuiltin*,
    range_check_ptr
  }(card: Card) -> (card_id: Uint256):
  alloc_locals

  Minter_onlyMinter()

  let (rules_data_address) = rules_data_address_storage.read()

  let (artist_exists) = IRulesData.artistExists(rules_data_address, card.artist_name)
  assert_not_zero(artist_exists) # Unknown artist

  # Check is production is stopped for this scarcity and season
  let (stopped) = Scarcity_productionStopped(card.season, card.scarcity)
  assert stopped = FALSE # Production is stopped

  # Check if the serial_number is valid, given the scarcity supply
  let (supply) = Scarcity_supply(card.season, card.scarcity)
  let (is_supply_set) = is_not_zero(supply)

  if is_supply_set == TRUE:
    assert_le(card.serial_number, supply) # Invalid serial
    tempvar range_check_ptr = range_check_ptr
  else:
    tempvar range_check_ptr = range_check_ptr
  end

  # Check if card already exists
  let (local card_id) = get_card_id_from_card(card)

  let (exists) = cardExists(card_id)
  assert exists = FALSE # Card already exists

  cards_storage.write(card_id, card)

  return (card_id)
end

# Ownership

@external
func transferOwnership{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
  }(new_owner: felt) -> (new_owner: felt):
  Ownable_transfer_ownership(new_owner)
  return (new_owner)
end

@external
func renounceOwnership{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
  }():
  Ownable_transfer_ownership(0)
  return ()
end
