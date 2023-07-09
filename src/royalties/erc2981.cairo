use core::traits::TryInto;
const IERC2981_ID: u32 = 0x2a55205a;

const HUNDRED_PERCENT: u16 = 10000;

#[starknet::interface]
trait IERC2981<TContractState> {
  fn royalty_info(self: @TContractState, token_id: u256, sale_price: u256) -> (starknet::ContractAddress, u256);
}

#[starknet::contract]
mod ERC2981 {
  use traits::{ Into, TryInto, DivRem };
  use zeroable::Zeroable;
  use integer::{ U128DivRem, u128_try_as_non_zero, U16Zeroable, U128Zeroable };
  use option::OptionTrait;

  // locals
  use super::HUNDRED_PERCENT;
  use rules_tokens::royalties::erc2981;
  use rules_tokens::introspection::erc165;
  use rules_tokens::introspection::erc165::{ ERC165, IERC165 };

  //
  // Storage
  //

  #[storage]
  struct Storage {
    _royalties_receiver: starknet::ContractAddress,
    _royalties_percentage: u16,
  }

  //
  // IERC2981 impl
  //

  #[external(v0)]
  impl IERC2981Impl of erc2981::IERC2981<ContractState> {
    fn royalty_info(self: @ContractState, token_id: u256, sale_price: u256) -> (starknet::ContractAddress, u256) {
      assert(sale_price.high.is_zero(), 'Unsupported sale price');

      let royalties_receiver_ = self._royalties_receiver.read();
      let royalties_percentage_ = self._royalties_percentage.read();

      let mut royalty_amount = 0_u256;

      if (royalties_percentage_.is_non_zero()) {
        let (q, r) = DivRem::<u128>::div_rem(
          sale_price.low,
          u128_try_as_non_zero(
            Into::<u16, felt252>::into(HUNDRED_PERCENT / royalties_percentage_).try_into().unwrap()
          ).unwrap()
        );
        royalty_amount = u256 { low: q, high: 0 };

        // if there is a remainder, we round up
        if (r.is_non_zero()) {
          royalty_amount += 1;
        }
      }

      (royalties_receiver_, royalty_amount)
    }
  }

  #[external(v0)]
  impl IERC165Impl of erc165::IERC165<ContractState> {
    fn supports_interface(self: @ContractState, interface_id: u32) -> bool {
      if (interface_id == erc2981::IERC2981_ID) {
        true
      } else {
        let erc165_self = ERC165::unsafe_new_contract_state();

        erc165_self.supports_interface(:interface_id)
      }
    }
  }

  //
  // Helpers
  //

  #[generate_trait]
  impl HelperImpl of HelperTrait {
    fn _set_royalty_receiver(ref self: ContractState, new_receiver: starknet::ContractAddress) {
      self._royalties_receiver.write(new_receiver);
    }

    fn _set_royalty_percentage(ref self: ContractState, new_percentage: u16) {
      assert(new_percentage <= HUNDRED_PERCENT, 'Invalid percentage');
      self._royalties_percentage.write(new_percentage);
    }
  }
}
