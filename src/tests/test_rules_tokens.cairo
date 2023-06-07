use array::ArrayTrait;
use traits::{ Into, TryInto };
use option::OptionTrait;
use starknet::testing;
use zeroable::Zeroable;
use starknet::class_hash::Felt252TryIntoClassHash;
use debug::PrintTrait;

// locals
use rules_tokens::core::RulesTokens;
use rules_tokens::core::data::CardModelTrait;
use rules_tokens::core::tokens::TokenIdTrait;
use rules_tokens::typed_data::voucher::Voucher;
use rules_tokens::utils::zeroable::U256Zeroable;
use super::mocks::signer::Signer;
use super::mocks::receiver::Receiver;
use super::utils;
use super::constants::{
  URI,
  CHAIN_ID,
  VOUCHER_1,
  VOUCHER_2,
  VOUCHER_SIGNER,
  VOUCHER_SIGNATURE_1,
  VOUCHER_SIGNATURE_2,
  VOUCHER_SIGNER_PUBLIC_KEY,
  CARD_MODEL_2,
  METADATA,
  RECEIVER_DEPLOYED_ADDRESS,
  CARD_TOKEN_ID_2,
  SCARCITY,
  CARD_MODEL_3,
  OWNER,
  OTHER,
  ZERO,
  SEASON,
};

// dispatchers
use rules_account::account::{ AccountABIDispatcher, AccountABIDispatcherTrait };
use rules_tokens::core::{ RulesTokensABIDispatcher, RulesTokensABIDispatcherTrait };

fn setup() {
  // setup chain id to compute vouchers hashes
  testing::set_chain_id(CHAIN_ID());

  // setup voucher signer - 0x1
  let voucher_signer = setup_voucher_signer();

  testing::set_caller_address(OWNER());
  RulesTokens::constructor(
    uri_: URI().span(),
    voucher_signer_: voucher_signer.contract_address,
    marketplace_: starknet::contract_address_const::<'marketplace'>()
  );

  // create some card models and scarcities
  let card_model_2 = CARD_MODEL_2();
  let card_model_3 = CARD_MODEL_3();
  let metadata = METADATA();
  let scarcity = SCARCITY();

  RulesTokens::add_scarcity(season: card_model_3.season, :scarcity);
  RulesTokens::add_card_model(new_card_model: card_model_2, :metadata);
  RulesTokens::add_card_model(new_card_model: card_model_3, :metadata);
}

fn setup_voucher_signer() -> AccountABIDispatcher {
  let mut calldata = ArrayTrait::new();
  calldata.append(VOUCHER_SIGNER_PUBLIC_KEY());

  let signer_address = utils::deploy(Signer::TEST_CLASS_HASH, calldata);
  AccountABIDispatcher { contract_address: signer_address }
}

// Always run it after `setup()`
fn setup_receiver() -> AccountABIDispatcher {
  let receiver_address = utils::deploy(Receiver::TEST_CLASS_HASH, ArrayTrait::new());

  assert(receiver_address == RECEIVER_DEPLOYED_ADDRESS(), 'receiver setup failed');

  AccountABIDispatcher { contract_address: receiver_address }
}

#[test]
#[available_gas(20000000)]
fn test__verify_voucher_signature_valid() {
  setup();

  let voucher_signer = RulesTokens::voucher_signer();

  let voucher = VOUCHER_1();
  let signature = VOUCHER_SIGNATURE_1();

  assert(
    RulesTokens::_is_voucher_signature_valid(:voucher, :signature, signer: voucher_signer),
    'Invalid voucher signature'
  );
}

#[test]
#[available_gas(20000000)]
fn test__is_voucher_signature_valid_success() {
  setup();

  let voucher_signer = RulesTokens::voucher_signer();

  let mut voucher = VOUCHER_1();
  voucher.amount += 1;
  let signature = VOUCHER_SIGNATURE_1();

  assert(
    !RulesTokens::_is_voucher_signature_valid(:voucher, :signature, signer: voucher_signer),
    'Invalid voucher signature'
  );
}

