use array::ArrayTrait;
use traits::Into;
use starknet::testing;
use debug::PrintTrait;
use alexandria_data_structures::array_ext::ArrayTraitExt;

// locals
use rules_tokens::core::RulesTokens;
use rules_tokens::typed_data::voucher::Voucher;
use super::mocks::signer::Signer;
use super::utils;

// dispatchers
use rules_account::account::{ AccountABIDispatcher, AccountABIDispatcherTrait };
use rules_tokens::core::{ RulesTokensABIDispatcher, RulesTokensABIDispatcherTrait };

fn URI() -> Array<felt252> {
  let mut uri = ArrayTrait::new();

  uri.append(111);
  uri.append(222);
  uri.append(333);

  uri
}

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

fn VOUCHER_SIGNATURE_1() -> Span<felt252> {
  let mut signature = ArrayTrait::new();

  signature.append(2695953738417365536425985872255638063085251035130087155136805057258727647085);
  signature.append(1604661661602024228358883734337166978451574222073686573714095457989525633748);

  signature.span()
}

fn VOUCHER_SIGNER_PUBLIC_KEY() -> felt252 {
  883045738439352841478194533192765345509759306772397516907181243450667673002
}

fn setup() -> RulesTokensABIDispatcher {
  // setup chain id to compute vouchers hashes
  testing::set_chain_id(CHAIN_ID());

  let voucher_signer = setup_voucher_signer();

  let mut calldata = ArrayTrait::new();

  let mut uri = URI();
  calldata.append(uri.len().into());
  calldata.append_all(ref uri);
  calldata.append(voucher_signer.contract_address.into());

  let rules_tokens_address = utils::deploy(RulesTokens::TEST_CLASS_HASH, calldata);
  RulesTokensABIDispatcher { contract_address: rules_tokens_address }
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

  let voucher = VOUCHER_1();
  let signature = VOUCHER_SIGNATURE_1();

  rules_tokens.redeem_voucher(:voucher, :signature);
  rules_tokens.redeem_voucher(:voucher, :signature);
}
