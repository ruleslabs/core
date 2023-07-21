#[starknet::contract]
mod Receiver {
  use rules_account::account::interface::ISRC6_ID;

  //
  // Storage
  //

  #[storage]
  struct Storage { }

  //
  // Constructor
  //

  #[constructor]
  fn constructor(ref self: ContractState) { }

  //
  // impls
  //

  #[external(v0)]
  fn supports_interface(self: @ContractState, interface_id: felt252) -> bool {
    interface_id == ISRC6_ID
  }
}
