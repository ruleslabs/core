use zeroable::Zeroable;
use traits::Into;

// locals
use rules_tokens::utils::zeroable::U128Zeroable;
use super::interface::{ Scarcity, CardModel };

#[abi]
trait RulesDataABI {
  #[view]
  fn card_model(card_model_id: u128) -> CardModel;

  #[view]
  fn scarcity(season: felt252, scarcity: felt252) -> Scarcity;

  #[external]
  fn add_card_model(new_card_model: CardModel) -> u128;

  #[external]
  fn add_scarcity(season: felt252, scarcity: Scarcity);
}

#[contract]
mod RulesData {
  // locals
  use super::{ Scarcity, ScarcityTrait, CardModel, CardModelTrait };
  use super::super::interface::{ IRulesData };
  use rules_tokens::utils::storage::{ ScarcityStorageAccess, CardModelStorageAccess };

  //
  // Storage
  //

  struct Storage {
    // season -> scarcity count
    _scarcities_count: LegacyMap<felt252, felt252>,
    // (season, scarcity_id) -> Scarcity
    _scarcities: LegacyMap<(felt252, felt252), Scarcity>,
    // card_model_id -> CardModel
    _card_models: LegacyMap<u128, CardModel>,
  }

  //
  // Constructor
  //

  #[constructor]
  fn constructor() {}

  //
  // IRulesData impl
  //

  impl RulesData of IRulesData {
    fn card_model(card_model_id: u128) -> CardModel {
      _card_models::read(card_model_id)
    }

    fn scarcity(season: felt252, scarcity: felt252) -> Scarcity {
      _scarcities::read((season, scarcity))
    }

    fn add_card_model(new_card_model: CardModel) -> u128 {
      assert(new_card_model.is_valid(), 'Invalid card model');

      let card_model_id = new_card_model.id();
      assert(!card_model(:card_model_id).is_valid(), 'Card model already exists');

      _card_models::write(card_model_id, new_card_model);

      card_model_id
    }

    fn add_scarcity(season: felt252, scarcity: Scarcity) {
      assert(scarcity.is_valid(), 'Invalid scarcity');

      // get new scarcities count
      let scarcities_count_ = _scarcities_count::read(season);
      let new_scarcities_count_ = scarcities_count_ + 1;

      _scarcities_count::write(season, new_scarcities_count_);
      _scarcities::write((season, new_scarcities_count_), scarcity);
    }
  }

  //
  // Getters
  //

  #[view]
  fn card_model(card_model_id: u128) -> CardModel {
    RulesData::card_model(:card_model_id)
  }

  #[view]
  fn scarcity(season: felt252, scarcity: felt252) -> Scarcity {
    RulesData::scarcity(:season, :scarcity)
  }

  //
  // Setters
  //

  #[external]
  fn add_card_model(new_card_model: CardModel) -> u128 {
    RulesData::add_card_model(:new_card_model)
  }

  #[external]
  fn add_scarcity(season: felt252, scarcity: Scarcity) {
    RulesData::add_scarcity(:season, :scarcity)
  }
}

trait ScarcityTrait {
  fn is_valid(self: Scarcity) -> bool;
}

impl ScarcityImpl of ScarcityTrait {
  fn is_valid(self: Scarcity) -> bool {
    if (self.name.is_zero() | self.max_supply.is_zero()) {
      false
    } else {
      true
    }
  }
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
    let mut hash = pedersen(0, self.artist_name);
    hash = pedersen(hash, self.season);
    hash = pedersen(hash, self.scarcity);
    hash = pedersen(hash, 3);

    Into::<felt252, u256>::into(hash).low
  }
}
