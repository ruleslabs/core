// locals
use rules_tokens::core::data::{ RulesData, CardModelTrait };
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
    scarcity: 0,
  }
}

fn CARD_MODEL_ID() -> u128 {
  0x03096242471061f433ba6a63130aa948
}

fn SCARCITY() -> Scarcity {
  Scarcity {
    max_supply: 1,
    name: 'silver',
  }
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
  card_model.scarcity += 1;
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

//
// Utils
//

fn assert_state_before_add_card_model(card_model: CardModel) {
  let card_model_id = card_model.id();

  assert(RulesData::card_model(:card_model_id) == CardModelZeroable::zero(), 'Invalid card model');
  assert(RulesData::card_model_metadata(:card_model_id) == MetadataZeroable::zero(), 'Invalid metadata');
}

fn assert_state_after_add_card_model(card_model: CardModel, metadata: Metadata) {
  let card_model_id = card_model.id();

  assert(RulesData::card_model(:card_model_id) == card_model, 'Invalid card model');
  assert(RulesData::card_model_metadata(:card_model_id) == metadata, 'Invalid metadata');
}
