use array::SpanTrait;
use rules_core::utils::serde::SpanSerde;

// locals
use rules_core::typed_data::voucher::Voucher;

#[abi]
trait RulesCoreABI {
  #[view]
  fn voucher_signer() -> starknet::ContractAddress;

  #[external]
  fn redeem_voucher(voucher: Voucher, signature: Span<felt252>);
}

#[contract]
mod RulesCore {
  use array::SpanTrait;
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
  fn constructor(uri_: Span<felt252>, voucher_signer_: starknet::ContractAddress) {
    ERC1155::initializer(:uri_);
    initializer(:voucher_signer_);
  }

  //
  // impls
  //

  impl RulesCore of IRulesCore {
    fn voucher_signer() -> starknet::ContractAddress {
      _voucher_signer::read()
    }

    fn redeem_voucher(voucher: Voucher, signature: Span<felt252>) {
      // assert voucher has not been already consumed and consume it
      assert(!_is_voucher_consumed(:voucher), 'Voucher already consumed');
      _consume_voucher(:voucher);

      // assert voucher signature is valid
      let voucher_signer_ = _voucher_signer::read();
      assert(_is_voucher_signature_valid(:voucher, :signature, signer: voucher_signer_), 'Invalid voucher signature');

      // mint token id
      _mint(to: voucher.receiver, token_id: voucher.token_id, amount: voucher.amount);
    }
  }

  // Getters

  #[view]
  fn uri(tokenId: u256) -> Span<felt252> {
    ERC1155::uri(:tokenId)
  }

  #[view]
  fn voucher_signer() -> starknet::ContractAddress {
    RulesCore::voucher_signer()
  }

  // ERC165

  #[view]
  fn supports_interface(interface_id: u32) -> bool {
    ERC1155::supports_interface(:interface_id)
  }

  // Balance

  #[view]
  fn balance_of(account: starknet::ContractAddress, id: u256) -> u256 {
    ERC1155::balance_of(:account, :id)
  }

  #[view]
  fn balance_of_batch(accounts: Span<starknet::ContractAddress>, ids: Span<u256>) -> Array<u256> {
    ERC1155::balance_of_batch(:accounts, :ids)
  }

  // Approval

  #[external]
  fn set_approval_for_all(operator: starknet::ContractAddress, approved: bool) {
    ERC1155::set_approval_for_all(:operator, :approved)
  }

  #[view]
  fn is_approved_for_all(account: starknet::ContractAddress, operator: starknet::ContractAddress) -> bool {
    ERC1155::is_approved_for_all(:account, :operator)
  }

  // Voucher

  #[external]
  fn redeem_voucher(voucher: Voucher, signature: Span<felt252>) {
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

  // Mint

  fn _mint(to: starknet::ContractAddress, token_id: u256, amount: u256) {
    // TODO
  }

  // Voucher

  #[internal]
  fn _is_voucher_signature_valid(
    voucher: Voucher,
    signature: Span<felt252>,
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
