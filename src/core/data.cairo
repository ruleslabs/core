#[contract]
mod RulesData {
  // locals
  use super::super::interface::{ Scarcity, CardModel, CardModelTrait, IRulesData };
  use rules_tokens::utils::storage::{ ScarcityStorageAccess, CardModelStorageAccess };

  //
  // Storage
  //

  struct Storage {
    // (season, scarcity_id) -> Scarcity
    _scarcities: LegacyMap<(felt252, felt252), Scarcity>,
    // card_model_id -> CardModel
    _card_models: LegacyMap<u128, CardModel>,
  }

  //
  // IRulesData
  //

  impl RulesData of IRulesData {
    fn card_model(card_model_id: u128) -> CardModel {
      _card_models::read(card_model_id)
    }

    fn add_card_model(card_model: CardModel) -> u128 {
      assert(card_model.is_valid(), 'Invalid card model');

      let mut card_model_id = card_model.id();
      assert(!card_model(:card_model_id).is_valid(), 'Card model already exists');

      _card_models::write(card_model_id, card_model);

      card_model_id
    }
  }

  //
  // Getters
  //

  #[view]
  fn card_model(card_model_id: u128) -> CardModel {
    RulesData::card_model(:card_model_id)
  }

  //
  // Setters
  //

  #[external]
  fn add_card_model(card_model: CardModel) -> u128 {
    RulesData::add_card_model(:card_model)
  }
}
