#[starknet::contract]
mod Signer {
  use array::ArrayTrait;

  // locals
  use rules_account::account;
  use rules_account::account::Account;

  //
  // Storage
  //

  #[storage]
  struct Storage {
    _public_key: felt252,
  }

  //
  // Constructor
  //

  #[constructor]
  fn constructor(ref self: ContractState, public_key_: felt252) {
    self._public_key.write(public_key_);
  }

  //
  // impl
  //

  #[external(v0)]
  fn is_valid_signature(self: @ContractState, message: felt252, signature: Array<felt252>) -> u32 {
    let account_self = Account::unsafe_new_contract_state();

    if (
      Account::HelperImpl::_is_valid_signature(
        self: @account_self,
        :message,
        signature: signature.span(),
        public_key: self._public_key.read()
      )
    ) {
      account::interface::ERC1271_VALIDATED
    } else {
      0_u32
    }
  }
}
