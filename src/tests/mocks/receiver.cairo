#[starknet::contract]
mod Receiver {

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
  fn supports_interface(self: @ContractState, interface_id: u32) -> bool {
    if (interface_id == rules_account::account::interface::IACCOUNT_ID) {
      true
    } else {
      false
    }
  }
}
