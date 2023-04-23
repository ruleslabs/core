%lang starknet

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.math import assert_not_zero

// Libraries

from periphery.proxy.library import Proxy
from ruleslabs.libraries.Cards import Cards
from ruleslabs.libraries.ERC1155.ERC1155 import ERC1155

// Utils

from ruleslabs.utils.memset import uint256_memset
from ruleslabs.utils.metadata import Metadata, _assert_metadata_are_valid
from ruleslabs.utils.card import Card, _assert_season_is_valid

// Constants

from ruleslabs.utils.card import SERIAL_NUMBER_MAX, SCARCITY_MIN

// Storage

@storage_var
func packs_supply_storage() -> (supply: felt) {
}

@storage_var
func packs_max_supply_storage(pack_id: Uint256) -> (max_supply: felt) {
}

@storage_var
func packs_metadata_storage(pack_id: Uint256) -> (metadata: Metadata) {
}

namespace Packs {

  func pack{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    pack_id: Uint256
  ) -> (max_supply: felt, metadata: Metadata) {
    let (metadata) = packs_metadata_storage.read(pack_id);
    let (max_supply) = packs_max_supply_storage.read(pack_id);

    return (max_supply, metadata);
  }

  func unlocked{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt,
    pack_id: Uint256
  ) -> (res: Uint256) {
    return (Uint256(0, 0),); // Not implemented yet
  }

  // Business logic

  func create_pack{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    max_supply: felt,
    metadata: Metadata,
  ) -> (pack_id: Uint256) {
    _assert_metadata_are_valid(metadata);

    with_attr error_message("Packs: pack max supply cannot be null") {
      assert_not_zero(max_supply);
    }

    // increase packs supply
    let (supply) = packs_supply_storage.read();
    packs_supply_storage.write(value=supply + 1);

    // return pack ID
    let pack_id = Uint256(supply + 1, 0);

    // store metadata and max supply
    packs_max_supply_storage.write(pack_id, max_supply);
    packs_metadata_storage.write(pack_id, metadata);

    return (pack_id,);
  }

  func create_common_pack{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    season: felt,
    metadata: Metadata
  ) -> (pack_id: Uint256) {
    _assert_metadata_are_valid(metadata);

    _assert_season_is_valid(season);

    // assert pack does not already exists
    let pack_id = Uint256(0, season);
    let (exists) = _pack_exists(pack_id);
    with_attr error_message("Packs: a common pack already exists for this season") {
      assert exists = FALSE;
    }

    // store metadata
    packs_metadata_storage.write(pack_id, metadata);

    return (pack_id,);
  }

  func open_pack_from{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _from: felt,
    pack_id: Uint256,
    cards_len: felt,
    cards: Card*,
    metadata_len: felt,
    metadata: Metadata*
  ) {
    alloc_locals;

    with_attr error_message("Packs: different cards_len and metadata_len") {
      assert cards_len = metadata_len;
    }

    // Create cards
    let (local card_ids: Uint256*) = alloc();
    Cards.create_batch_of_cards(cards_len, cards, metadata, card_ids);

    // Mint cards
    let (amounts: Uint256*) = alloc();
    uint256_memset(dst=amounts, value=Uint256(1, 0), n=cards_len);

    let data = cast(0, felt*);

    // Unsafe minting to avoid Reetrancy attack which could cancel the opening
    ERC1155.mint_batch(
      to=_from,
      ids_len=cards_len,
      ids=card_ids,
      amounts_len=cards_len,
      amounts=amounts,
      data_len=0,
      data=data,
    );

    // Burn openned pack
    ERC1155.burn(_from, pack_id, amount=Uint256(1, 0));
    return ();
  }

  // Internals

  func _pack_exists{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(pack_id: Uint256) -> (res: felt) {
    let (metadata) = packs_metadata_storage.read(pack_id);

    if (metadata.multihash_identifier == 0) {
      return (FALSE,);
    } else {
      return (TRUE,);
    }
  }
}
