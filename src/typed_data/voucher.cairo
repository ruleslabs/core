use traits::Into;
use box::BoxTrait;

// locals
use super::constants;
use super::typed_data::Message;

#[derive(Serde, Drop)]
struct Voucher {
  receiver: starknet::ContractAddress,
  token_id: u256,
  amount: u256,
  nonce: felt252,
}

impl VoucherMessage of Message<Voucher> {
  #[inline(always)]
  fn compute_hash(self: @Voucher) -> felt252 {
    let mut hash = pedersen(0, constants::VOUCHER_TYPE_HASH);
    hash = pedersen(hash, (*self.receiver).into());
    hash = pedersen(hash, hash_u256(*self.token_id));
    hash = pedersen(hash, hash_u256(*self.amount));
    hash = pedersen(hash, *self.nonce);

    pedersen(hash, 5)
  }
}

fn hash_u256(n: u256) -> felt252 {
  let mut hash = pedersen(0, constants::U256_TYPE_HASH);
  hash = pedersen(hash, n.low.into());
  hash = pedersen(hash, n.high.into());

  pedersen(hash, 3)
}
