%lang starknet
%builtins pedersen range_check

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from contracts.RulesPacks.library import (
  RulesPacks_pack_exists,
  RulesPacks_pack_card_model_quantity,
  RulesPacks_pack_max_supply,
  RulesPacks_pack,
  RulesPacks_rules_cards_address,

  RulesPacks_initializer,
  RulesPacks_create_pack,
)

from models.card import CardModel
from models.metadata import Metadata
from models.pack import PackCardModel

# AccessControl/Ownable

from lib.Ownable_base import (
  Ownable_get_owner,

  Ownable_initializer,
  Ownable_only_owner,
  Ownable_transfer_ownership
)

from lib.roles.AccessControl_base import (
  AccessControl_has_role,
  AccessControl_roles_count,
  AccessControl_role_member,

  AccessControl_initializer
)

from lib.roles.minter import (
  Minter_role,

  Minter_initializer,
  Minter_only_minter,
  Minter_grant,
  Minter_revoke
)

#
# Constructor
#

@constructor
func constructor{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(owner: felt, rules_cards_address: felt):
  Ownable_initializer(owner)
  AccessControl_initializer(owner)
  Minter_initializer(owner)
  RulesPacks_initializer(rules_cards_address)
  return ()
end

#
# Getters
#

@view
func packExists{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(pack_id: Uint256) -> (res: felt):
  let (res) = RulesPacks_pack_exists(pack_id)
  return (res)
end

@view
func getPackCardModelQuantity{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(pack_id: Uint256, card_model: CardModel) -> (quantity: felt):
  let (quantity) = RulesPacks_pack_card_model_quantity(pack_id, card_model)
  return (quantity)
end

@view
func getPackMaxSupply{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(pack_id: Uint256) -> (quantity: felt):
  let (max_supply) = RulesPacks_pack_max_supply(pack_id)
  return (max_supply)
end

@view
func getPack{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(pack_id: Uint256) -> (cards_per_pack: felt, metadata: Metadata):
  let (cards_per_pack, metadata) = RulesPacks_pack(pack_id)
  return (cards_per_pack, metadata)
end

# Other contracts

@view
func rulesCards{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }() -> (address: felt):
  let (address) = RulesPacks_rules_cards_address()
  return (address)
end

#
# Setters
#

@external
func createPack{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(
    cards_per_pack: felt,
    pack_card_models_len: felt,
    pack_card_models: PackCardModel*,
    metadata: Metadata
  ) -> (pack_id: Uint256):
  Minter_only_minter()
  let (pack_id) = RulesPacks_create_pack(cards_per_pack, pack_card_models_len, pack_card_models, metadata)
  return (pack_id)
end
