use array::ArrayTrait;
use starknet::testing;

// locals
use rules_tokens::core::messages::RulesMessages;
use super::constants::{
  CHAIN_ID,
  VOUCHER_1,
  VOUCHER_SIGNATURE_1,
  VOUCHER_SIGNER_PUBLIC_KEY,
};
use super::utils;
use super::mocks::signer::Signer;

// dispatchers
use rules_account::account::{ AccountABIDispatcher, AccountABIDispatcherTrait };

fn setup() {
  // setup chain id to compute vouchers hashes
  testing::set_chain_id(CHAIN_ID());

  // setup voucher signer - 0x1
  let voucher_signer = setup_voucher_signer();

  RulesMessages::constructor(voucher_signer_: voucher_signer.contract_address);
}

fn setup_voucher_signer() -> AccountABIDispatcher {
  let mut calldata = ArrayTrait::new();
  calldata.append(VOUCHER_SIGNER_PUBLIC_KEY());

  let signer_address = utils::deploy(Signer::TEST_CLASS_HASH, calldata);
  AccountABIDispatcher { contract_address: signer_address }
}

#[test]
#[available_gas(20000000)]
fn test_consume_valid_voucher_valid() {
  setup();

  let voucher_signer = RulesMessages::voucher_signer();

  let voucher = VOUCHER_1();
  let signature = VOUCHER_SIGNATURE_1();

  RulesMessages::consume_valid_voucher(:voucher, :signature);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Invalid voucher signature',))]
fn test_consume_valid_voucher_invalid() {
  setup();

  let voucher_signer = RulesMessages::voucher_signer();

  let mut voucher = VOUCHER_1();
  voucher.amount += 1;
  let signature = VOUCHER_SIGNATURE_1();

  RulesMessages::consume_valid_voucher(:voucher, :signature);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Voucher already consumed',))]
fn test_consume_valid_voucher_already_consumed() {
  setup();

  let voucher_signer = RulesMessages::voucher_signer();

  let mut voucher = VOUCHER_1();
  let signature = VOUCHER_SIGNATURE_1();

  RulesMessages::consume_valid_voucher(:voucher, :signature);
  RulesMessages::consume_valid_voucher(:voucher, :signature);
}
