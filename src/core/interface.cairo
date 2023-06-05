use array::SpanTrait;

use rules_core::typed_data::voucher::Voucher;
use rules_core::utils::serde::SpanSerde;

#[abi]
trait IRulesCore {
  fn voucher_signer() -> starknet::ContractAddress;

  fn redeem_voucher(voucher: Voucher, signature: Span<felt252>);
}