#[test]
#[available_gas(20000000)]
fn test__is_voucher_signature_valid_failure() {
  setup();

  let voucher_signer = RulesTokens::voucher_signer();

  let mut voucher = VOUCHER_1();
  voucher.amount += 1;
  let signature = VOUCHER_SIGNATURE_1();

  assert(
    !RulesTokens::_is_voucher_signature_valid(:voucher, :signature, signer: voucher_signer),
    'Invalid voucher signature'
  );
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Invalid voucher signature',))]
fn test_redeem_voucher_invalid_signature() {
  setup();

  let mut voucher = VOUCHER_1();
  voucher.nonce += 1;
  let signature = VOUCHER_SIGNATURE_1();

  RulesTokens::redeem_voucher(:voucher, :signature);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Voucher already consumed',))]
fn test_redeem_voucher_already_consumed() {
  setup();
  let receiver = setup_receiver();

  let voucher = VOUCHER_2();
  let signature = VOUCHER_SIGNATURE_2();

  let card_model = CARD_MODEL_2();
  let metadata = METADATA();

  RulesTokens::redeem_voucher(:voucher, :signature);
  RulesTokens::redeem_voucher(:voucher, :signature);
}

// Card

#[test]
#[available_gas(20000000)]
fn test_balance_of_after_redeem_voucher() {
  setup();
  let receiver = setup_receiver();

  let voucher = VOUCHER_2();
  let signature = VOUCHER_SIGNATURE_2();

  // create conditions to successfully redeem the voucher
  let card_model = CARD_MODEL_2();
  let metadata = METADATA();
  let card_token_id = CARD_TOKEN_ID_2();

  assert(
    RulesTokens::balance_of(account: receiver.contract_address, id: card_token_id).is_zero(),
    'balance of before'
  );

  RulesTokens::redeem_voucher(:voucher, :signature);

  assert(
    RulesTokens::balance_of(account: receiver.contract_address, id: card_token_id) == voucher.amount,
    'balance of after'
  );
}

#[test]
#[available_gas(20000000)]
fn test_card_exists() {
  setup();
  let receiver = setup_receiver();

  let card_token_id = CARD_TOKEN_ID_2();

  assert(!RulesTokens::card_exists(:card_token_id), 'card exists before');

  RulesTokens::_mint(to: receiver.contract_address, token_id: TokenIdTrait::new(id: card_token_id), amount: 1);

  assert(RulesTokens::card_exists(:card_token_id), 'card exists after');
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Card already minted',))]
fn test__mint_card_already_minted() {
  setup();
  let receiver = setup_receiver();

  let card_token_id = CARD_TOKEN_ID_2();

  RulesTokens::_mint(to: receiver.contract_address, token_id: TokenIdTrait::new(id: card_token_id), amount: 1);
  RulesTokens::_mint(to: receiver.contract_address, token_id: TokenIdTrait::new(id: card_token_id), amount: 1);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Card model does not exists',))]
fn test__mint_card_unknown_card_model() {
  setup();
  let receiver = setup_receiver();

  let card_token_id = CARD_TOKEN_ID_2();

  RulesTokens::_mint(to: receiver.contract_address, token_id: TokenIdTrait::new(id: card_token_id + 1), amount: 1);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Serial number is out of range',))]
fn test__mint_card_out_of_range_serial_number() {
  setup();
  let receiver = setup_receiver();

  let scarcity = SCARCITY();
  let card_token_id = u256 { low: CARD_MODEL_3().id(), high: scarcity.max_supply + 1 };

  RulesTokens::_mint(to: receiver.contract_address, token_id: TokenIdTrait::new(id: card_token_id), amount: 1);
}

#[test]
#[available_gas(20000000)]
fn test__mint_card_in_range_serial_number() {
  setup();
  let receiver = setup_receiver();

  let scarcity = SCARCITY();
  let card_token_id = u256 { low: CARD_MODEL_3().id(), high: scarcity.max_supply };

  assert(!RulesTokens::card_exists(:card_token_id), 'card exists before');

  RulesTokens::_mint(to: receiver.contract_address, token_id: TokenIdTrait::new(id: card_token_id), amount: 1);

  assert(RulesTokens::card_exists(:card_token_id), 'card exists after');
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Card amount cannot exceed 1',))]
fn test__mint_card_invalid_amount() {
  setup();
  let receiver = setup_receiver();

  let card_token_id = CARD_TOKEN_ID_2();

  RulesTokens::_mint(to: receiver.contract_address, token_id: TokenIdTrait::new(id: card_token_id), amount: 2);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Packs tokens not supported yet',))]
fn test__mint_pack() {
  setup();
  let receiver = setup_receiver();

  let card_token_id = CARD_TOKEN_ID_2();
  let pack_token_id = u256 { low: card_token_id.low, high: 0 };

  RulesTokens::_mint(to: receiver.contract_address, token_id: TokenIdTrait::new(id: pack_token_id), amount: 2);
}

// Upgrade

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_upgrade_unauthorized() {
  setup();

  testing::set_caller_address(OTHER());
  RulesTokens::upgrade(new_implementation: 'new implementation'.try_into().unwrap());
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Caller is the zero address',))]
fn test_upgrade_from_zero() {
  setup();

  testing::set_caller_address(ZERO());
  RulesTokens::upgrade(new_implementation: 'new implementation'.try_into().unwrap());
}

// Add scarcity

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Caller is the zero address',))]
fn test_add_scarcity_from_zero() {
  setup();

  let season = SEASON();

  testing::set_caller_address(ZERO());
  RulesTokens::add_scarcity(:season, scarcity: SCARCITY());
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_add_scarcity_unauthorized() {
  setup();

  let season = SEASON();

  testing::set_caller_address(OTHER());
  RulesTokens::add_scarcity(:season, scarcity: SCARCITY());
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Caller is the zero address',))]
fn test_add_card_model_from_zero() {
  setup();

  let card_model_2 = CARD_MODEL_2();
  let metadata = METADATA();

  testing::set_caller_address(ZERO());
  RulesTokens::add_card_model(new_card_model: card_model_2, :metadata);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_add_card_model_unauthorized() {
  setup();

  let card_model_2 = CARD_MODEL_2();
  let metadata = METADATA();

  testing::set_caller_address(OTHER());
  RulesTokens::add_card_model(new_card_model: card_model_2, :metadata);
}
