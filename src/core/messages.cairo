use array::{ SpanTrait, SpanSerde };
use zeroable::Zeroable;
use messages::typed_data::typed_data::Domain;

// locals
use super::voucher::Voucher;

fn DOMAIN() -> Domain {
  Domain {
    name: 'Rules',
    version: '1.1',
  }
}

#[starknet::interface]
trait RulesMessagesABI<TContractState> {
  fn voucher_signer(self: @TContractState) -> starknet::ContractAddress;

  fn consume_valid_voucher(ref self: TContractState, voucher: Voucher, signature: Span<felt252>);
}

#[starknet::contract]
mod RulesMessages {
  use array::{ ArrayTrait, SpanTrait, SpanSerde };
  use zeroable::Zeroable;
  use rules_account::account;
  use messages::messages::Messages;
  use messages::messages::Messages::{ InternalTrait as MessagesInternalTrait };
  use messages::typed_data::TypedDataTrait;

  // locals
  use super::DOMAIN;
  use rules_utils::utils::zeroable::U64Zeroable;
  use rules_tokens::core;
  use super::super::interface::{ Voucher, IRulesMessages };

  // dispatchers
  use rules_account::account::{ AccountABIDispatcher, AccountABIDispatcherTrait };

  //
  // Storage
  //

  #[storage]
  struct Storage {
    _voucher_signer: starknet::ContractAddress,
  }

  //
  // Constructor
  //

  #[constructor]
  fn constructor(ref self: ContractState, voucher_signer_: starknet::ContractAddress) {
    self.initializer(:voucher_signer_);
  }

  //
  // impls
  //

  #[external(v0)]
  impl IRulesMessagesImpl of core::interface::IRulesMessages<ContractState> {
    fn voucher_signer(self: @ContractState) -> starknet::ContractAddress {
      self._voucher_signer.read()
    }

    fn consume_valid_voucher(ref self: ContractState, voucher: Voucher, signature: Span<felt252>) {
      let mut messages_self = Messages::unsafe_new_contract_state();

      let voucher_signer_ = self.voucher_signer();

      // compute voucher message hash
      let hash = voucher.compute_hash_from(from: voucher_signer_, domain: DOMAIN());

      // assert voucher has not been already consumed and consume it
      assert(!messages_self._is_message_consumed(:hash), 'Voucher already consumed');
      messages_self._consume_message(:hash);

      // assert voucher signature is valid
      assert(
        messages_self._is_message_signature_valid(:hash, :signature, signer: voucher_signer_),
        'Invalid voucher signature'
      );
    }
  }

  //
  // Internals
  //

  #[generate_trait]
  impl InternalImpl of InternalTrait {
    // Init

    fn initializer(ref self: ContractState, voucher_signer_: starknet::ContractAddress) {
      self._voucher_signer.write(voucher_signer_);
    }
  }
}
