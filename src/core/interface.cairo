use traits::{ Into, TryInto };
use array::ArrayTrait;
use zeroable::Zeroable;
use option::OptionTrait;

use rules_tokens::utils::zeroable::U128Zeroable;
use rules_tokens::typed_data::voucher::Voucher;
use rules_tokens::utils::serde::SpanSerde;

const METADATA_MULTIHASH_IDENTIFIER: u16 = 0x1220;

// Metadata

#[derive(Serde, Copy, Drop)]
struct Metadata {
  multihash_identifier: u16,
  hash: u256,
}

// Scarcity

#[derive(Serde, Copy, Drop)]
struct Scarcity {
  max_supply: u128,
  name: felt252,
}

// Card model

#[derive(Serde, Copy, Drop)]
struct CardModel {
  artist_name: felt252,
  season: felt252,
  scarcity_id: felt252,
}

//
// Interfaces
//

#[abi]
trait IRulesTokens {
  fn voucher_signer() -> starknet::ContractAddress;

  fn redeem_voucher(voucher: Voucher, signature: Span<felt252>);
}

#[abi]
trait IRulesData {
  fn card_model(card_model_id: u128) -> CardModel;

  fn card_model_metadata(card_model_id: u128) -> Metadata;

  fn scarcity(season: felt252, scarcity_id: felt252) -> Scarcity;

  fn uncommon_scarcities_count(season: felt252) -> felt252;

  fn add_card_model(new_card_model: CardModel, metadata: Metadata) -> u128;

  fn add_scarcity(season: felt252, scarcity: Scarcity);
}
