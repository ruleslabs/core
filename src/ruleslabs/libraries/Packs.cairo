%lang starknet

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.math import assert_not_zero, assert_le

// Libraries

from periphery.proxy.library import Proxy
from ruleslabs.libraries.Cards import Cards
from ruleslabs.libraries.ERC1155.ERC1155 import ERC1155

// Utils

from ruleslabs.utils.memset import uint256_memset
from ruleslabs.utils.metadata import FeltMetadata, Metadata, _assert_metadata_are_valid
from ruleslabs.utils.card import Card, _assert_season_is_valid

// Constants

from ruleslabs.utils.card import SERIAL_NUMBER_MAX, SCARCITY_MIN
from ruleslabs.utils.metadata import MULTIHASH_ID

// Storage

@storage_var
func packs_supply_storage() -> (supply: felt) {
}

@storage_var
func packs_max_supply_storage(pack_id: Uint256) -> (max_supply: felt) {
}

@storage_var
func packs_available_supply_storage(pack_id: Uint256) -> (available_supply: felt) {
}

@storage_var
func packs_metadata_hash_storage(pack_id: Uint256) -> (metadata_hash: Uint256) {
}

@storage_var
func packs_unlocked_storage(owner: felt, pack_id: Uint256) -> (amount: felt) {
}

namespace Packs {

  // Getters

  func pack{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    pack_id: Uint256
  ) -> (max_supply: felt, metadata: Metadata) {
    let (metadata_hash) = packs_metadata_hash_storage.read(pack_id);
    let (max_supply) = packs_max_supply_storage.read(pack_id);

    return (max_supply, Metadata(metadata_hash, MULTIHASH_ID));
  }

  func unlocked{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt,
    pack_id: Uint256
  ) -> (amount: felt) {
    let (amount) = packs_unlocked_storage.read(owner, pack_id);
    return (amount,);
  }

  func pack_exists{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(pack_id: Uint256) -> (res: felt) {
    let (metadata_hash) = packs_metadata_hash_storage.read(pack_id);

    if (metadata_hash.low == 0) {
      return (FALSE,);
    } else {
      return (TRUE,);
    }
  }

  // Business logic

  func unlock{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt,
    pack_id: Uint256,
    amount: felt
  ) {
    let (unlocked_amount) = packs_unlocked_storage.read(owner, pack_id);
    packs_unlocked_storage.write(owner, pack_id, value=unlocked_amount + amount);

    return ();
  }

  func lock{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt,
    pack_id: Uint256,
    amount: felt
  ) {
    let (unlocked_amount) = packs_unlocked_storage.read(owner, pack_id);
    with_attr error_message("Packs: cannot lock more than unlocked amount") {
      assert_le(amount, unlocked_amount);
    }

    packs_unlocked_storage.write(owner, pack_id, value=unlocked_amount - amount);

    return ();
  }

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

    // store metadata
    packs_metadata_hash_storage.write(pack_id, metadata.hash);

    // store max supply
    packs_max_supply_storage.write(pack_id, max_supply);

    // store available supply
    packs_available_supply_storage.write(pack_id, max_supply);

    return (pack_id,);
  }

  func create_common_pack{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    season: felt,
    metadata: Metadata
  ) -> (pack_id: Uint256) {
    _assert_metadata_are_valid(metadata);

    _assert_season_is_valid(season);

    // get pack ID
    let pack_id = Uint256(0, season);

    // assert pack does not already exists
    with_attr error_message("Packs: a common pack already exists for this season") {
      let (exists) = pack_exists(pack_id);
      assert exists = FALSE;
    }

    // store metadata
    packs_metadata_hash_storage.write(pack_id, metadata.hash);

    return (pack_id,);
  }

  func open_pack_from{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _from: felt,
    pack_id: Uint256,
    cards_len: felt,
    cards: Card*,
    metadata_len: felt,
    metadata: FeltMetadata*
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

  func decrease_available_pack_supply{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    pack_id: Uint256,
    amount: felt
  ) {
    // just assert pack exists for common packs
    if (pack_id.low == 0) {
      with_attr error_message("Packs: pack does not exists") {
        let (exists) = pack_exists(pack_id);
        assert exists = TRUE;
      }
      return ();
    }

    let (available_supply) = packs_available_supply_storage.read(pack_id);

    // assert new available max supply is not too low
    with_attr error_message("Packs: available pack supply too low") {
      assert_le(amount, available_supply);
    }

    // update available supply
    packs_available_supply_storage.write(pack_id, value=available_supply - amount);

    return ();
  }
}
