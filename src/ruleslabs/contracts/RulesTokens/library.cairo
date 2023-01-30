%lang starknet

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_le, uint256_lt, uint256_add, uint256_sub
from starkware.cairo.common.math import assert_le, assert_not_zero, assert_not_equal
from starkware.starknet.common.syscalls import get_caller_address
from ruleslabs.lib.memset import uint256_memset

from ruleslabs.models.metadata import Metadata
from ruleslabs.models.card import Card

// Libraries

from ruleslabs.token.ERC1155.ERC1155_base import (
  ERC1155_balance_of,
  ERC1155_safe_mint,
  ERC1155_safe_mint_batch,
  ERC1155_mint_batch,
  ERC1155_burn,
  ERC1155_approve,
  ERC1155_safe_transfer_from,
  ERC1155_safe_batch_transfer_from,
)

from ruleslabs.token.ERC1155.ERC1155_Metadata_base import ERC1155_Metadata_token_uri

from ruleslabs.token.ERC1155.ERC1155_Supply_base import (
  ERC1155_Supply_exists,
  ERC1155_Supply_total_supply,
  ERC1155_Supply_before_token_transfer,
)

from periphery.proxy.library import Proxy

// Interfaces

from ruleslabs.contracts.RulesCards.IRulesCards import IRulesCards
from ruleslabs.contracts.RulesPacks.IRulesPacks import IRulesPacks

//
// Events
//

@event
func PackUnlocking(owner: felt, token_id: Uint256, amount: Uint256) {
}

//
// Storage
//

// Initialization

@storage_var
func contract_initialized() -> (initialized: felt) {
}

// Addresses

@storage_var
func rules_cards_address_storage() -> (rules_cards_address: felt) {
}

@storage_var
func rules_packs_address_storage() -> (rules_cards_address: felt) {
}

// Pack locking

@storage_var
func RulesTokens_packs_unlocking_amount(owner: felt, token_id: Uint256) -> (amount: Uint256) {
}

namespace RulesTokens {
  //
  // Initializer
  //

