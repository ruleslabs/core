use array::ArrayTrait;
use traits::Into;
use starknet::testing;
use debug::PrintTrait;
use alexandria_data_structures::array_ext::ArrayTraitExt;

// locals
use rules_tokens::core::RulesTokens;
use rules_tokens::typed_data::voucher::Voucher;
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
};

// dispatchers
use rules_account::account::{ AccountABIDispatcher, AccountABIDispatcherTrait };
use rules_tokens::core::{ RulesTokensABIDispatcher, RulesTokensABIDispatcherTrait };

fn setup() -> RulesTokensABIDispatcher {
  // setup chain id to compute vouchers hashes
  testing::set_chain_id(CHAIN_ID());

  // setup voucher signer - 0x1
  let voucher_signer = setup_voucher_signer();

  // setup rules tokens - 0x3
  let mut calldata = ArrayTrait::new();

  let mut uri = URI();
  calldata.append(uri.len().into());
  calldata.append_all(ref uri);
  calldata.append(voucher_signer.contract_address.into());
  calldata.append('marketplace address');

  let rules_tokens_address = utils::deploy(RulesTokens::TEST_CLASS_HASH, calldata);
  RulesTokensABIDispatcher { contract_address: rules_tokens_address }
}

fn setup_voucher_signer() -> AccountABIDispatcher {
  let mut calldata = ArrayTrait::new();
  calldata.append(VOUCHER_SIGNER_PUBLIC_KEY());

  let signer_address = utils::deploy(Signer::TEST_CLASS_HASH, calldata);
  AccountABIDispatcher { contract_address: signer_address }
}

// Always run it after `setup()`
fn setup_receiver() {
  let receiver_address = utils::deploy(Receiver::TEST_CLASS_HASH, ArrayTrait::new());

  assert(receiver_address == RECEIVER_DEPLOYED_ADDRESS(), 'receiver setup failed');
}

#[test]
#[available_gas(20000000)]
fn test__verify_voucher_signature_valid() {
  let rules_tokens = setup();
  let voucher_signer = rules_tokens.voucher_signer();

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
  let rules_tokens = setup();
  let voucher_signer = rules_tokens.voucher_signer();

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
  let rules_tokens = setup();
  let voucher_signer = rules_tokens.voucher_signer();

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
#[should_panic(expected: ('Invalid voucher signature', 'ENTRYPOINT_FAILED'))]
fn test_redeem_voucher_invalid_signature() {
  let rules_tokens = setup();
  let voucher_signer = rules_tokens.voucher_signer();

  let mut voucher = VOUCHER_1();
  voucher.nonce += 1;
  let signature = VOUCHER_SIGNATURE_1();

  rules_tokens.redeem_voucher(:voucher, :signature);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Voucher already consumed', 'ENTRYPOINT_FAILED'))]
fn test_redeem_voucher_already_consumed() {
  let rules_tokens = setup();
  let voucher_signer = rules_tokens.voucher_signer();

  setup_receiver();

  let mut voucher = VOUCHER_2();
  let signature = VOUCHER_SIGNATURE_2();

  // create conditions to successfully redeem the voucher
  let card_model = CARD_MODEL_2();
  let metadata = METADATA();

  rules_tokens.add_card_model(new_card_model: CARD_MODEL_2(), metadata: METADATA());

  rules_tokens.redeem_voucher(:voucher, :signature);
  rules_tokens.redeem_voucher(:voucher, :signature);
}
