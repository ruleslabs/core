use zeroable::Zeroable;

// locals
use rules_tokens::core::data::{ RulesData, CardModelTrait, ScarcityTrait };
use rules_tokens::core::interface::{ CardModel, Scarcity, Metadata, METADATA_MULTIHASH_IDENTIFIER };
use rules_tokens::utils::partial_eq::{ CardModelEq, ScarcityEq };
use rules_tokens::utils::zeroable::{ CardModelZeroable, ScarcityZeroable };
use super::utils;
use super::utils::partial_eq::MetadataEq;
use super::utils::zeroable::MetadataZeroable;

// dispatchers
use rules_tokens::core::data::{ RulesDataABIDispatcher, RulesDataABIDispatcherTrait };

fn METADATA() -> Metadata {
  Metadata {
    multihash_identifier: METADATA_MULTIHASH_IDENTIFIER,
    hash: u256 {
      low: 'hash low',
      high: 'hash high',
    },
  }
}

fn CARD_MODEL() -> CardModel {
  CardModel {
    artist_name: 'King ju',
    season: 1,
    scarcity_id: 0,
  }
}

fn CARD_MODEL_ID() -> u128 {
  0x03096242471061f433ba6a63130aa948
}

fn COMMON_SCARCITY() -> Scarcity {
  ScarcityTrait::common()
}

fn SCARCITY() -> Scarcity {
  Scarcity {
    max_supply: 1,
    name: 'silver',
  }
}

fn SEASON() -> felt252 {
  'I\'ll be dead until this season'
}

fn setup() {
  RulesData::constructor();

  RulesData::add_card_model(CARD_MODEL(), METADATA());
}

// Card model

#[test]
#[available_gas(20000000)]
fn test_get_card_model() {
  setup();

  let card_model = CARD_MODEL();
  let card_model_id = CARD_MODEL_ID();

  assert(RulesData::card_model(:card_model_id) == card_model, 'Invalid card model');
}

#[test]
#[available_gas(20000000)]
fn test_get_card_model_metadata() {
  setup();

  let metadata = METADATA();
  let card_model_id = CARD_MODEL_ID();

  assert(RulesData::card_model_metadata(:card_model_id) == metadata, 'Invalid metadata');
}

#[test]
#[available_gas(20000000)]
fn test_add_card_model_returns_valid_id() {
  let card_model = CARD_MODEL();
  let metadata = METADATA();

  let card_model_id = RulesData::add_card_model(new_card_model: card_model, :metadata);

  assert(card_model_id == CARD_MODEL_ID(), 'Invalid card model id');
}

