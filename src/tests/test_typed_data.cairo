use starknet::testing;

// locals
use rules_tokens::typed_data::TypedDataTrait;
use rules_tokens::typed_data::voucher::Voucher;
use rules_tokens::typed_data::order::{ Order, Item, ERC20_Item, ERC1155_Item };

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
    salt: 6,
  }
}

fn VOUCHER_HASH() -> felt252 {
  0x6a0bb8dafde554d96eb3bcf536c8f43c57d8b56af4a84317f3e941f1b2e8fb4
}

fn ORDER() -> Order {
  Order {
    offer_item: Item::ERC1155(ERC1155_Item {
      token: starknet::contract_address_const::<1>(),
      identifier: u256 { low: 2, high: 3 },
      amount: u256 { low: 4, high: 5 },
    }),
    consideration_item: Item::ERC20(ERC20_Item {
      token: starknet::contract_address_const::<6>(),
      amount: u256 { low: 7, high: 8 },
    }),
    end_time: 9,
    salt: 10,
  }
}

fn ORDER_HASH() -> felt252 {
  0x52fc92eacf7be2ff8a45ec31d5394df02c5ee5e57268fd62aa25f34924169d2
}

//
// VOUCHER
//

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
  voucher.salt += 1;

  assert(voucher.compute_hash_from(from: SIGNER()) != VOUCHER_HASH(), 'Invalid voucher hash')
}

//
// ORDER
//

#[test]
#[available_gas(20000000)]
fn test_order_compute_hash_from_signer() {
  testing::set_chain_id(CHAIN_ID());
  assert(ORDER().compute_hash_from(from: SIGNER()) == ORDER_HASH(), 'Invalid order hash')
}

#[test]
#[available_gas(20000000)]
fn test_order_compute_hash_from_signer_with_invalid_chain_id() {
  testing::set_chain_id(CHAIN_ID() + 1);
  assert(ORDER().compute_hash_from(from: SIGNER()) != ORDER_HASH(), 'Invalid order hash')
}

#[test]
#[available_gas(20000000)]
fn test_order_compute_hash_from_other() {
  testing::set_chain_id(CHAIN_ID());
  assert(ORDER().compute_hash_from(from: OTHER()) != ORDER_HASH(), 'Invalid order hash')
}

#[test]
#[available_gas(20000000)]
fn test_invalid_order_compute_hash_from_signer() {
  testing::set_chain_id(CHAIN_ID());

  let mut order = ORDER();
  order.salt += 1;

  assert(order.compute_hash_from(from: SIGNER()) != ORDER_HASH(), 'Invalid order hash')
}
