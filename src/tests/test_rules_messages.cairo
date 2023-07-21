use core::traits::Into;
use array::ArrayTrait;
use starknet::testing;

// locals
use rules_tokens::core::messages::RulesMessages;
use rules_tokens::core::interface::IRulesMessages;
use rules_tokens::core::messages::RulesMessages::{ ContractState as RulesMessagesContractState, InternalTrait };

use super::constants::{
  CHAIN_ID,
  BLOCK_TIMESTAMP,
  VOUCHER_1,
  VOUCHER_SIGNATURE_1,
  VOUCHER_SIGNER_PUBLIC_KEY,
};
use super::utils;
use super::mocks::signer::Signer;

// dispatchers
use rules_account::account::{ AccountABIDispatcher, AccountABIDispatcherTrait };

fn setup() -> RulesMessagesContractState {
  // setup block timestamp
  testing::set_block_timestamp(BLOCK_TIMESTAMP());

  // setup chain id to compute vouchers hashes
  testing::set_chain_id(CHAIN_ID());

  // setup voucher signer - 0x1
  let voucher_signer = setup_signer(VOUCHER_SIGNER_PUBLIC_KEY());

  let mut rules_messages = RulesMessages::unsafe_new_contract_state();

  rules_messages.initializer(voucher_signer_: voucher_signer.contract_address);

  rules_messages
}

fn setup_signer(public_key: felt252) -> AccountABIDispatcher {
  let mut calldata = ArrayTrait::new();
  calldata.append(public_key);

  let signer_address = utils::deploy(Signer::TEST_CLASS_HASH, calldata);
  AccountABIDispatcher { contract_address: signer_address }
}

// VOUCHER

#[test]
#[available_gas(20000000)]
fn test_consume_valid_voucher_valid() {
  let mut rules_messages = setup();

  let voucher_signer = rules_messages.voucher_signer();

  let voucher = VOUCHER_1();
  let signature = VOUCHER_SIGNATURE_1();

  rules_messages.consume_valid_voucher(:voucher, :signature);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Invalid voucher signature',))]
fn test_consume_valid_voucher_invalid() {
  let mut rules_messages = setup();

  let mut voucher = VOUCHER_1();
  voucher.amount += 1;
  let signature = VOUCHER_SIGNATURE_1();

  rules_messages.consume_valid_voucher(:voucher, :signature);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Voucher already consumed',))]
fn test_consume_valid_voucher_already_consumed() {
  let mut rules_messages = setup();

  let mut voucher = VOUCHER_1();
  let signature = VOUCHER_SIGNATURE_1();

  rules_messages.consume_valid_voucher(:voucher, :signature);
  rules_messages.consume_valid_voucher(:voucher, :signature);
}
