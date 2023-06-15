use traits::Into;
use box::BoxTrait;
use array::ArrayTrait;
use serde::Serde;

// locals
use super::constants;
use super::common::hash_u256;
use super::typed_data::Message;

#[derive(Serde, Copy, Drop)]
struct Order {
  offer_item: Item,
  consideration_item: Item,
  end_time: u64,
  salt: felt252,
}

#[derive(Serde, Copy, Drop)]
struct ERC20_Item {
  token: starknet::ContractAddress,
  amount: u256,
}

#[derive(Serde, Copy, Drop)]
struct ERC1155_Item {
  token: starknet::ContractAddress,
  identifier: u256,
  amount: u256,
}

#[derive(Serde, Copy, Drop)]
enum Item {
  ERC20: ERC20_Item,
  ERC1155: ERC1155_Item,
}

impl OrderMessage of Message<Order> {
  #[inline(always)]
  fn compute_hash(self: @Order) -> felt252 {
    let mut hash = pedersen(0, constants::ORDER_TYPE_HASH);
    hash = pedersen(hash, hash_item(*self.offer_item));
    hash = pedersen(hash, hash_item(*self.consideration_item));
    hash = pedersen(hash, (*self).end_time.into());
    hash = pedersen(hash, *self.salt);

    pedersen(hash, 5)
  }
}

fn hash_item(item: Item) -> felt252 {
  let mut hash = pedersen(0, constants::ITEM_TYPE_HASH);

  match item {
    Item::ERC20(erc_20_item) => {
      hash = pedersen(hash, erc_20_item.token.into());
      hash = pedersen(hash, hash_u256(u256 { low: 0, high: 0 }));
      hash = pedersen(hash, hash_u256(erc_20_item.amount));
      hash = pedersen(hash, 1);
    },
    Item::ERC1155(erc_1155_item) => {
      hash = pedersen(hash, erc_1155_item.token.into());
      hash = pedersen(hash, hash_u256(erc_1155_item.identifier));
      hash = pedersen(hash, hash_u256(erc_1155_item.amount));
      hash = pedersen(hash, 3);
    },
  }

  pedersen(hash, 5)
}
