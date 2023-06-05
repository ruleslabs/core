use traits::Into;
use box::BoxTrait;

use super::constants;

trait Message<T> {
  fn compute_hash(self: @T) -> felt252;
}

trait TypedDataTrait<T> {
  fn compute_hash_from(self: @T, from: starknet::ContractAddress) -> felt252;
}

impl TypedDataImpl<T, impl TMessage: Message<T>> of TypedDataTrait<T> {
  #[inline(always)]
  fn compute_hash_from(self: @T, from: starknet::ContractAddress) -> felt252 {
    let tx_info = starknet::get_tx_info().unbox();

    let prefix = constants::STARKNET_MESSAGE_PREFIX;
    let domain_hash = hash_domain(tx_info.chain_id);
    let account = from.into();
    let message_hash = self.compute_hash();

    let mut hash = pedersen(0, prefix);
    hash = pedersen(hash, domain_hash);
    hash = pedersen(hash, account);
    hash = pedersen(hash, message_hash);

    pedersen(hash, 4)
  }
}

fn hash_domain(chain_id: felt252) -> felt252 {
  let mut hash = pedersen(0, constants::STARKNET_DOMAIN_TYPE_HASH);
  hash = pedersen(hash, constants::STARKNET_DOMAIN_NAME);
  hash = pedersen(hash, chain_id);
  hash = pedersen(hash, constants::STARKNET_DOMAIN_VERSION);

  pedersen(hash, 4)
}
