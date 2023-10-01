use traits::Into;
use box::BoxTrait;
use messages::typed_data::common::hash_u256;
use messages::typed_data::Message;

// sn_keccak('Voucher(receiver:felt252,tokenId:u256,amount:u256,salt:felt252)u256(low:felt252,high:felt252)')
const VOUCHER_TYPE_HASH: felt252 = 0x2b7b26b9be07bb06826bb14ffeb28e910317886010a72720cce19e1974bd232;

#[derive(Serde, Copy, Drop)]
struct Voucher {
  receiver: starknet::ContractAddress,
  token_id: u256,
  amount: u256,
  salt: felt252,
}

impl VoucherMessage of Message<Voucher> {
  #[inline(always)]
  fn compute_hash(self: @Voucher) -> felt252 {
    let mut hash = pedersen::pedersen(0, VOUCHER_TYPE_HASH);
    hash = pedersen::pedersen(hash, (*self.receiver).into());
    hash = pedersen::pedersen(hash, hash_u256(*self.token_id));
    hash = pedersen::pedersen(hash, hash_u256(*self.amount));
    hash = pedersen::pedersen(hash, *self.salt);

    pedersen::pedersen(hash, 5)
  }
}