#[test]
#[available_gas(20000000)]
fn test_multiple_add_card_model() {
  setup();

  let metadata = METADATA();

  // add card model

  let mut card_model = CARD_MODEL();
  card_model.artist_name += 1;

  assert_state_before_add_card_model(:card_model);

  let card_model_id = RulesData::add_card_model(new_card_model: card_model, :metadata);

  assert_state_after_add_card_model(:card_model, :metadata);

  // add card model

  card_model = CARD_MODEL();
  card_model.season += 1;

  assert_state_before_add_card_model(:card_model);

  let card_model_id = RulesData::add_card_model(new_card_model: card_model, :metadata);

  assert_state_after_add_card_model(:card_model, :metadata);

  // add card model

  card_model = CARD_MODEL();
  card_model.scarcity_id += 1;
  RulesData::add_scarcity(season: card_model.season, scarcity: SCARCITY());

  assert_state_before_add_card_model(:card_model);

  let card_model_id = RulesData::add_card_model(new_card_model: card_model, :metadata);

  assert_state_after_add_card_model(:card_model, :metadata);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Card model already exists',))]
fn test_add_card_model_already_exists() {
  setup();

  let card_model = CARD_MODEL();
  let metadata = METADATA();

  RulesData::add_card_model(new_card_model: card_model, :metadata);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Invalid card model',))]
fn test_add_card_model_invalid_artist_name() {
  setup();

  let mut card_model = CARD_MODEL();
  let metadata = METADATA();

  card_model.artist_name = 0;

  RulesData::add_card_model(new_card_model: card_model, :metadata);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Invalid card model',))]
fn test_add_card_model_invalid_season() {
  setup();

  let mut card_model = CARD_MODEL();
  let metadata = METADATA();

  card_model.season = 0;

  RulesData::add_card_model(new_card_model: card_model, :metadata);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Scarcity does not exists',))]
fn test_add_card_model_invalid_scarcity() {
  setup();

  let mut card_model = CARD_MODEL();
  let metadata = METADATA();

  card_model.scarcity_id += 1;

  RulesData::add_card_model(new_card_model: card_model, :metadata);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Invalid metadata',))]
fn test_add_card_model_invalid_metadata_multihash_id() {
  setup();

  let card_model = CARD_MODEL();
  let mut metadata = METADATA();

  metadata.multihash_identifier += 1;

  RulesData::add_card_model(new_card_model: card_model, :metadata);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Invalid metadata',))]
fn test_add_card_model_invalid_metadata_hash() {
  setup();

  let card_model = CARD_MODEL();
  let mut metadata = METADATA();

  metadata.hash = 0;

  RulesData::add_card_model(new_card_model: card_model, :metadata);
}

// Scarcity

#[test]
#[available_gas(20000000)]
fn test_common_scarcity() {
  setup();

  assert(RulesData::scarcity(season: 0, scarcity_id: 0) == COMMON_SCARCITY(), 'Common scarcity');
  assert(
    RulesData::scarcity(season: 'in a long, long time', scarcity_id: 0) == COMMON_SCARCITY(),
    'Invalid common scarcity'
  );
}

#[test]
#[available_gas(20000000)]
fn test_uncommon_scarcity() {
  setup();

  let season = SEASON();
  RulesData::add_scarcity(:season, scarcity: SCARCITY());

  assert(RulesData::scarcity(:season, scarcity_id: 1) == SCARCITY(), 'Uncommon scarcity');
}

#[test]
#[available_gas(20000000)]
fn test_uncommon_scarcities_count() {
  setup();

  let season = SEASON();

  assert(RulesData::uncommon_scarcities_count(:season).is_zero(), 'Uncommon scarcities count');

  RulesData::add_scarcity(:season, scarcity: SCARCITY());

  assert(RulesData::uncommon_scarcities_count(:season) == 1, 'Uncommon scarcities count');

  // these tests are so boring, let me have some fun
  let mut i = 0;
  let how_much = 0x42;
  loop {
    if (i == how_much) {
      break ();
    }

    RulesData::add_scarcity(:season, scarcity: SCARCITY());
    i += 1;
  };

  // anyway, no one will ever read this text :|
  assert(RulesData::uncommon_scarcities_count(:season) == how_much + 1, 'Uncommon scarcities count');

  assert(RulesData::uncommon_scarcities_count(season: season + 1).is_zero(), 'Uncommon scarcities count');
}

#[test]
#[available_gas(20000000)]
fn test_add_scarcity() {
  setup();

  let mut season = SEASON();
  let mut scarcity = SCARCITY();

  // add scarcity

  assert_state_before_add_scarcity(:season);

  RulesData::add_scarcity(:season, :scarcity);

  assert_state_after_add_scarcity(:season, :scarcity);

  // add scarcity

  season += 0x42;

  assert_state_before_add_scarcity(:season);

  RulesData::add_scarcity(:season, :scarcity);

  assert_state_after_add_scarcity(:season, :scarcity);

  // add scarcity

  scarcity.name = 'incredibly rare';
  scarcity.max_supply = 1;

  assert_state_before_add_scarcity(:season);

  RulesData::add_scarcity(:season, :scarcity);

  assert_state_after_add_scarcity(:season, :scarcity);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Invalid scarcity',))]
fn test_add_scarcity_invalid_max_supply() {
  setup();

  let season = SEASON();
  let mut scarcity = SCARCITY();

  scarcity.max_supply = 0;

  RulesData::add_scarcity(:season, :scarcity);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Invalid scarcity',))]
fn test_add_scarcity_invalid_name() {
  setup();

  let season = SEASON();
  let mut scarcity = SCARCITY();

  scarcity.name = 0;

  RulesData::add_scarcity(:season, :scarcity);
}

//
// Utils
//

fn assert_state_before_add_card_model(card_model: CardModel) {
  let card_model_id = card_model.id();

  assert(RulesData::card_model(:card_model_id) == CardModelZeroable::zero(), 'card model after');
  assert(RulesData::card_model_metadata(:card_model_id) == MetadataZeroable::zero(), 'metadata after');
}

fn assert_state_after_add_card_model(card_model: CardModel, metadata: Metadata) {
  let card_model_id = card_model.id();

  assert(RulesData::card_model(:card_model_id) == card_model, 'card model after');
  assert(RulesData::card_model_metadata(:card_model_id) == metadata, 'metadata after');
}

fn assert_state_before_add_scarcity(season: felt252) {
  let scarcity_id = RulesData::uncommon_scarcities_count(:season);

  assert(RulesData::scarcity(:season, scarcity_id: scarcity_id + 1) == ScarcityZeroable::zero(), 'scarcity before');
}

fn assert_state_after_add_scarcity(season: felt252, scarcity: Scarcity) {
  let scarcity_id = RulesData::uncommon_scarcities_count(:season);

  assert(RulesData::scarcity(:season, scarcity_id: scarcity_id) == scarcity, 'scarcity after');
}
