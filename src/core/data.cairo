use zeroable::Zeroable;
use traits::Into;

// locals
use rules_tokens::utils::zeroable::{ U128Zeroable, U256Zeroable };
use super::interface::{ Scarcity, CardModel, Metadata, METADATA_MULTIHASH_IDENTIFIER };

const COMMON_SCARCITY_MAX_SUPPLY: u128 = 0xffffffffffffffffffffffffffffffff;
const COMMON_SCARCITY_NAME: felt252 = 'Common';

#[abi]
trait RulesDataABI {
  #[view]
  fn card_model(card_model_id: u128) -> CardModel;

  #[view]
  fn card_model_metadata(card_model_id: u128) -> Metadata;

  #[view]
  fn scarcity(season: felt252, scarcity_id: felt252) -> Scarcity;

  #[view]
  fn uncommon_scarcities_count(season: felt252) -> felt252;

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
  use rules_tokens::utils::zeroable::{ CardModelZeroable, ScarcityZeroable };
  use super::super::interface::{ IRulesData };
  use rules_tokens::utils::storage::{ ScarcityStorageAccess, CardModelStorageAccess, MetadataStorageAccess };

  //
  // Storage
  //

  struct Storage {
    // season -> uncommon scarcities count
    _uncommon_scarcities_count: LegacyMap<felt252, felt252>,
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

    fn scarcity(season: felt252, scarcity_id: felt252) -> Scarcity {
      if (scarcity_id.is_zero()) {
        ScarcityTrait::common()
      } else {
        _scarcities::read((season, scarcity_id))
      }
    }

    fn uncommon_scarcities_count(season: felt252) -> felt252 {
      _uncommon_scarcities_count::read(season)
    }

    fn add_card_model(new_card_model: CardModel, metadata: Metadata) -> u128 {
      // assert card model and metadata are valid
      assert(new_card_model.is_valid(), 'Invalid card model');
      assert(metadata.is_valid(), 'Invalid metadata');

      // assert card model does not already exists
      let card_model_id = new_card_model.id();
      assert(card_model(:card_model_id).is_zero(), 'Card model already exists');

      // assert scarcity exists
      let scarcity_ = scarcity(season: new_card_model.season, scarcity_id: new_card_model.scarcity_id);
      assert(scarcity_.is_non_zero(), 'Scarcity does not exists');

      // save card model and metadata
      _card_models::write(card_model_id, new_card_model);
      _card_models_metadata::write(card_model_id, metadata);

      // return card model id
      card_model_id
    }

    fn add_scarcity(season: felt252, scarcity: Scarcity) {
      assert(scarcity.is_valid(), 'Invalid scarcity');

      // get new scarcities count
      let new_uncommon_scarcities_count = uncommon_scarcities_count(season) + 1;

      _uncommon_scarcities_count::write(season, new_uncommon_scarcities_count);
      _scarcities::write((season, new_uncommon_scarcities_count), scarcity);
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
  fn scarcity(season: felt252, scarcity_id: felt252) -> Scarcity {
    RulesData::scarcity(:season, :scarcity_id)
  }

  #[view]
  fn uncommon_scarcities_count(season: felt252) -> felt252 {
    RulesData::uncommon_scarcities_count(:season)
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

  fn common() -> Scarcity;
}

impl ScarcityImpl of ScarcityTrait {
  fn is_valid(self: Scarcity) -> bool {
    if (self.name.is_zero() | self.max_supply.is_zero()) {
      false
    } else {
      true
    }
  }

  fn common() -> Scarcity {
    Scarcity {
      max_supply: COMMON_SCARCITY_MAX_SUPPLY,
      name: COMMON_SCARCITY_NAME,
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
    hash = pedersen(hash, self.scarcity_id);
    hash = pedersen(hash, 3);

    Into::<felt252, u256>::into(hash).low
  }
}