  func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _rules_cards_address: felt, _rules_packs_address: felt
  ) {
    // assert not already initialized
    let (initialized) = contract_initialized.read();
    with_attr error_message("RulesTokens: contract already initialized") {
      assert initialized = FALSE;
    }
    contract_initialized.write(TRUE);

    rules_cards_address_storage.write(_rules_cards_address);
    rules_packs_address_storage.write(_rules_packs_address);
    return ();
  }

  //
  // Getters
  //

  func token_uri{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: Uint256
  ) -> (token_uri_len: felt, token_uri: felt*) {
    let (exists) = ERC1155_Supply_exists(token_id);
    with_attr error_message("Token {token_id} does not exist.") {
      assert exists = TRUE;
    }

    let (token_uri_len, token_uri) = ERC1155_Metadata_token_uri(token_id);
    return (token_uri_len, token_uri);
  }

  func card{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    card_id: Uint256
  ) -> (card: Card, metadata: Metadata) {
    let (rules_cards_address) = rules_cards_address_storage.read();

    let (card, metadata) = IRulesCards.getCard(rules_cards_address, card_id);
    return (card, metadata);
  }

  // Other contracts

  func rules_cards{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    address: felt
  ) {
    let (address) = rules_cards_address_storage.read();
    return (address,);
  }

  func rules_packs{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    address: felt
  ) {
    let (address) = rules_packs_address_storage.read();
    return (address,);
  }

  func unlocked{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, token_id: Uint256
  ) -> (amount: Uint256) {
    let (amount) = RulesTokens_packs_unlocking_amount.read(owner, token_id);
    return (amount,);
  }

  //
  // Setters
  //

  func upgrade{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    implementation: felt
  ) {
    // make sure the target is not null
    with_attr error_message("RulesTokens: new implementation cannot be null") {
      assert_not_zero(implementation);
    }

    // change implementation
    Proxy.set_implementation(implementation);
    return ();
  }

  //
  // Business logic
  //

  func create_and_mint_card{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    card: Card, metadata: Metadata, to: felt
  ) -> (token_id: Uint256) {
    alloc_locals;

    let (rules_cards_address) = rules_cards_address_storage.read();
    let (local card_id) = IRulesCards.createCard(rules_cards_address, card, metadata, FALSE);

    let data = cast(0, felt*);
    _safe_mint(to, token_id=card_id, amount=Uint256(1, 0), data_len=0, data=data);

    return (token_id=card_id);
  }

  func mint_card{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    card_id: Uint256, to: felt
  ) -> (token_id: Uint256) {
    let (rules_cards_address) = rules_cards_address_storage.read();
    let (exists) = IRulesCards.cardExists(rules_cards_address, card_id);
    with_attr error_message("Card does not exist") {
      assert exists = TRUE;
    }

    let (exists) = ERC1155_Supply_exists(card_id);
    with_attr error_message("Token already minted") {
      assert exists = FALSE;
    }

    let data = cast(0, felt*);
    _safe_mint(to, token_id=card_id, amount=Uint256(1, 0), data_len=0, data=data);

    return (token_id=card_id);
  }

  func mint_pack{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    pack_id: Uint256, to: felt, amount: felt, unlocked: felt
  ) -> (token_id: Uint256) {
    alloc_locals;

    let (rules_packs_address) = rules_packs_address_storage.read();
    let (exists) = IRulesPacks.packExists(rules_packs_address, pack_id);
    with_attr error_message("Pack does not exist") {
      assert exists = TRUE;
    }

    let (local supply) = ERC1155_Supply_total_supply(pack_id);
    let (local max_supply) = IRulesPacks.getPackMaxSupply(rules_packs_address, pack_id);

    if (max_supply == 0) {
      // the pack is a common pack
      let (rules_cards_address) = rules_cards_address_storage.read();
      let (stopped) = IRulesCards.productionStoppedForSeasonAndScarcity(
        rules_cards_address, season=pack_id.high, scarcity=0
      );

      with_attr error_message(
          "RulesTokens: Production stopped for the common cards of this season") {
        assert stopped = FALSE;
      }

      tempvar syscall_ptr = syscall_ptr;
      tempvar pedersen_ptr = pedersen_ptr;
      tempvar range_check_ptr = range_check_ptr;
    } else {
      // the pack is a classic pack
      local felt_supply = supply.low;

      with_attr error_message(
          "RulesTokens: Can't mint {amount} packs, amount too high. supply: {felt_supply}, max supply: {max_supply}") {
        assert_le(amount + felt_supply, max_supply);
      }

      tempvar syscall_ptr = syscall_ptr;
      tempvar pedersen_ptr = pedersen_ptr;
      tempvar range_check_ptr = range_check_ptr;
    }

    let data = cast(0, felt*);
    _safe_mint(to, token_id=pack_id, amount=Uint256(amount, 0), data_len=0, data=data);

    // Anticipated opening approve
    if (unlocked == TRUE) {
      _inc_unlocked_packs(owner=to, token_id=pack_id, amount=Uint256(amount, 0));
      return (token_id=pack_id);
    } else {
      return (token_id=pack_id);
    }
  }

  // Opening

  func open_pack{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    to: felt,
    pack_id: Uint256,
    cards_len: felt,
    cards: Card*,
    metadata_len: felt,
    metadata: Metadata*,
  ) {
    alloc_locals;
    with_attr error_message("RulesTokens: cards count and metadata count doesn't match") {
      assert cards_len = metadata_len;
    }

    let (local caller) = get_caller_address();

    // Ensures 'owner' hold at least one pack
    let (balance) = ERC1155_balance_of(caller, pack_id);
    let (valid_amount) = uint256_le(Uint256(1, 0), balance);
    with_attr error_message("RulesTokens: caller does not own this pack") {
      assert valid_amount = TRUE;
    }

    // Check if card models are in the pack and `cards_len == cards_per_pack`
    let (rules_packs_address) = rules_packs_address_storage.read();
    let (cards_per_pack, _) = IRulesPacks.getPack(rules_packs_address, pack_id);

    with_attr error_message(
        "RulesTokens: wrong number of cards, expected {cards_per_pack} got {cards_len}") {
      assert cards_per_pack = cards_len;
    }
    _assert_cards_presence_in_pack(rules_packs_address, pack_id, cards_len, cards);

    // Create cards
    let (rules_cards_address) = rules_cards_address_storage.read();
    let (card_ids: Uint256*) = alloc();
    _create_cards_batch(rules_cards_address, cards_len, cards, metadata, card_ids);

    // Mint cards to receipent
    let (amounts: Uint256*) = alloc();
    uint256_memset(dst=amounts, value=Uint256(1, 0), n=cards_len);
    let data = cast(0, felt*);
    // Unsafe to avoid Reetrancy attack which could cancel the opening
    _mint_batch(
      to=to,
      ids_len=cards_len,
      ids=card_ids,
      amounts_len=cards_len,
      amounts=amounts,
      data_len=0,
      data=data,
    );

    // Burn openned pack
    ERC1155_burn(caller, pack_id, amount=Uint256(1, 0));
    return ();
  }

  // Transfers

  func safe_transfer_from{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _from: felt, to: felt, token_id: Uint256, amount: Uint256, data_len: felt, data: felt*
  ) {
    _unlocking_handler(_from, to, token_id, amount);
    ERC1155_safe_transfer_from(_from, to, token_id, amount, data_len, data);

    return ();
  }

  func safe_batch_transfer_from{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _from: felt,
    to: felt,
    ids_len: felt,
    ids: Uint256*,
    amounts_len: felt,
    amounts: Uint256*,
    data_len: felt,
    data: felt*,
  ) {
    _batch_unlocking_handler_loop(_from, to, ids_len, ids, amounts_len, amounts);
    ERC1155_safe_batch_transfer_from(_from, to, ids_len, ids, amounts_len, amounts, data_len, data);

    return ();
  }

  //
  // Internals
  //

  func _assert_cards_presence_in_pack{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
  }(rules_packs_address: felt, pack_id: Uint256, cards_len: felt, cards: Card*) {
    if (cards_len == 0) {
      return ();
    }

    let (quantity) = IRulesPacks.getPackCardModelQuantity(
      rules_packs_address, pack_id, [cards].model
    );
    with_attr error_message("RulesTokens: Card {cards_len} not mintable from pack") {
      assert_not_zero(quantity);
    }

    _assert_cards_presence_in_pack(
      rules_packs_address, pack_id, cards_len=cards_len - 1, cards=cards + Card.SIZE
    );
    return ();
  }

  func _safe_mint{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    to: felt, token_id: Uint256, amount: Uint256, data_len: felt, data: felt*
  ) {
    let (ids: Uint256*) = alloc();
    assert ids[0] = token_id;

    let (amounts: Uint256*) = alloc();
    assert amounts[0] = amount;

    ERC1155_Supply_before_token_transfer(_from=0, to=to, ids_len=1, ids=ids, amounts=amounts);

    ERC1155_safe_mint(to, token_id, amount, data_len, data);
    return ();
  }

  func _mint_batch{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    to: felt,
    ids_len: felt,
    ids: Uint256*,
    amounts_len: felt,
    amounts: Uint256*,
    data_len: felt,
    data: felt*,
  ) {
    ERC1155_Supply_before_token_transfer(
      _from=0, to=to, ids_len=ids_len, ids=ids, amounts=amounts
    );

    ERC1155_mint_batch(to, ids_len, ids, amounts_len, amounts, data_len, data);
    return ();
  }

  func _create_cards_batch{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    rules_cards_address: felt,
    cards_len: felt,
    cards: Card*,
    metadata: Metadata*,
    card_ids: Uint256*,
  ) {
    if (cards_len == 0) {
      return ();
    }

    let (card_id) = IRulesCards.createCard(rules_cards_address, [cards], [metadata], TRUE);
    assert [card_ids] = card_id;

    _create_cards_batch(
      rules_cards_address,
      cards_len - 1,
      cards + Card.SIZE,
      metadata + Metadata.SIZE,
      card_ids + Uint256.SIZE,
    );
    return ();
  }

  // Pack locking

  func _batch_unlocking_handler_loop{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _from: felt, to: felt, ids_len: felt, ids: Uint256*, amounts_len: felt, amounts: Uint256*
  ) {
    // loop stopping condition
    if (ids_len == 0) {
      return ();
    }

    _unlocking_handler(_from, to, [ids], [amounts]);

    _batch_unlocking_handler_loop(
      _from, to, ids_len - 1, ids + Uint256.SIZE, amounts_len - 1, amounts + Uint256.SIZE
    );
    return ();
  }

  func _unlocking_handler{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _from: felt, to: felt, token_id: Uint256, amount: Uint256
  ) {
    // if token_id.low * token_id.high === 0 => token is a pack
    // Check and update the amount of unlocked packs if needed
    if (token_id.low * token_id.high == 0) {
      let (unlocked_amount) = RulesTokens_packs_unlocking_amount.read(_from, token_id);

      with_attr error_message("RulesTokens: not enough unlocked packs") {
        let (unlocked_amount_too_low) = uint256_lt(unlocked_amount, amount);
        assert unlocked_amount_too_low = FALSE;
      }

      // Decrease unlocked amount
      let (new_unlocked_amount) = uint256_sub(unlocked_amount, amount);
      _unlock_packs(_from, token_id, new_unlocked_amount);

      // Increase unlocked packs amount for recipient
      _inc_unlocked_packs(to, token_id, amount);

      return ();
    } else {
      return ();
    }
  }

  func _unlock_packs{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, token_id: Uint256, amount: Uint256
  ) {
    RulesTokens_packs_unlocking_amount.write(owner, token_id, amount);
    PackUnlocking.emit(owner, token_id, amount);
    return ();
  }

  func _inc_unlocked_packs{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, token_id: Uint256, amount: Uint256
  ) {
    let (current_amount) = RulesTokens_packs_unlocking_amount.read(owner, token_id);
    let (new_amount: Uint256, _) = uint256_add(current_amount, amount);
    RulesTokens_packs_unlocking_amount.write(owner, token_id, new_amount);
    PackUnlocking.emit(owner, token_id, amount);
    return ();
  }
}
