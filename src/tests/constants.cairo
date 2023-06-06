use array::ArrayTrait;

// locals
use rules_tokens::core::data::{ RulesData, CardModelTrait, ScarcityTrait };
use rules_tokens::core::interface::{ CardModel, Scarcity, Metadata, METADATA_MULTIHASH_IDENTIFIER };
use rules_tokens::typed_data::voucher::Voucher;

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
    artist_name: 'King ju',
    season: 1,
    scarcity_id: 0,
  }
}

fn CARD_MODEL_2() -> CardModel {
  CardModel {
    artist_name: 'Double P',
    season: 1995,
    scarcity_id: 0,
  }
}

fn CARD_MODEL_ID() -> u128 {
  0x03096242471061f433ba6a63130aa948
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

fn VOUCHER_1() -> Voucher {
  Voucher {
    receiver: starknet::contract_address_const::<'receiver 1'>(),
    token_id: u256 { low: 'token id 1 low', high: 'token id 1 high' },
    amount: u256 { low: 'amount 1 low', high: 'amount 1 high' },
    nonce: 1,
  }
}

// valid card voucher
fn VOUCHER_2() -> Voucher {
  Voucher {
    receiver: RECEIVER_DEPLOYED_ADDRESS(),
    token_id: u256 { low: CARD_MODEL_2().id(), high: 0x42 },
    amount: u256 { low: 1, high: 0 },
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

fn VOUCHER_SIGNATURE_2() -> Span<felt252> {
  let mut signature = ArrayTrait::new();

  signature.append(2305388663398077516669640470607532907931150161441669616184452610369318970150);
  signature.append(3165717456559673604699389572072320190973872032067044902297644067641220914862);

  signature.span()
}

fn VOUCHER_SIGNER_PUBLIC_KEY() -> felt252 {
  883045738439352841478194533192765345509759306772397516907181243450667673002
}

fn RECEIVER_DEPLOYED_ADDRESS() -> starknet::ContractAddress {
  starknet::contract_address_const::<0x3>()
}
