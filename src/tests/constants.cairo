use array::ArrayTrait;

use rules_utils::utils::base64::Base64;
use rules_utils::utils::array::ArrayTraitExt;

// locals
use rules_tokens::core::data::{ RulesData, CardModelTrait, ScarcityTrait };
use rules_tokens::core::interface::{ CardModel, Scarcity, Pack, Metadata };
use rules_tokens::core::voucher::Voucher;

fn METADATA() -> Metadata {
  let mut hash = array![];
  hash.append('hash 1');
  hash.append('hash 2');

  Metadata { hash: hash.span() }
}

fn METADATA_2() -> Metadata {
  let mut hash = array![];
  hash.append('hash 2');
  hash.append('hash 1');

  Metadata { hash: hash.span() }
}

fn INVALID_METADATA() -> Metadata {
  let mut hash = array![];
  hash.append(1);
  hash.append(2);
  hash.append(3);

  Metadata { hash: hash.span() }
}

fn CARD_MODEL_1() -> CardModel {
  CardModel {
    artist_name: 'ju',
    season: 894,
    scarcity_id: 0,
  }
}

// 0x1eeb9e09cde37e1ddec3ac07df646ce0
fn CARD_MODEL_2() -> CardModel {
  CardModel {
    artist_name: 'Double P',
    season: 1995,
    scarcity_id: 0,
  }
}

fn CARD_MODEL_3() -> CardModel {
  CardModel {
    artist_name: 'Sully',
    season: 33,
    scarcity_id: 1,
  }
}

fn CARD_MODEL_ID() -> u128 {
  0xf0579640f29841cc5a94e67ec97ed9e2
}

fn PACK_1() -> Pack {
  Pack {
    name: 'Pack 1',
    season: 1,
  }
}

fn PACK_2() -> Pack {
  Pack {
    name: 'Pack 2',
    season: 2,
  }
}

fn PACK_ID_1() -> u128 {
  0x1
}

fn CARD_TOKEN_ID_2() -> u256 {
  u256 { low: CARD_MODEL_2().id(), high: 0x42 }
}

fn COMMON_SCARCITY() -> Scarcity {
  ScarcityTrait::common()
}

fn SCARCITY() -> Scarcity {
  Scarcity {
    max_supply: 1,
    name: 'silver',
  }
}

fn SEASON() -> felt252 {
  'I\'ll be dead until this season'
}

fn URI() -> Array<felt252> {
  array![111, 222, 333]
}

fn CONTRACT_URI() -> Array<felt252> {
  array![111, 222, 333]
}

fn CHAIN_ID() -> felt252 {
  'SN_MAIN'
}

fn BLOCK_TIMESTAMP() -> u64 {
  103374042_u64
}

//
// METADATA URI
//

fn CARD_MODEL_2_URI() -> Array<felt252> {
  let mut ret = array![
    '{"image":"ipfs://hash 1hash 2",',
    '"animation_url":"ipfs://hash 2h',
    'ash 1","name":"Double P - Commo',
    'n #66","attributes":[{"trait_ty',
    'pe":"Serial number","value":"66',
    '"},{"trait_type":"Artist","valu',
    'e":"Double P"},{"trait_type":"R',
    'arity","value":"Common"},{"trai',
    't_type":"Season","value":"1995"',
    '}]}',
  ];

  ret = ret.encode();

  array!['data:application/json;base64,'].concat(@ret)
}

fn PACK_1_URI() -> Array<felt252> {
  let mut ret = array![
    '{"image":"ipfs://hash 1hash 2",',
    '"name":"Pack 1","attributes":[{',
    '"trait_type":"Season","value":"',
    '1"}]}',
  ];

  ret = ret.encode();

  array!['data:application/json;base64,'].concat(@ret)
}

//
// VOUCHERS
//

fn VOUCHER_1() -> Voucher {
  Voucher {
    receiver: starknet::contract_address_const::<'receiver 1'>(),
    token_id: u256 { low: 'token id 1 low', high: 'token id 1 high' },
    amount: u256 { low: 'amount 1 low', high: 'amount 1 high' },
    salt: 1,
  }
}

// valid card voucher
fn VOUCHER_2() -> Voucher {
  Voucher {
    receiver: RECEIVER_DEPLOYED_ADDRESS(),
    token_id: CARD_TOKEN_ID_2(),
    amount: u256 { low: 1, high: 0 },
    salt: 1,
  }
}

fn VOUCHER_SIGNER() -> starknet::ContractAddress {
  starknet::contract_address_const::<'voucher signer'>()
}

fn VOUCHER_SIGNATURE_1() -> Span<felt252> {
  array![
    3087695227963934782411443355974054330531912780999299366340358158172188798955,
    2936225994738482437582710271434813684883822280549795930447609837161446520483,
  ].span()
}

fn VOUCHER_SIGNATURE_2() -> Span<felt252> {
  array![
    1567101499423974405132552866654397941796461247734137894210715097651800024623,
    2406489013391837256524712835539748966140428060639388300020587314195643879538,
  ].span()
}

fn VOUCHER_SIGNER_PUBLIC_KEY() -> felt252 {
  0x1f3c942d7f492a37608cde0d77b884a5aa9e11d2919225968557370ddb5a5aa
}

// ADDRESSES

fn RECEIVER_DEPLOYED_ADDRESS() -> starknet::ContractAddress {
  starknet::contract_address_const::<0x2>()
}

fn OTHER_RECEIVER_DEPLOYED_ADDRESS() -> starknet::ContractAddress {
  starknet::contract_address_const::<0x3>()
}

fn ZERO() -> starknet::ContractAddress {
  Zeroable::zero()
}

fn OWNER() -> starknet::ContractAddress {
  starknet::contract_address_const::<10>()
}

fn OTHER() -> starknet::ContractAddress {
  starknet::contract_address_const::<20>()
}

fn MARKETPLACE() -> starknet::ContractAddress {
  starknet::contract_address_const::<'marketplace'>()
}

fn ROYALTIES_RECEIVER() -> starknet::ContractAddress {
  starknet::contract_address_const::<'royalties receiver'>()
}

// MISC

fn ROYALTIES_PERCENTAGE() -> u16 {
  500 // 5%
}
