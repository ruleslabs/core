use array::ArrayTrait;
use traits::Into;
use starknet::testing;
use debug::PrintTrait;

// locals
use rules_core::core::RulesCore;
use rules_core::typed_data::voucher::Voucher;
use super::mocks::signer::Signer;
use super::utils;

// dispatchers
use rules_account::account::{ AccountABIDispatcher, AccountABIDispatcherTrait };
use rules_core::core::{ RulesCoreABIDispatcher, RulesCoreABIDispatcherTrait };

fn CHAIN_ID() -> felt252 {
  'SN_MAIN'
}

fn VOUCHER_1() -> Voucher {
  Voucher {
    receiver: starknet::contract_address_const::<'receiver 1'>(),
    token_id: u256 { low: 'token id 1 low', high: 'token id 1 high' },
    amount: u256 { low: 'amount 1 low', high: 'amount 1 high' },
    nonce: 1,
  }
}

fn VOUCHER_SIGNER() -> starknet::ContractAddress {
  starknet::contract_address_const::<'voucher signer'>()
}

fn VOUCHER_SIGNATURE_1() -> Array<felt252> {
  let mut signature = ArrayTrait::new();

  signature.append(2695953738417365536425985872255638063085251035130087155136805057258727647085);
  signature.append(1604661661602024228358883734337166978451574222073686573714095457989525633748);

  signature
}

fn VOUCHER_SIGNER_PUBLIC_KEY() -> felt252 {
  883045738439352841478194533192765345509759306772397516907181243450667673002
}

fn setup() -> RulesCoreABIDispatcher {
  // setup chain id to compute vouchers hashes
  testing::set_chain_id(CHAIN_ID());

  let voucher_signer = setup_voucher_signer();

  let mut calldata = ArrayTrait::new();
  calldata.append(voucher_signer.contract_address.into());

  let rules_core_address = utils::deploy(RulesCore::TEST_CLASS_HASH, calldata);
  RulesCoreABIDispatcher { contract_address: rules_core_address }
}

fn setup_voucher_signer() -> AccountABIDispatcher {
  let mut calldata = ArrayTrait::new();
  calldata.append(VOUCHER_SIGNER_PUBLIC_KEY());

  let signer_address = utils::deploy(Signer::TEST_CLASS_HASH, calldata);
  AccountABIDispatcher { contract_address: signer_address }
}

#[test]
#[available_gas(20000000)]
fn test__verify_voucher_signature_valid() {
  let rules_core = setup();
  let voucher_signer = rules_core.voucher_signer();

  let voucher = VOUCHER_1();
  let signature = VOUCHER_SIGNATURE_1();

  assert(
    RulesCore::_is_voucher_signature_valid(:voucher, :signature, signer: voucher_signer),
    'Invalid voucher signature'
  );
}

#[test]
#[available_gas(20000000)]
fn test__verify_voucher_signature_invalid() {
  let rules_core = setup();
  let voucher_signer = rules_core.voucher_signer();

  let mut voucher = VOUCHER_1();
  voucher.amount += 1;
  let signature = VOUCHER_SIGNATURE_1();

  assert(
    !RulesCore::_is_voucher_signature_valid(:voucher, :signature, signer: voucher_signer),
    'Invalid voucher signature'
  );
}
