use zeroable::Zeroable;

// locals
use rules_tokens::core::data::{ RulesData, CardModelTrait, ScarcityTrait };
use rules_tokens::core::interface::{ IRulesData, CardModel, Pack, Scarcity, Metadata };
use rules_tokens::core::data::RulesData::{
  ContractState as RulesDataContractState,
  _packs_count::InternalContractMemberStateTrait as RulesData_packs_countInternalContractMemberStateTrait,
};

use rules_tokens::utils::partial_eq::{ CardModelEq, ScarcityEq, PackEq };
use rules_tokens::utils::zeroable::{ CardModelZeroable, ScarcityZeroable, PackZeroable };

use super::utils;
use super::utils::partial_eq::MetadataEq;
use super::utils::zeroable::MetadataZeroable;
use super::constants::{
  METADATA,
  METADATA_2,
  CARD_MODEL_1,
  CARD_MODEL_ID,
  COMMON_SCARCITY,
  SCARCITY,
  SEASON,
  INVALID_METADATA,
  PACK_1,
  PACK_ID_1,
};

// dispatchers
use rules_tokens::core::data::{ RulesDataABIDispatcher, RulesDataABIDispatcherTrait };

fn setup() -> RulesDataContractState {
  let mut rules_data = RulesData::unsafe_new_contract_state();

  rules_data.add_card_model(CARD_MODEL_1(), METADATA(), METADATA_2());

  rules_data.add_pack(PACK_1(), METADATA());

  rules_data
}

// Card model

#[test]
#[available_gas(20000000)]
fn test_card_model() {
  let mut rules_data = setup();

  let card_model = CARD_MODEL_1();
  let card_model_id = CARD_MODEL_ID();

  assert(rules_data.card_model(:card_model_id) == card_model, 'Invalid card model');
}

#[test]
#[available_gas(20000000)]
fn test_card_model_image_metadata() {
  let mut rules_data = setup();

  let image_metadata = METADATA();
  let card_model_id = CARD_MODEL_ID();

  assert(rules_data.card_model_image_metadata(:card_model_id) == image_metadata, 'Invalid metadata');
}

#[test]
#[available_gas(20000000)]
fn test_card_model_animation_metadata() {
  let mut rules_data = setup();

  let animation_metadata = METADATA_2();
  let card_model_id = CARD_MODEL_ID();

  assert(rules_data.card_model_animation_metadata(:card_model_id) == animation_metadata, 'Invalid metadata');
}

#[test]
#[available_gas(20000000)]
fn test_add_card_model_returns_valid_id() {
  let mut rules_data = RulesData::unsafe_new_contract_state();

  let card_model = CARD_MODEL_1();
  let image_metadata = METADATA();
  let animation_metadata = METADATA_2();

  let card_model_id = rules_data.add_card_model(new_card_model: card_model, :image_metadata, :animation_metadata);

  assert(card_model_id == CARD_MODEL_ID(), 'Invalid card model id');
}

