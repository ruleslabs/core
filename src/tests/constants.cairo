use array::ArrayTrait;

// locals
use rules_tokens::core::data::{ RulesData, CardModelTrait, ScarcityTrait };
use rules_tokens::core::interface::{ CardModel, Scarcity, Metadata, METADATA_MULTIHASH_IDENTIFIER };
use rules_tokens::typed_data::voucher::Voucher;
use rules_tokens::typed_data::order::{ Order, Item, ERC20_Item, ERC1155_Item };

fn METADATA() -> Metadata {
  Metadata {
    multihash_identifier: METADATA_MULTIHASH_IDENTIFIER,
    hash: u256 {
      low: 'hash low',
      high: 'hash high',
    },
  }
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
  let mut uri = ArrayTrait::new();

  uri.append(111);
  uri.append(222);
  uri.append(333);

  uri
}

fn CHAIN_ID() -> felt252 {
  'SN_MAIN'
}

fn BLOCK_TIMESTAMP() -> u64 {
  103374042_u64
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
  let mut signature = ArrayTrait::new();

  signature.append(3087695227963934782411443355974054330531912780999299366340358158172188798955);
  signature.append(2936225994738482437582710271434813684883822280549795930447609837161446520483);

  signature.span()
}

fn VOUCHER_SIGNATURE_2() -> Span<felt252> {
  let mut signature = ArrayTrait::new();

  signature.append(1567101499423974405132552866654397941796461247734137894210715097651800024623);
  signature.append(2406489013391837256524712835539748966140428060639388300020587314195643879538);

  signature.span()
}

fn VOUCHER_SIGNER_PUBLIC_KEY() -> felt252 {
  0x1f3c942d7f492a37608cde0d77b884a5aa9e11d2919225968557370ddb5a5aa
}

//
// ORDERS
//

fn ORDER_1() -> Order {
  Order {
    offer_item: Item::ERC1155(ERC1155_Item {
      token: starknet::contract_address_const::<'offer token 1'>(),
      identifier: u256 { low: 'offer id 1 low', high: 'offer id 1 high' },
      amount: u256 { low: 'offer qty 1 low', high: 'offer qty 1 high' },
    }),
    consideration_item: Item::ERC20(ERC20_Item {
      token: starknet::contract_address_const::<'consideration token 1'>(),
      amount: u256 { low: 'cons qty 1 low', high: 'cons qty 1 high' },
    }),
    end_time: BLOCK_TIMESTAMP() + 1,
    salt: 'salt 1',
  }
}

fn ORDER_SIGNER() -> starknet::ContractAddress {
  starknet::contract_address_const::<'order signer'>()
}

fn ORDER_SIGNATURE_1() -> Span<felt252> {
  let mut signature = ArrayTrait::new();

  signature.append(3237959813748497657862449788898314067503717469340761365314380802108721860625);
  signature.append(1398567426642486998238399998023820315663915285444134720048195322876322419898);

  signature.span()
}

fn ORDER_SIGNER_PUBLIC_KEY() -> felt252 {
  0x1766831fbcbc258a953dd0c0505ecbcd28086c673355c7a219bc031b710b0d6
}

// ADDRESSES

fn RECEIVER_DEPLOYED_ADDRESS() -> starknet::ContractAddress {
  starknet::contract_address_const::<0x2>()
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
