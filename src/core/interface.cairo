use array::ArrayTrait;
use zeroable::Zeroable;

use rules_tokens::typed_data::voucher::Voucher;
use rules_tokens::utils::serde::SpanSerde;

#[derive(Serde, Drop)]
struct Scarcity {
  max_supply: u128,
  name: felt252,
}

// Card model

#[derive(Serde, Copy, Drop)]
struct CardModel {
  artist_name: felt252,
  scarcity: felt252,
  season: felt252,
}

trait CardModelTrait {
  fn is_valid(self: CardModel) -> bool;
  fn id(self: CardModel) -> u128;
}

impl CardModelImpl of CardModelTrait {
  fn is_valid(self: CardModel) -> bool {
    if (self.artist_name.is_zero() | self.season.is_zero()) {
      false
    } else {
      true
    }
  }

  fn id(self: CardModel) -> u128 {
    1_u128
  }
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

  fn add_card_model(card_model: CardModel) -> u128;
}
