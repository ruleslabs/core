use array::ArrayTrait;
use traits::{ Into, TryInto };
use option::OptionTrait;
use starknet::testing;
use zeroable::Zeroable;
use starknet::class_hash::Felt252TryIntoClassHash;
use rules_erc1155::erc1155::interface::IERC1155_ID;

// locals
use rules_tokens::royalties::erc2981::IERC2981_ID;
use rules_tokens::core::RulesTokens;
use rules_tokens::core::data::CardModelTrait;
use rules_tokens::core::tokens::TokenIdTrait;
use rules_tokens::core::voucher::Voucher;
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
  OTHER_RECEIVER_DEPLOYED_ADDRESS,
  CARD_TOKEN_ID_2,
  SCARCITY,
  CARD_MODEL_3,
  OWNER,
  OTHER,
  ZERO,
  SEASON,
  MARKETPLACE,
  ROYALTIES_RECEIVER,
  ROYALTIES_PERCENTAGE
};

// dispatchers
use rules_account::account::{ AccountABIDispatcher, AccountABIDispatcherTrait };
use rules_tokens::core::{ RulesTokensABIDispatcher, RulesTokensABIDispatcherTrait };

fn setup() {
  // setup chain id to compute vouchers hashes
  testing::set_chain_id(CHAIN_ID());

  // setup voucher signer - 0x1
  let voucher_signer = setup_voucher_signer();

  RulesTokens::constructor(
    uri_: URI().span(),
    owner_: OWNER(),
    voucher_signer_: voucher_signer.contract_address,
    marketplace_: MARKETPLACE(),
    royalties_receiver_: ROYALTIES_RECEIVER(),
    royalties_percentage_: ROYALTIES_PERCENTAGE()
  );

  // create some card models and scarcities
  let card_model_2 = CARD_MODEL_2();
  let card_model_3 = CARD_MODEL_3();
  let metadata = METADATA();
  let scarcity = SCARCITY();

  testing::set_caller_address(OWNER());
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

fn setup_other_receiver() -> AccountABIDispatcher {
  let receiver_address = utils::deploy(Receiver::TEST_CLASS_HASH, ArrayTrait::new());

  assert(receiver_address == OTHER_RECEIVER_DEPLOYED_ADDRESS(), 'receiver setup failed');

  AccountABIDispatcher { contract_address: receiver_address }
}

//
// TESTS
//

#[test]
#[available_gas(20000000)]
fn test_supports_interface() {
  setup();

  assert(RulesTokens::supports_interface(interface_id: IERC1155_ID), 'Does not support IERC1155');
  assert(RulesTokens::supports_interface(interface_id: IERC2981_ID), 'Does not support IERC2981');
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Invalid voucher signature',))]
fn test_redeem_voucher_invalid_signature() {
  setup();

  let mut voucher = VOUCHER_1();
  voucher.salt += 1;
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

// Marketplace

#[test]
#[available_gas(20000000)]
fn test_marketplace() {
  setup();

  let marketplace = MARKETPLACE();

  assert(RulesTokens::marketplace() == marketplace, 'Invalid marketplace address');
}

#[test]
#[available_gas(20000000)]
fn test_set_marketplace() {
  setup();

  let marketplace = MARKETPLACE();
  let new_marketplace = OTHER();

  assert(RulesTokens::marketplace() == marketplace, 'Invalid marketplace address');

  RulesTokens::set_marketplace(marketplace_: new_marketplace);

  assert(RulesTokens::marketplace() == new_marketplace, 'Invalid marketplace address');
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Caller is the zero address',))]
fn test_set_marketplace_from_zero() {
  setup();

  let marketplace = MARKETPLACE();
  let new_marketplace = OTHER();

  testing::set_caller_address(ZERO());
  RulesTokens::set_marketplace(marketplace_: new_marketplace);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_set_marketplace_unauthorized() {
  setup();

  let marketplace = MARKETPLACE();
  let new_marketplace = OTHER();

  testing::set_caller_address(OTHER());
  RulesTokens::set_marketplace(marketplace_: new_marketplace);
}

// Reedem voucher to

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Caller is not the marketplace',))]
fn test_redeem_voucher_to_unauthorized() {
  setup();
  let receiver = setup_receiver();

  let voucher = VOUCHER_2();
  let signature = VOUCHER_SIGNATURE_2();

  let card_model = CARD_MODEL_2();
  let metadata = METADATA();

  testing::set_caller_address(OWNER());
  RulesTokens::redeem_voucher_to(to: OTHER(), :voucher, :signature);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Caller is the zero address',))]
fn test_redeem_voucher_to_from_zero() {
  setup();
  let receiver = setup_receiver();

  let voucher = VOUCHER_2();
  let signature = VOUCHER_SIGNATURE_2();

  let card_model = CARD_MODEL_2();
  let metadata = METADATA();

  testing::set_caller_address(ZERO());
  RulesTokens::redeem_voucher_to(to: OTHER(), :voucher, :signature);
}

#[test]
#[available_gas(20000000)]
fn test_balance_of_after_redeem_voucher_to_() {
  setup();
  setup_receiver();

  let receiver = setup_other_receiver();

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

  testing::set_caller_address(MARKETPLACE());
  RulesTokens::redeem_voucher_to(to: receiver.contract_address, :voucher, :signature);

  assert(
    RulesTokens::balance_of(account: receiver.contract_address, id: card_token_id) == voucher.amount,
    'balance of after'
  );
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Invalid voucher signature',))]
fn test_redeem_voucher_to_invalid_signature() {
  setup();
  let receiver = setup_receiver();

  let mut voucher = VOUCHER_2();
  voucher.salt += 1;
  let signature = VOUCHER_SIGNATURE_2();

  let card_model = CARD_MODEL_2();
  let metadata = METADATA();

  testing::set_caller_address(MARKETPLACE());
  RulesTokens::redeem_voucher_to(to: OTHER(), :voucher, :signature);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Voucher already consumed',))]
fn test_redeem_voucher_to_already_consumed() {
  setup();
  setup_receiver();

  let receiver = setup_other_receiver();

  let voucher = VOUCHER_2();
  let signature = VOUCHER_SIGNATURE_2();

  let card_model = CARD_MODEL_2();
  let metadata = METADATA();

  testing::set_caller_address(MARKETPLACE());
  RulesTokens::redeem_voucher_to(to: receiver.contract_address, :voucher, :signature);
  RulesTokens::redeem_voucher_to(to: receiver.contract_address, :voucher, :signature);
}

// ERC2981 - Royalties

#[test]
#[available_gas(20000000)]
fn test_royalty_info_amount_without_reminder() {
  setup();

  let (_, royalty_amount) = RulesTokens::royalty_info(token_id: 0, sale_price: 100);
  assert(royalty_amount == 5, 'Invalid royalty amount');

  let (_, royalty_amount) = RulesTokens::royalty_info(token_id: 0, sale_price: 20);
  assert(royalty_amount == 1, 'Invalid royalty amount');

  let (_, royalty_amount) = RulesTokens::royalty_info(token_id: 0, sale_price: 0xfffffff0);
  assert(royalty_amount == 0xccccccc, 'Invalid royalty amount');

  let (_, royalty_amount) = RulesTokens::royalty_info(token_id: 0, sale_price: 0);
  assert(royalty_amount == 0, 'Invalid royalty amount');
}

#[test]
#[available_gas(20000000)]
fn test_royalty_info_amount_with_reminder() {
  setup();

  let  royalties_receiver = ROYALTIES_RECEIVER();

  let (_, royalty_amount) = RulesTokens::royalty_info(token_id: 0, sale_price: 101);
  assert(royalty_amount == 6, 'Invalid royalty amount');

  let (_, royalty_amount) = RulesTokens::royalty_info(token_id: 0, sale_price: 119);
  assert(royalty_amount == 6, 'Invalid royalty amount');

  let (_, royalty_amount) = RulesTokens::royalty_info(token_id: 0, sale_price: 19);
  assert(royalty_amount == 1, 'Invalid royalty amount');

  let (_, royalty_amount) = RulesTokens::royalty_info(token_id: 0, sale_price: 1);
  assert(royalty_amount == 1, 'Invalid royalty amount');
}

#[test]
#[available_gas(20000000)]
fn test_royalty_info_receiver() {
  setup();

  let  royalties_receiver = ROYALTIES_RECEIVER();

  let (receiver, _) = RulesTokens::royalty_info(token_id: 100, sale_price: 100);
  assert(receiver == royalties_receiver, 'Invalid royalty receiver');

  let (receiver, _) = RulesTokens::royalty_info(token_id: 20, sale_price: 20);
  assert(receiver == royalties_receiver, 'Invalid royalty receiver');

  let (receiver, _) = RulesTokens::royalty_info(token_id: 0x42, sale_price: 0x42);
  assert(receiver == royalties_receiver, 'Invalid royalty receiver');
}

#[test]
#[available_gas(20000000)]
fn test_set_royalty_receiver() {
  setup();

  let new_royalties_receiver = OTHER();

  RulesTokens::set_royalties_receiver(new_receiver: new_royalties_receiver);

  let (receiver, _) = RulesTokens::royalty_info(token_id: 0x42, sale_price: 0x42);
  assert(receiver == new_royalties_receiver, 'Invalid royalty receiver');
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_set_royalty_receiver_unauthorized() {
  setup();

  testing::set_caller_address(OTHER());
  RulesTokens::set_royalties_receiver(new_receiver: OTHER());
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Caller is the zero address',))]
fn test_set_royalty_receiver_from_zero() {
  setup();

  testing::set_caller_address(ZERO());
  RulesTokens::set_royalties_receiver(new_receiver: OTHER());
}

#[test]
#[available_gas(20000000)]
fn test_set_royalty_percentage_50() {
  setup();

  RulesTokens::set_royalties_percentage(new_percentage: 5000); // 50%

  let (_, royalties_amount) = RulesTokens::royalty_info(token_id: 0x42, sale_price: 0x42);
  assert(royalties_amount == 0x21, 'Invalid royalty amount');
}

#[test]
#[available_gas(20000000)]
fn test_set_royalty_percentage_100() {
  setup();

  RulesTokens::set_royalties_percentage(new_percentage: 10000); // 100%

  let (_, royalties_amount) = RulesTokens::royalty_info(token_id: 0x42, sale_price: 0x42);
  assert(royalties_amount == 0x42, 'Invalid royalty amount');
}

#[test]
#[available_gas(20000000)]
fn test_set_royalty_percentage_zero() {
  setup();

  RulesTokens::set_royalties_percentage(new_percentage: 0); // 0%

  let (_, royalties_amount) = RulesTokens::royalty_info(token_id: 0x42, sale_price: 0x42);
  assert(royalties_amount == 0, 'Invalid royalty amount');
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Invalid percentage',))]
fn test_set_royalty_percentage_above_100() {
  setup();

  RulesTokens::set_royalties_percentage(new_percentage: 10001); // 100.01%
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_set_royalty_percentage_unauthorized() {
  setup();

  testing::set_caller_address(OTHER());
  RulesTokens::set_royalties_percentage(new_percentage: 1);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Caller is the zero address',))]
fn test_set_royalty_percentage_from_zero() {
  setup();

  testing::set_caller_address(ZERO());
  RulesTokens::set_royalties_percentage(new_percentage: 1);
}
