use array::SpanTrait;
use zeroable::Zeroable;
use rules_utils::utils::serde::SpanSerde;
use messages::typed_data::typed_data::Domain;

// locals
use super::voucher::Voucher;

fn DOMAIN() -> Domain {
  Domain {
    name: 'Rules',
    version: '1.1',
  }
}

#[abi]
trait RulesMessagesABI {
  #[view]
  fn voucher_signer() -> starknet::ContractAddress;

  #[external]
  fn consume_valid_voucher(voucher: Voucher, signature: Span<felt252>);
}

#[contract]
mod RulesMessages {
  use array::{ ArrayTrait, SpanTrait };
  use zeroable::Zeroable;
  use rules_account::account;
  use messages::messages::Messages;
  use messages::typed_data::TypedDataTrait;

  // locals
  use super::DOMAIN;
  use rules_utils::utils::serde::SpanSerde;
  use rules_utils::utils::zeroable::U64Zeroable;
  use super::super::interface::{ IRulesMessages, Voucher };

  // dispatchers
  use rules_account::account::{ AccountABIDispatcher, AccountABIDispatcherTrait };

  //
  // Storage
  //

  struct Storage {
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
      let hash = voucher.compute_hash_from(from: voucher_signer_, domain: DOMAIN());

      // assert voucher has not been already consumed and consume it
      assert(!Messages::_is_message_consumed(:hash), 'Voucher already consumed');
      Messages::_consume_message(:hash);

      // assert voucher signature is valid
      assert(
        Messages::_is_message_signature_valid(:hash, :signature, signer: voucher_signer_),
        'Invalid voucher signature'
      );
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

  //
  // Internals
  //

  // Init

  #[internal]
  fn initializer(voucher_signer_: starknet::ContractAddress) {
    _voucher_signer::write(voucher_signer_);
  }
}
