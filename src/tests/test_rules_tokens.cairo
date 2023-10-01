use array::{ ArrayTrait, SpanTrait, SpanPartialEq };
use traits::{ Into, TryInto };
use option::OptionTrait;
use starknet::testing;
use zeroable::Zeroable;
use starknet::class_hash::Felt252TryIntoClassHash;
use integer::U256Zeroable;

use rules_erc1155::erc1155::interface::{ IERC1155_ID, IERC1155 };

use rules_utils::introspection::interface::ISRC5;
use rules_utils::royalties::interface::{ IERC2981_ID, IERC2981 };

// locals
use rules_tokens::core::RulesTokens;
use rules_tokens::core::interface::{ IRulesMessages, IRulesData, IRulesTokens };
use rules_tokens::core::tokens::RulesTokens::{ ContractState as RulesTokensContractState, InternalTrait, UpgradeTrait };

use rules_tokens::core::data::CardModelTrait;
use rules_tokens::core::tokens::TokenIdTrait;
use rules_tokens::core::voucher::Voucher;
use super::mocks::signer::Signer;
use super::mocks::receiver::Receiver;
use super::utils;
use super::constants::{
  URI,
  CONTRACT_URI,
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

fn setup() -> RulesTokensContractState {
  // setup chain id to compute vouchers hashes
  testing::set_chain_id(CHAIN_ID());

  // setup voucher signer - 0x1
  let voucher_signer = setup_voucher_signer();

  let mut rules_tokens = RulesTokens::unsafe_new_contract_state();

  rules_tokens.initializer(
    uri_: URI().span(),
    owner_: OWNER(),
    voucher_signer_: voucher_signer.contract_address,
    contract_uri_: CONTRACT_URI().span(),
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
  rules_tokens.add_scarcity(season: card_model_3.season, :scarcity);
  rules_tokens.add_card_model(new_card_model: card_model_2, :metadata);
  rules_tokens.add_card_model(new_card_model: card_model_3, :metadata);

  rules_tokens
}

fn setup_voucher_signer() -> AccountABIDispatcher {
  let calldata = array![VOUCHER_SIGNER_PUBLIC_KEY()];

  let signer_address = utils::deploy(Signer::TEST_CLASS_HASH, calldata);
  AccountABIDispatcher { contract_address: signer_address }
}

// Always run it after `setup()`
fn setup_receiver() -> AccountABIDispatcher {
  let receiver_address = utils::deploy(Receiver::TEST_CLASS_HASH, array![]);

  assert(receiver_address == RECEIVER_DEPLOYED_ADDRESS(), 'receiver setup failed');

  AccountABIDispatcher { contract_address: receiver_address }
}

fn setup_other_receiver() -> AccountABIDispatcher {
  let receiver_address = utils::deploy(Receiver::TEST_CLASS_HASH, array![]);

  assert(receiver_address == OTHER_RECEIVER_DEPLOYED_ADDRESS(), 'receiver setup failed');

  AccountABIDispatcher { contract_address: receiver_address }
}

//
// TESTS
//

#[test]
#[available_gas(20000000)]
fn test_supports_interface() {
  let mut rules_tokens = setup();

  assert(rules_tokens.supports_interface(interface_id: IERC1155_ID), 'Does not support IERC1155');
  assert(rules_tokens.supports_interface(interface_id: IERC2981_ID), 'Does not support IERC2981');
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Invalid voucher signature',))]
fn test_redeem_voucher_invalid_signature() {
  let mut rules_tokens = setup();

  let mut voucher = VOUCHER_1();
  voucher.salt += 1;
  let signature = VOUCHER_SIGNATURE_1();

  rules_tokens.redeem_voucher(:voucher, :signature);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Voucher already consumed',))]
fn test_redeem_voucher_already_consumed() {
  let mut rules_tokens = setup();
  let receiver = setup_receiver();

  let voucher = VOUCHER_2();
  let signature = VOUCHER_SIGNATURE_2();

  let card_model = CARD_MODEL_2();
  let metadata = METADATA();

  rules_tokens.redeem_voucher(:voucher, :signature);
  rules_tokens.redeem_voucher(:voucher, :signature);
}

// Card

#[test]
#[available_gas(20000000)]
fn test_balance_of_after_redeem_voucher() {
  let mut rules_tokens = setup();
  let receiver = setup_receiver();

  let voucher = VOUCHER_2();
  let signature = VOUCHER_SIGNATURE_2();

  // create conditions to successfully redeem the voucher
  let card_model = CARD_MODEL_2();
  let metadata = METADATA();
  let card_token_id = CARD_TOKEN_ID_2();

  assert(
    rules_tokens.balance_of(account: receiver.contract_address, id: card_token_id).is_zero(),
    'balance of before'
  );

  rules_tokens.redeem_voucher(:voucher, :signature);

  assert(
    rules_tokens.balance_of(account: receiver.contract_address, id: card_token_id) == voucher.amount,
    'balance of after'
  );
}

#[test]
#[available_gas(20000000)]
fn test_card_exists() {
  let mut rules_tokens = setup();
  let receiver = setup_receiver();

  let card_token_id = CARD_TOKEN_ID_2();

  assert(!rules_tokens.card_exists(:card_token_id), 'card exists before');

  rules_tokens._mint(to: receiver.contract_address, token_id: TokenIdTrait::new(id: card_token_id), amount: 1);

  assert(rules_tokens.card_exists(:card_token_id), 'card exists after');
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Card already minted',))]
fn test__mint_card_already_minted() {
  let mut rules_tokens = setup();
  let receiver = setup_receiver();

  let card_token_id = CARD_TOKEN_ID_2();

  rules_tokens._mint(to: receiver.contract_address, token_id: TokenIdTrait::new(id: card_token_id), amount: 1);
  rules_tokens._mint(to: receiver.contract_address, token_id: TokenIdTrait::new(id: card_token_id), amount: 1);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Card model does not exists',))]
fn test__mint_card_unknown_card_model() {
  let mut rules_tokens = setup();
  let receiver = setup_receiver();

  let card_token_id = CARD_TOKEN_ID_2();

  rules_tokens._mint(to: receiver.contract_address, token_id: TokenIdTrait::new(id: card_token_id + 1), amount: 1);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Serial number is out of range',))]
fn test__mint_card_out_of_range_serial_number() {
  let mut rules_tokens = setup();
  let receiver = setup_receiver();

  let scarcity = SCARCITY();
  let card_token_id = u256 { low: CARD_MODEL_3().id(), high: scarcity.max_supply + 1 };

  rules_tokens._mint(to: receiver.contract_address, token_id: TokenIdTrait::new(id: card_token_id), amount: 1);
}

#[test]
#[available_gas(20000000)]
fn test__mint_card_in_range_serial_number() {
  let mut rules_tokens = setup();
  let receiver = setup_receiver();

  let scarcity = SCARCITY();
  let card_token_id = u256 { low: CARD_MODEL_3().id(), high: scarcity.max_supply };

  assert(!rules_tokens.card_exists(:card_token_id), 'card exists before');

  rules_tokens._mint(to: receiver.contract_address, token_id: TokenIdTrait::new(id: card_token_id), amount: 1);

  assert(rules_tokens.card_exists(:card_token_id), 'card exists after');
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Card amount cannot exceed 1',))]
fn test__mint_card_invalid_amount() {
  let mut rules_tokens = setup();
  let receiver = setup_receiver();

  let card_token_id = CARD_TOKEN_ID_2();

  rules_tokens._mint(to: receiver.contract_address, token_id: TokenIdTrait::new(id: card_token_id), amount: 2);
}

#[test]
#[available_gas(20000000)]
fn test__mint_pack() {
  let mut rules_tokens = setup();
  let receiver = setup_receiver();

  let card_token_id = CARD_TOKEN_ID_2();
  let pack_token_id = u256 { low: card_token_id.low, high: 0 };

  rules_tokens._mint(to: receiver.contract_address, token_id: TokenIdTrait::new(id: pack_token_id), amount: 2);

  assert(rules_tokens.balance_of(account: receiver.contract_address, id: pack_token_id) == 2, 'pack balance after');
}

// Upgrade

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_upgrade_unauthorized() {
  let mut rules_tokens = setup();

  testing::set_caller_address(OTHER());
  rules_tokens.upgrade(new_implementation: 'new implementation'.try_into().unwrap());
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Caller is the zero address',))]
fn test_upgrade_from_zero() {
  let mut rules_tokens = setup();

  testing::set_caller_address(ZERO());
  rules_tokens.upgrade(new_implementation: 'new implementation'.try_into().unwrap());
}

// Add scarcity

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Caller is the zero address',))]
fn test_add_scarcity_from_zero() {
  let mut rules_tokens = setup();

  let season = SEASON();

  testing::set_caller_address(ZERO());
  rules_tokens.add_scarcity(:season, scarcity: SCARCITY());
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_add_scarcity_unauthorized() {
  let mut rules_tokens = setup();

  let season = SEASON();

  testing::set_caller_address(OTHER());
  rules_tokens.add_scarcity(:season, scarcity: SCARCITY());
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Caller is the zero address',))]
fn test_add_card_model_from_zero() {
  let mut rules_tokens = setup();

  let card_model_2 = CARD_MODEL_2();
  let metadata = METADATA();

  testing::set_caller_address(ZERO());
  rules_tokens.add_card_model(new_card_model: card_model_2, :metadata);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_add_card_model_unauthorized() {
  let mut rules_tokens = setup();

  let card_model_2 = CARD_MODEL_2();
  let metadata = METADATA();

  testing::set_caller_address(OTHER());
  rules_tokens.add_card_model(new_card_model: card_model_2, :metadata);
}

// Marketplace

#[test]
#[available_gas(20000000)]
fn test_marketplace() {
  let mut rules_tokens = setup();

  let marketplace = MARKETPLACE();

  assert(rules_tokens.marketplace() == marketplace, 'Invalid marketplace address');
}

#[test]
#[available_gas(20000000)]
fn test_set_marketplace() {
  let mut rules_tokens = setup();

  let marketplace = MARKETPLACE();
  let new_marketplace = OTHER();

  assert(rules_tokens.marketplace() == marketplace, 'Invalid marketplace address');

  rules_tokens.set_marketplace(marketplace_: new_marketplace);

  assert(rules_tokens.marketplace() == new_marketplace, 'Invalid marketplace address');
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Caller is the zero address',))]
fn test_set_marketplace_from_zero() {
  let mut rules_tokens = setup();

  let marketplace = MARKETPLACE();
  let new_marketplace = OTHER();

  testing::set_caller_address(ZERO());
  rules_tokens.set_marketplace(marketplace_: new_marketplace);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_set_marketplace_unauthorized() {
  let mut rules_tokens = setup();

  let marketplace = MARKETPLACE();
  let new_marketplace = OTHER();

  testing::set_caller_address(OTHER());
  rules_tokens.set_marketplace(marketplace_: new_marketplace);
}

// Reedem voucher to

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Caller is not the marketplace',))]
fn test_redeem_voucher_to_unauthorized() {
  let mut rules_tokens = setup();
  let receiver = setup_receiver();

  let voucher = VOUCHER_2();
  let signature = VOUCHER_SIGNATURE_2();

  let card_model = CARD_MODEL_2();
  let metadata = METADATA();

  testing::set_caller_address(OWNER());
  rules_tokens.redeem_voucher_to(to: OTHER(), :voucher, :signature);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Caller is the zero address',))]
fn test_redeem_voucher_to_from_zero() {
  let mut rules_tokens = setup();
  let receiver = setup_receiver();

  let voucher = VOUCHER_2();
  let signature = VOUCHER_SIGNATURE_2();

  let card_model = CARD_MODEL_2();
  let metadata = METADATA();

  testing::set_caller_address(ZERO());
  rules_tokens.redeem_voucher_to(to: OTHER(), :voucher, :signature);
}

#[test]
#[available_gas(20000000)]
fn test_balance_of_after_redeem_voucher_to_() {
  let mut rules_tokens = setup();
  setup_receiver();

  let receiver = setup_other_receiver();

  let voucher = VOUCHER_2();
  let signature = VOUCHER_SIGNATURE_2();

  // create conditions to successfully redeem the voucher
  let card_model = CARD_MODEL_2();
  let metadata = METADATA();
  let card_token_id = CARD_TOKEN_ID_2();

  assert(
    rules_tokens.balance_of(account: receiver.contract_address, id: card_token_id).is_zero(),
    'balance of before'
  );

  testing::set_caller_address(MARKETPLACE());
  rules_tokens.redeem_voucher_to(to: receiver.contract_address, :voucher, :signature);

  assert(
    rules_tokens.balance_of(account: receiver.contract_address, id: card_token_id) == voucher.amount,
    'balance of after'
  );
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Invalid voucher signature',))]
fn test_redeem_voucher_to_invalid_signature() {
  let mut rules_tokens = setup();
  let receiver = setup_receiver();

  let mut voucher = VOUCHER_2();
  voucher.salt += 1;
  let signature = VOUCHER_SIGNATURE_2();

  let card_model = CARD_MODEL_2();
  let metadata = METADATA();

  testing::set_caller_address(MARKETPLACE());
  rules_tokens.redeem_voucher_to(to: OTHER(), :voucher, :signature);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Voucher already consumed',))]
fn test_redeem_voucher_to_already_consumed() {
  let mut rules_tokens = setup();
  setup_receiver();

  let receiver = setup_other_receiver();

  let voucher = VOUCHER_2();
  let signature = VOUCHER_SIGNATURE_2();

  let card_model = CARD_MODEL_2();
  let metadata = METADATA();

  testing::set_caller_address(MARKETPLACE());
  rules_tokens.redeem_voucher_to(to: receiver.contract_address, :voucher, :signature);
  rules_tokens.redeem_voucher_to(to: receiver.contract_address, :voucher, :signature);
}

// ERC2981 - Royalties

#[test]
#[available_gas(20000000)]
fn test_royalty_info_amount_without_reminder() {
  let mut rules_tokens = setup();

  let (_, royalty_amount) = rules_tokens.royalty_info(token_id: 0, sale_price: 100);
  assert(royalty_amount == 5, 'Invalid royalty amount');

  let (_, royalty_amount) = rules_tokens.royalty_info(token_id: 0, sale_price: 20);
  assert(royalty_amount == 1, 'Invalid royalty amount');

  let (_, royalty_amount) = rules_tokens.royalty_info(token_id: 0, sale_price: 0xfffffff0);
  assert(royalty_amount == 0xccccccc, 'Invalid royalty amount');

  let (_, royalty_amount) = rules_tokens.royalty_info(token_id: 0, sale_price: 0);
  assert(royalty_amount == 0, 'Invalid royalty amount');
}

#[test]
#[available_gas(20000000)]
fn test_royalty_info_amount_with_reminder() {
  let mut rules_tokens = setup();

  let  royalties_receiver = ROYALTIES_RECEIVER();

  let (_, royalty_amount) = rules_tokens.royalty_info(token_id: 0, sale_price: 101);
  assert(royalty_amount == 6, 'Invalid royalty amount');

  let (_, royalty_amount) = rules_tokens.royalty_info(token_id: 0, sale_price: 119);
  assert(royalty_amount == 6, 'Invalid royalty amount');

  let (_, royalty_amount) = rules_tokens.royalty_info(token_id: 0, sale_price: 19);
  assert(royalty_amount == 1, 'Invalid royalty amount');

  let (_, royalty_amount) = rules_tokens.royalty_info(token_id: 0, sale_price: 1);
  assert(royalty_amount == 1, 'Invalid royalty amount');
}

#[test]
#[available_gas(20000000)]
fn test_royalty_info_receiver() {
  let mut rules_tokens = setup();

  let  royalties_receiver = ROYALTIES_RECEIVER();

  let (receiver, _) = rules_tokens.royalty_info(token_id: 100, sale_price: 100);
  assert(receiver == royalties_receiver, 'Invalid royalty receiver');

  let (receiver, _) = rules_tokens.royalty_info(token_id: 20, sale_price: 20);
  assert(receiver == royalties_receiver, 'Invalid royalty receiver');

  let (receiver, _) = rules_tokens.royalty_info(token_id: 0x42, sale_price: 0x42);
  assert(receiver == royalties_receiver, 'Invalid royalty receiver');
}

#[test]
#[available_gas(20000000)]
fn test_set_royalty_receiver() {
  let mut rules_tokens = setup();

  let new_royalties_receiver = OTHER();

  rules_tokens.set_royalties_receiver(new_receiver: new_royalties_receiver);

  let (receiver, _) = rules_tokens.royalty_info(token_id: 0x42, sale_price: 0x42);
  assert(receiver == new_royalties_receiver, 'Invalid royalty receiver');
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_set_royalty_receiver_unauthorized() {
  let mut rules_tokens = setup();

  testing::set_caller_address(OTHER());
  rules_tokens.set_royalties_receiver(new_receiver: OTHER());
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Caller is the zero address',))]
fn test_set_royalty_receiver_from_zero() {
  let mut rules_tokens = setup();

  testing::set_caller_address(ZERO());
  rules_tokens.set_royalties_receiver(new_receiver: OTHER());
}

#[test]
#[available_gas(20000000)]
fn test_set_royalty_percentage_50() {
  let mut rules_tokens = setup();

  rules_tokens.set_royalties_percentage(new_percentage: 5000); // 50%

  let (_, royalties_amount) = rules_tokens.royalty_info(token_id: 0x42, sale_price: 0x42);
  assert(royalties_amount == 0x21, 'Invalid royalty amount');
}

#[test]
#[available_gas(20000000)]
fn test_set_royalty_percentage_100() {
  let mut rules_tokens = setup();

  rules_tokens.set_royalties_percentage(new_percentage: 10000); // 100%

  let (_, royalties_amount) = rules_tokens.royalty_info(token_id: 0x42, sale_price: 0x42);
  assert(royalties_amount == 0x42, 'Invalid royalty amount');
}

#[test]
#[available_gas(20000000)]
fn test_set_royalty_percentage_zero() {
  let mut rules_tokens = setup();

  rules_tokens.set_royalties_percentage(new_percentage: 0); // 0%

  let (_, royalties_amount) = rules_tokens.royalty_info(token_id: 0x42, sale_price: 0x42);
  assert(royalties_amount == 0, 'Invalid royalty amount');
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Invalid percentage',))]
fn test_set_royalty_percentage_above_100() {
  let mut rules_tokens = setup();

  rules_tokens.set_royalties_percentage(new_percentage: 10001); // 100.01%
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_set_royalty_percentage_unauthorized() {
  let mut rules_tokens = setup();

  testing::set_caller_address(OTHER());
  rules_tokens.set_royalties_percentage(new_percentage: 1);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Caller is the zero address',))]
fn test_set_royalty_percentage_from_zero() {
  let mut rules_tokens = setup();

  testing::set_caller_address(ZERO());
  rules_tokens.set_royalties_percentage(new_percentage: 1);
}

// Tranfer from marketplace

#[test]
#[available_gas(20000000)]
fn test_safe_transfer_from_marketplace() {
  let mut rules_tokens = setup();
  let receiver = setup_receiver();
  let other_receiver = setup_other_receiver();

  let card_token_id = CARD_TOKEN_ID_2();

  rules_tokens._mint(to: receiver.contract_address, token_id: TokenIdTrait::new(id: card_token_id), amount: 1);

  testing::set_caller_address(MARKETPLACE());
  rules_tokens.safe_transfer_from(
    from: receiver.contract_address,
    to: other_receiver.contract_address,
    id: card_token_id,
    amount: 1,
    data: array![].span()
  );
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC1155: caller not allowed',))]
fn test_safe_transfer_from_unauthorized() {
  let mut rules_tokens = setup();
  let receiver = setup_receiver();
  let other_receiver = setup_other_receiver();

  let card_token_id = CARD_TOKEN_ID_2();

  rules_tokens._mint(to: receiver.contract_address, token_id: TokenIdTrait::new(id: card_token_id), amount: 1);

  testing::set_caller_address(OTHER());
  rules_tokens.safe_transfer_from(
    from: receiver.contract_address,
    to: other_receiver.contract_address,
    id: card_token_id,
    amount: 1,
    data: array![].span()
  );
}

// Contract URI

#[test]
#[available_gas(20000000)]
fn test_contract_uri() {
  let mut rules_tokens = setup();

  let contract_uri = CONTRACT_URI().span();

  assert(rules_tokens.contract_uri() == contract_uri, 'Invalid contract URI address');
}

#[test]
#[available_gas(20000000)]
fn test_set_contract_uri() {
  let mut rules_tokens = setup();

  let contract_uri = CONTRACT_URI().span();
  let new_contract_uri = URI().span();

  assert(rules_tokens.contract_uri() == contract_uri, 'Invalid contract URI address');

  rules_tokens.set_contract_uri(contract_uri_: new_contract_uri);

  assert(rules_tokens.contract_uri() == new_contract_uri, 'Invalid contract URI address');
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Caller is the zero address',))]
fn test_set_contract_uri_from_zero() {
  let mut rules_tokens = setup();

  let contract_uri = CONTRACT_URI().span();
  let new_contract_uri = URI().span();

  testing::set_caller_address(ZERO());
  rules_tokens.set_contract_uri(contract_uri_: new_contract_uri);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_set_contract_uri_unauthorized() {
  let mut rules_tokens = setup();

  let contract_uri = CONTRACT_URI().span();
  let new_contract_uri = URI().span();

  testing::set_caller_address(OTHER());
  rules_tokens.set_contract_uri(contract_uri_: new_contract_uri);
}
