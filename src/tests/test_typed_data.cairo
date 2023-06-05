use starknet::testing;
use debug::PrintTrait;

// locals
use rules_core::typed_data::typed_data::{ TypedDataTrait };
use rules_core::typed_data::voucher::{ Voucher };

fn CHAIN_ID() -> felt252 {
  'SN_MAIN'
}

fn SIGNER() -> starknet::ContractAddress {
  starknet::contract_address_const::<'signer'>()
}

fn OTHER() -> starknet::ContractAddress {
  starknet::contract_address_const::<'other'>()
}

fn VOUCHER() -> Voucher {
  Voucher {
    receiver: starknet::contract_address_const::<1>(),
    token_id: u256 { low: 2, high: 3 },
    amount: u256 { low: 4, high: 5 },
    nonce: 6,
  }
}

fn VOUCHER_HASH() -> felt252 {
  0x5e71d08cb6c4d0ef021829f96f0482635844c52d1c14ef560379bf75b584822
}

#[test]
#[available_gas(20000000)]
fn test_voucher_compute_hash_from_signer() {
  testing::set_chain_id(CHAIN_ID());
  assert(VOUCHER().compute_hash_from(from: SIGNER()) == VOUCHER_HASH(), 'Invalid voucher hash')
}

#[test]
#[available_gas(20000000)]
fn test_voucher_compute_hash_from_signer_with_invalid_chain_id() {
  testing::set_chain_id(CHAIN_ID() + 1);
  assert(VOUCHER().compute_hash_from(from: SIGNER()) != VOUCHER_HASH(), 'Invalid voucher hash')
}

#[test]
#[available_gas(20000000)]
fn test_voucher_compute_hash_from_other() {
  testing::set_chain_id(CHAIN_ID());
  assert(VOUCHER().compute_hash_from(from: OTHER()) != VOUCHER_HASH(), 'Invalid voucher hash')
}

#[test]
#[available_gas(20000000)]
fn test_invalid_voucher_compute_hash_from_signer() {
  testing::set_chain_id(CHAIN_ID());

  let mut voucher = VOUCHER();
  voucher.nonce += 1;

  assert(voucher.compute_hash_from(from: SIGNER()) != VOUCHER_HASH(), 'Invalid voucher hash')
}