#[test]
#[available_gas(20000000)]
fn test_multiple_add_card_model() {
  let mut rules_data = setup();

  let image_metadata = METADATA();
  let animation_metadata = METADATA_2();

  // add card model

  let mut card_model = CARD_MODEL_1();
  card_model.artist_name += 1;

  assert_state_before_add_card_model(ref :rules_data, :card_model);

  let card_model_id = rules_data.add_card_model(new_card_model: card_model, :image_metadata, :animation_metadata);

  assert_state_after_add_card_model(ref :rules_data, :card_model, :image_metadata, :animation_metadata);

  // add card model

  card_model = CARD_MODEL_1();
  card_model.season += 1;

  assert_state_before_add_card_model(ref :rules_data, :card_model);

  let card_model_id = rules_data.add_card_model(new_card_model: card_model, :image_metadata, :animation_metadata);

  assert_state_after_add_card_model(ref :rules_data, :card_model, :image_metadata, :animation_metadata);

  // add card model

  card_model = CARD_MODEL_1();
  card_model.scarcity_id += 1;
  rules_data.add_scarcity(season: card_model.season, scarcity: SCARCITY());

  assert_state_before_add_card_model(ref :rules_data, :card_model);

  let card_model_id = rules_data.add_card_model(new_card_model: card_model, :image_metadata, :animation_metadata);

  assert_state_after_add_card_model(ref :rules_data, :card_model, :image_metadata, :animation_metadata);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Card model already exists',))]
fn test_add_card_model_already_exists() {
  let mut rules_data = setup();

  let card_model = CARD_MODEL_1();
  let image_metadata = METADATA();
  let animation_metadata = METADATA_2();

  rules_data.add_card_model(new_card_model: card_model, :image_metadata, :animation_metadata);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Invalid card model',))]
fn test_add_card_model_invalid_artist_name() {
  let mut rules_data = setup();

  let mut card_model = CARD_MODEL_1();
  let image_metadata = METADATA();
  let animation_metadata = METADATA_2();

  card_model.artist_name = 0;

  rules_data.add_card_model(new_card_model: card_model, :image_metadata, :animation_metadata);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Invalid card model',))]
fn test_add_card_model_invalid_season() {
  let mut rules_data = setup();

  let mut card_model = CARD_MODEL_1();
  let image_metadata = METADATA();
  let animation_metadata = METADATA_2();

  card_model.season = 0;

  rules_data.add_card_model(new_card_model: card_model, :image_metadata, :animation_metadata);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Scarcity does not exists',))]
fn test_add_card_model_invalid_scarcity() {
  let mut rules_data = setup();

  let mut card_model = CARD_MODEL_1();
  let image_metadata = METADATA();
  let animation_metadata = METADATA_2();

  card_model.scarcity_id += 1;

  rules_data.add_card_model(new_card_model: card_model, :image_metadata, :animation_metadata);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Invalid image metadata',))]
fn test_add_card_model_invalid_image_metadata() {
  let mut rules_data = setup();

  let card_model = CARD_MODEL_1();
  let image_metadata = INVALID_METADATA();
  let animation_metadata = METADATA();

  rules_data.add_card_model(new_card_model: card_model, :image_metadata, :animation_metadata);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Invalid animation metadata',))]
fn test_add_card_model_invalid_animation_metadata() {
  let mut rules_data = setup();

  let card_model = CARD_MODEL_1();
  let image_metadata = METADATA();
  let animation_metadata = INVALID_METADATA();

  rules_data.add_card_model(new_card_model: card_model, :image_metadata, :animation_metadata);
}

// Scarcity

#[test]
#[available_gas(20000000)]
fn test_common_scarcity() {
  let mut rules_data = setup();

  assert(rules_data.scarcity(season: 0, scarcity_id: 0) == COMMON_SCARCITY(), 'Common scarcity');
  assert(
    rules_data.scarcity(season: 'in a long, long time', scarcity_id: 0) == COMMON_SCARCITY(),
    'Invalid common scarcity'
  );
}

#[test]
#[available_gas(20000000)]
fn test_uncommon_scarcity() {
  let mut rules_data = setup();

  let season = SEASON();
  rules_data.add_scarcity(:season, scarcity: SCARCITY());

  assert(rules_data.scarcity(:season, scarcity_id: 1) == SCARCITY(), 'Uncommon scarcity');
}

#[test]
#[available_gas(20000000)]
fn test_uncommon_scarcities_count() {
  let mut rules_data = setup();

  let season = SEASON();

  assert(rules_data.uncommon_scarcities_count(:season).is_zero(), 'Uncommon scarcities count');

  rules_data.add_scarcity(:season, scarcity: SCARCITY());

  assert(rules_data.uncommon_scarcities_count(:season) == 1, 'Uncommon scarcities count');

  // these tests are so boring, let me have some fun
  let mut i = 0;
  let how_much = 0x42;
  loop {
    if (i == how_much) {
      break ();
    }

    rules_data.add_scarcity(:season, scarcity: SCARCITY());
    i += 1;
  };

  // anyway, no one will ever read this text :|
  assert(rules_data.uncommon_scarcities_count(:season) == how_much + 1, 'Uncommon scarcities count');

  assert(rules_data.uncommon_scarcities_count(season: season + 1).is_zero(), 'Uncommon scarcities count');
}

#[test]
#[available_gas(20000000)]
fn test_add_scarcity() {
  let mut rules_data = setup();

  let mut season = SEASON();
  let mut scarcity = SCARCITY();

  // add scarcity

  assert_state_before_add_scarcity(ref :rules_data, :season);

  rules_data.add_scarcity(:season, :scarcity);

  assert_state_after_add_scarcity(ref :rules_data, :season, :scarcity);

  // add scarcity

  season += 0x42;

  assert_state_before_add_scarcity(ref :rules_data, :season);

  rules_data.add_scarcity(:season, :scarcity);

  assert_state_after_add_scarcity(ref :rules_data, :season, :scarcity);

  // add scarcity

  scarcity.name = 'incredibly rare';
  scarcity.max_supply = 1;

  assert_state_before_add_scarcity(ref :rules_data, :season);

  rules_data.add_scarcity(:season, :scarcity);

  assert_state_after_add_scarcity(ref :rules_data, :season, :scarcity);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Invalid scarcity',))]
fn test_add_scarcity_invalid_max_supply() {
  let mut rules_data = setup();

  let season = SEASON();
  let mut scarcity = SCARCITY();

  scarcity.max_supply = 0;

  rules_data.add_scarcity(:season, :scarcity);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Invalid scarcity',))]
fn test_add_scarcity_invalid_name() {
  let mut rules_data = setup();

  let season = SEASON();
  let mut scarcity = SCARCITY();

  scarcity.name = 0;

  rules_data.add_scarcity(:season, :scarcity);
}

// Pack

#[test]
#[available_gas(20000000)]
fn test_pack() {
  let mut rules_data = setup();

  let pack = PACK_1();
  let pack_id = PACK_ID_1();

  assert(rules_data.pack(:pack_id) == pack, 'Invalid pack');
}

#[test]
#[available_gas(20000000)]
fn test_pack_metadata() {
  let mut rules_data = setup();

  let image_metadata = METADATA();
  let pack_id = PACK_ID_1();

  assert(rules_data.pack_image_metadata(:pack_id) == image_metadata, 'Invalid metadata');
}

#[test]
#[available_gas(20000000)]
fn test_add_pack_returns_valid_id() {
  let mut rules_data = RulesData::unsafe_new_contract_state();

  let pack = PACK_1();
  let image_metadata = METADATA();

  let pack_id = rules_data.add_pack(new_pack: pack, :image_metadata);

  assert(pack_id == PACK_ID_1(), 'Invalid pack id');
}

#[test]
#[available_gas(20000000)]
fn test_multiple_add_pack() {
  let mut rules_data = setup();

  let image_metadata = METADATA();

  // add pack

  let mut pack = PACK_1();
  pack.name += 1;

  assert_state_before_add_pack(ref :rules_data);

  let card_model_id = rules_data.add_pack(new_pack: pack, :image_metadata);

  assert_state_after_add_pack(ref :rules_data, :pack, :image_metadata);

  // add pack

  pack.season += 100;

  assert_state_before_add_pack(ref :rules_data);

  let card_model_id = rules_data.add_pack(new_pack: pack, :image_metadata);

  assert_state_after_add_pack(ref :rules_data, :pack, :image_metadata);

  // add pack

  pack.name += '100';

  assert_state_before_add_pack(ref :rules_data);

  let card_model_id = rules_data.add_pack(new_pack: pack, :image_metadata);

  assert_state_after_add_pack(ref :rules_data, :pack, :image_metadata);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Invalid pack',))]
fn test_add_pack_invalid_name() {
  let mut rules_data = RulesData::unsafe_new_contract_state();

  let mut pack = PACK_1();
  let image_metadata = METADATA();

  pack.name = 0;

  let card_model_id = rules_data.add_pack(new_pack: pack, :image_metadata);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Invalid pack',))]
fn test_add_pack_invalid_season() {
  let mut rules_data = RulesData::unsafe_new_contract_state();

  let mut pack = PACK_1();
  let image_metadata = METADATA();

  pack.season = 0;

  let card_model_id = rules_data.add_pack(new_pack: pack, :image_metadata);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Invalid image metadata',))]
fn test_add_pack_invalid_image_metadata() {
  let mut rules_data = setup();

  let pack = PACK_1();
  let image_metadata = INVALID_METADATA();

  rules_data.add_pack(new_pack: pack, :image_metadata);
}

// Set metadata

#[test]
#[available_gas(20000000)]
fn test_set_card_model_metadata() {
  let mut rules_data = setup();

  let card_model = CARD_MODEL_1();
  let card_model_id = card_model.id();
  let image_metadata = METADATA_2();
  let animation_metadata = METADATA();

  rules_data.set_card_model_metadata(:card_model_id, :image_metadata, :animation_metadata);

  assert_state_after_add_card_model(ref :rules_data, :card_model, :image_metadata, :animation_metadata);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Card model does not exists',))]
fn test_set_card_model_metadata_does_not_exists() {
  let mut rules_data = setup();

  let card_model = CARD_MODEL_1();
  let card_model_id = card_model.id() + 1;
  let image_metadata = METADATA_2();
  let animation_metadata = METADATA();

  rules_data.set_card_model_metadata(:card_model_id, :image_metadata, :animation_metadata);
}

#[test]
#[available_gas(20000000)]
fn test_set_pack_metadata() {
  let mut rules_data = setup();

  let pack_id = PACK_ID_1();
  let image_metadata = METADATA_2();

  rules_data.set_pack_metadata(:pack_id, :image_metadata);
}

//
// Utils
//

// Card model

fn assert_state_before_add_card_model(ref rules_data: RulesDataContractState, card_model: CardModel) {
  let card_model_id = card_model.id();

  assert(rules_data.card_model(:card_model_id) == CardModelZeroable::zero(), 'card model before');
  assert(rules_data.card_model_image_metadata(:card_model_id) == MetadataZeroable::zero(), 'image metadata before');
  assert(
    rules_data.card_model_animation_metadata(:card_model_id) == MetadataZeroable::zero(),
    'animation metadata before'
  );
}

fn assert_state_after_add_card_model(
  ref rules_data: RulesDataContractState,
  card_model: CardModel,
  image_metadata: Metadata,
  animation_metadata: Metadata
) {
  let card_model_id = card_model.id();

  assert(rules_data.card_model(:card_model_id) == card_model, 'card model after');
  assert(rules_data.card_model_image_metadata(:card_model_id) == image_metadata, 'image metadata after');
  assert(rules_data.card_model_animation_metadata(:card_model_id) == animation_metadata, 'animation metadata after');
}

// Scarcity

fn assert_state_before_add_scarcity(ref rules_data: RulesDataContractState, season: felt252) {
  let scarcity_id = rules_data.uncommon_scarcities_count(:season);

  assert(rules_data.scarcity(:season, scarcity_id: scarcity_id + 1) == ScarcityZeroable::zero(), 'scarcity before');
}

fn assert_state_after_add_scarcity(ref rules_data: RulesDataContractState, season: felt252, scarcity: Scarcity) {
  let scarcity_id = rules_data.uncommon_scarcities_count(:season);

  assert(rules_data.scarcity(:season, scarcity_id: scarcity_id) == scarcity, 'scarcity after');
}

// Pack

fn assert_state_before_add_pack(ref rules_data: RulesDataContractState) {
  let pack_id = rules_data._packs_count.read() + 1;

  assert(rules_data.pack(:pack_id) == PackZeroable::zero(), 'pack before');
  assert(rules_data.pack_image_metadata(:pack_id) == MetadataZeroable::zero(), 'image_metadata before');
}

fn assert_state_after_add_pack(ref rules_data: RulesDataContractState, pack: Pack, image_metadata: Metadata) {
  let pack_id = rules_data._packs_count.read();

  assert(rules_data.pack(:pack_id) == pack, 'pack after');
  assert(rules_data.pack_image_metadata(:pack_id) == image_metadata, 'metadata after');
}
