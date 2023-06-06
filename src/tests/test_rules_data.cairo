// locals
use rules_tokens::core::data::RulesData;
use rules_tokens::core::interface::CardModel;
use super::utils;
use super::utils::partial_eq::{ CardModelEq, ScarcityEq };

// dispatchers
use rules_tokens::core::data::{ RulesDataABIDispatcher, RulesDataABIDispatcherTrait };

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

fn setup() -> RulesDataABIDispatcher {
  let rules_data = setup_rules_data();

  rules_data.add_card_model(CARD_MODEL());

  rules_data
}

fn setup_rules_data() -> RulesDataABIDispatcher {
  let rules_data_address = utils::deploy(RulesData::TEST_CLASS_HASH, calldata: ArrayTrait::new());

  RulesDataABIDispatcher { contract_address: rules_data_address }
}

// Card model

#[test]
#[available_gas(20000000)]
fn test_get_card_model() {
  let rules_data = setup();

  assert(rules_data.card_model(CARD_MODEL_ID()) == CARD_MODEL(), 'Invalid card model');
}

#[test]
#[available_gas(20000000)]
fn test_add_card_model_returns_valid_id() {
  let rules_data = setup_rules_data();

  let card_model_id = rules_data.add_card_model(CARD_MODEL());

  assert(card_model_id == CARD_MODEL_ID(), 'Invalid card model id');
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Card model already exists', 'ENTRYPOINT_FAILED'))]
fn test_add_card_model_already_exists() {
  let rules_data = setup();

  rules_data.add_card_model(CARD_MODEL());
}

// Scarcity
