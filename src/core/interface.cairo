use array::Array;

use rules_core::typed_data::voucher::Voucher;

#[abi]
trait IRulesCore {
  fn redeem_voucher(voucher: Voucher, signature: Array<felt252>);
}
