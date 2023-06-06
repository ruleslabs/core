use zeroable::Zeroable;
use traits::Into;

// locals
use rules_tokens::utils::zeroable::{ U128Zeroable, U256Zeroable };
use super::interface::{ Scarcity, CardModel, Metadata, METADATA_MULTIHASH_IDENTIFIER };

#[abi]
trait RulesDataABI {
  #[view]
  fn card_model(card_model_id: u128) -> CardModel;

  #[view]
  fn card_model_metadata(card_model_id: u128) -> Metadata;

  #[view]
  fn scarcity(season: felt252, scarcity: felt252) -> Scarcity;

  #[external]
  fn add_card_model(new_card_model: CardModel, metadata: Metadata) -> u128;

  #[external]
  fn add_scarcity(season: felt252, scarcity: Scarcity);
}

#[contract]
mod RulesData {
  use zeroable::Zeroable;

  // locals
  use super::{ Scarcity, ScarcityTrait, CardModel, CardModelTrait, Metadata, MetadataTrait };
  use rules_tokens::utils::zeroable::CardModelZeroable;
  use super::super::interface::{ IRulesData };
  use rules_tokens::utils::storage::{ ScarcityStorageAccess, CardModelStorageAccess, MetadataStorageAccess };

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
    // card_model_id -> Metadata
    _card_models_metadata: LegacyMap<u128, Metadata>,
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

    fn card_model_metadata(card_model_id: u128) -> Metadata {
      _card_models_metadata::read(card_model_id)
    }

    fn scarcity(season: felt252, scarcity: felt252) -> Scarcity {
      _scarcities::read((season, scarcity))
    }

    fn add_card_model(new_card_model: CardModel, metadata: Metadata) -> u128 {
      // assert card model and metadata are valid
      assert(new_card_model.is_valid(), 'Invalid card model');
      assert(metadata.is_valid(), 'Invalid metadata');

      // assert card model does not already exists
      let card_model_id = new_card_model.id();
      assert(card_model(:card_model_id).is_zero(), 'Card model already exists');

      _card_models::write(card_model_id, new_card_model);

      // save metadata
      _card_models_metadata::write(card_model_id, metadata);

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
  fn card_model_metadata(card_model_id: u128) -> Metadata {
    RulesData::card_model_metadata(:card_model_id)
  }

  #[view]
  fn scarcity(season: felt252, scarcity: felt252) -> Scarcity {
    RulesData::scarcity(:season, :scarcity)
  }

  //
  // Setters
  //

  #[external]
  fn add_card_model(new_card_model: CardModel, metadata: Metadata) -> u128 {
    RulesData::add_card_model(:new_card_model, :metadata)
  }

  #[external]
  fn add_scarcity(season: felt252, scarcity: Scarcity) {
    RulesData::add_scarcity(:season, :scarcity)
  }
}

trait MetadataTrait {
  fn is_valid(self: Metadata) -> bool;
}

impl MetadataImpl of MetadataTrait {
  fn is_valid(self: Metadata) -> bool {
    if (self.multihash_identifier != METADATA_MULTIHASH_IDENTIFIER | self.hash.is_zero()) {
      false
    } else {
      true
    }
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
