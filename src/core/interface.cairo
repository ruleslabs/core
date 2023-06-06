use traits::{ Into, TryInto };
use array::ArrayTrait;
use zeroable::Zeroable;
use option::OptionTrait;

use rules_tokens::utils::zeroable::U128Zeroable;
use rules_tokens::typed_data::voucher::Voucher;
use rules_tokens::utils::serde::SpanSerde;

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
  scarcity: felt252,
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

  fn scarcity(season: felt252, scarcity: felt252) -> Scarcity;

  fn add_card_model(new_card_model: CardModel) -> u128;

  fn add_scarcity(season: felt252, scarcity: Scarcity);
}
