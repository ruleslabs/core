#[contract]
mod RulesCore {
  use array::Array;
  use rules_account::account::{ AccountABIDispatcher, AccountABIDispatcherTrait };
  use rules_erc1155::erc1155::ERC1155;

  use rules_core::typed_data::voucher::Voucher;
  use rules_core::typed_data::TypedDataTrait;

  use super::super::interface::IRulesCore;

  //
  // Storage
  //

  struct Storage {
    // (receiver, nonce) -> (consumed)
    _consumed_vouchers_nonce: LegacyMap<(starknet::ContractAddress, felt252), bool>,
    _voucher_signer: starknet::ContractAddress,
  }

  //
  // Constructor
  //

  #[constructor]
  fn constructor(voucher_signer_: starknet::ContractAddress) {
    initializer(:voucher_signer_);
  }

  //
  // impls
  //

  impl RulesCore of IRulesCore {
    fn redeem_voucher(voucher: Voucher, signature: Array<felt252>) {
      _consume_voucher_nonce(:voucher);
      _verify_voucher_signature(:voucher, :signature);
    }
  }

  #[external]
  fn redeem_voucher(voucher: Voucher, signature: Array<felt252>) {
    RulesCore::redeem_voucher(:voucher, :signature);
  }

  //
  // Internals
  //

  // Init

  #[internal]
  fn initializer(voucher_signer_: starknet::ContractAddress) {
    _voucher_signer::write(voucher_signer_);
  }

  // Voucher

  #[internal]
  fn _verify_voucher_signature(voucher: Voucher, signature: Array<felt252>) {
    let voucher_signer_ = _voucher_signer::read();

    // compute voucher message hash
    let hash = voucher.compute_hash_from(from: voucher_signer_);

    // validate signature
    let voucher_signer_account = AccountABIDispatcher { contract_address: voucher_signer_ };
    voucher_signer_account.is_valid_signature(message: hash, :signature);
  }

  // assert nonce has not been already consumed and consume it
  #[internal]
  fn _consume_voucher_nonce(voucher: Voucher) {
    assert(!_consumed_vouchers_nonce::read((voucher.receiver, voucher.nonce)), 'Voucher already consumed');
    _consumed_vouchers_nonce::write((voucher.receiver, voucher.nonce), true);
  }
}

// add scarcity for season
// create card model for scarcity and season
