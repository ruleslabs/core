use array::SpanTrait;
use zeroable::Zeroable;
use rules_erc1155::utils::serde::SpanSerde;

// locals
use rules_tokens::constants;
use rules_tokens::utils::zeroable::{ U128Zeroable };
use super::interface::{ Token, TokenId, CardToken, PackToken, CardModel, Scarcity, Metadata };
use rules_tokens::typed_data::voucher::Voucher;
use rules_tokens::typed_data::order::Order;

#[abi]
trait RulesMessagesABI {
  #[view]
  fn voucher_signer() -> starknet::ContractAddress;

  #[external]
  fn consume_valid_voucher(voucher: Voucher, signature: Span<felt252>);

  #[external]
  fn consume_valid_order_from(from: starknet::ContractAddress, order: Order, signature: Span<felt252>);
}

#[contract]
mod RulesMessages {
  use array::{ ArrayTrait, SpanTrait };
  use zeroable::Zeroable;
  use rules_account::account;

  // locals
  use rules_erc1155::utils::serde::SpanSerde;
  use rules_tokens::utils::zeroable::{ U64Zeroable };
  use rules_tokens::typed_data::TypedDataTrait;
  use super::super::interface::{ IRulesMessages, Voucher, Order };

  // dispatchers
  use rules_account::account::{ AccountABIDispatcher, AccountABIDispatcherTrait };

  //
  // Storage
  //

  struct Storage {
    // message_hash -> consumed
    _consumed_messages: LegacyMap<felt252, bool>,

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

  impl RulesMessages of IRulesMessages {
    fn voucher_signer() -> starknet::ContractAddress {
      _voucher_signer::read()
    }

    fn consume_valid_voucher(voucher: Voucher, signature: Span<felt252>) {
      let voucher_signer_ = voucher_signer();

      // compute voucher message hash
      let hash = voucher.compute_hash_from(from: voucher_signer_);

      // assert voucher has not been already consumed and consume it
      assert(!_is_message_consumed(:hash), 'Voucher already consumed');
      _consume_message(:hash);

      // assert voucher signature is valid
      assert(_is_message_signature_valid(:hash, :signature, signer: voucher_signer_), 'Invalid voucher signature');
    }

    fn consume_valid_order_from(from: starknet::ContractAddress, order: Order, signature: Span<felt252>) {
      // compute voucher message hash
      let hash = order.compute_hash_from(:from);

      // assert order has not been already consumed and consume it
      assert(!_is_message_consumed(:hash), 'Order already consumed');
      _consume_message(:hash);

      // assert order signature is valid
      assert(_is_message_signature_valid(:hash, :signature, signer: from), 'Invalid order signature');

      // assert end time is not passed
      if (order.end_time.is_non_zero()) {
        let block_timestamp = starknet::get_block_timestamp();

        assert(block_timestamp <= order.end_time, 'Order ended');
      }
    }
  }

  // Getters

  #[view]
  fn voucher_signer() -> starknet::ContractAddress {
    RulesMessages::voucher_signer()
  }

  // Voucher

  #[external]
  fn consume_valid_voucher(voucher: Voucher, signature: Span<felt252>) {
    RulesMessages::consume_valid_voucher(:voucher, :signature);
  }

  // Order

  #[external]
  fn consume_valid_order_from(from: starknet::ContractAddress, order: Order, signature: Span<felt252>) {
    RulesMessages::consume_valid_order_from(:from, :order, :signature);
  }

  //
  // Internals
  //

  // Init

  #[internal]
  fn initializer(voucher_signer_: starknet::ContractAddress) {
    _voucher_signer::write(voucher_signer_);
  }

  // Messages

  #[internal]
  fn _is_message_signature_valid(hash: felt252, signature: Span<felt252>, signer: starknet::ContractAddress) -> bool {
    // check signature
    let signer_account = AccountABIDispatcher { contract_address: signer };
    signer_account.is_valid_signature(message: hash, :signature) == account::interface::ERC1271_VALIDATED
  }

  #[internal]
  fn _is_message_consumed(hash: felt252) -> bool {
    _consumed_messages::read(hash)
  }

  #[internal]
  fn _consume_message(hash: felt252) {
    _consumed_messages::write(hash, true);
  }
}
