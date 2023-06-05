use rules_core::typed_data::voucher::Voucher;

#[abi]
trait RulesCoreABI {
  #[view]
  fn voucher_signer() -> starknet::ContractAddress;

  #[external]
  fn redeem_voucher(voucher: Voucher, signature: Array<felt252>);
}

#[contract]
mod RulesCore {
  use array::Array;
  use rules_erc1155::erc1155::ERC1155;
  use rules_account::account;

  // locals
  use rules_core::typed_data::TypedDataTrait;
  use super::Voucher;
  use super::super::interface::IRulesCore;

  // dispatchers
  use rules_account::account::{ AccountABIDispatcher, AccountABIDispatcherTrait };

  //
  // Storage
  //

  struct Storage {
    // (receiver, nonce) -> (consumed)
    _consumed_vouchers: LegacyMap<(starknet::ContractAddress, felt252), bool>,
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
    fn voucher_signer() -> starknet::ContractAddress {
      _voucher_signer::read()
    }

    fn redeem_voucher(voucher: Voucher, signature: Array<felt252>) {
      // check nonce
      assert(!_is_voucher_consumed(:voucher), 'Voucher already consumed');

      // check signature
      let voucher_signer_ = _voucher_signer::read();
      assert(_is_voucher_signature_valid(:voucher, :signature, signer: voucher_signer_), 'Invalid voucher signature');
    }
  }

  // ERC1155

  // Getters

  #[view]
  fn voucher_signer() -> starknet::ContractAddress {
    RulesCore::voucher_signer()
  }

  // Voucher

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
  fn _is_voucher_signature_valid(
    voucher: Voucher,
    signature: Array<felt252>,
    signer: starknet::ContractAddress
  ) -> bool {
    // compute voucher message hash
    let hash = voucher.compute_hash_from(from: signer);

    // check signature
    let signer_account = AccountABIDispatcher { contract_address: signer };
    signer_account.is_valid_signature(message: hash, :signature) == account::interface::ERC1271_VALIDATED
  }

  #[internal]
  fn _is_voucher_consumed(voucher: Voucher) -> bool {
    _consumed_vouchers::read((voucher.receiver, voucher.nonce))
  }

  #[internal]
  fn _consume_voucher(voucher: Voucher) {
    _consumed_vouchers::write((voucher.receiver, voucher.nonce), true);
  }
}

// add scarcity for season
// create card model for scarcity and season
