%lang starknet

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import assert_le
from starkware.cairo.common.math_cmp import is_not_zero
from starkware.cairo.common.uint256 import Uint256

// Interfaces

from ruleslabs.interfaces.IRulesCards import IRulesCards

// Libraries

from ruleslabs.libraries.Scarcity import Scarcity
from periphery.proxy.library import Proxy

// Utils

from ruleslabs.utils.metadata import Metadata, _assert_metadata_are_valid
from ruleslabs.utils.card import (
  Card,
  _card_id_to_card,
  _card_to_card_id,
  _assert_card_well_formed
)

// Storage

@storage_var
func cards_metadata_storage(card_id: Uint256) -> (metadata: Metadata) {
}

// deprecated
@storage_var
func rules_cards_address_storage() -> (rules_cards_address: felt) {
}

namespace Cards {

  // Getters

  func card{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(
    card_id: Uint256
  ) -> (card: Card, metadata: Metadata) {
    let (card) = _card_id_to_card(card_id);
    let (metadata) = cards_metadata_storage.read(card_id);

    return (card, metadata);
  }

  func old_card{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(
    card_id: Uint256
  ) -> (card: Card, metadata: Metadata) {
    let (rules_cards_address) = rules_cards_address_storage.read();
    let (card, metadata) = IRulesCards.getCard(rules_cards_address, card_id);

    return (card, metadata);
  }

  func cardId{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    card: Card
  ) -> (card_id: Uint256) {
    let (card_id) = _card_to_card_id(card);
    return (card_id,);
  }

  func card_exists{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(card_id: Uint256) -> (res: felt) {
    let (metadata) = cards_metadata_storage.read(card_id);

    // check old cards aswell ):
    let (rules_cards_address) = rules_cards_address_storage.read();
    if (rules_cards_address == 0) {
      if (metadata.multihash_identifier == 0) {
        return (FALSE,);
      } else {
        return (TRUE,);
      }
    }

    let (old_card_exists) = IRulesCards.cardExists(rules_cards_address, card_id);

    if (metadata.multihash_identifier + old_card_exists == 0) {
      return (FALSE,);
    } else {
      return (TRUE,);
    }
  }

  // Business logic

  // IMPORTANT: there is not protection against double card creation
  func create_card{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    card: Card,
    metadata: Metadata
  ) -> (card_id: Uint256) {
    alloc_locals;

    _assert_metadata_are_valid(metadata);

    _assert_card_well_formed(card);

    // Check if the serial_number is valid, given the scarcity supply
    let (max_supply) = Scarcity.max_supply(card.season, card.scarcity);
    with_attr error_message("Cards: Invalid Serial") {
      assert_le(card.serial_number, max_supply);
    }

    // get card ID
    let (local card_id) = _card_to_card_id(card);

    // assert does not already exists
    let (exists) = card_exists(card_id);
    with_attr error_message("Cards: this card already exists") {
      assert exists = FALSE;
    }

    // get card id and save metadata
    cards_metadata_storage.write(card_id, metadata);

    return (card_id,);
  }

  func create_batch_of_cards{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    cards_len: felt,
    cards: Card*,
    metadata: Metadata*,
    card_ids: Uint256*
  ) {
    // loop condition
    if (cards_len == 0) {
      return ();
    }

    // create card
    let (card_id) = create_card([cards], [metadata]);
    assert [card_ids] = card_id;

    // iterate
    create_batch_of_cards(
      cards_len - 1,
      cards + Card.SIZE,
      metadata + Metadata.SIZE,
      card_ids + Uint256.SIZE
    );
    return ();
  }
}
