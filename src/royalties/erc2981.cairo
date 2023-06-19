use core::traits::TryInto;
const IERC2981_ID: u32 = 0x2a55205a;

const HUNDRED_PERCENT: u16 = 10000;

#[abi]
trait IERC2981 {
  fn supports_interface(interface_id: u32) -> bool;

  fn royalty_info(token_id: u256, sale_price: u256) -> (starknet::ContractAddress, u256);
}

#[contract]
mod ERC2981 {
  use traits::{ Into, TryInto, DivRem };
  use zeroable::Zeroable;
  use integer::{ U128DivRem, u128_try_as_non_zero };
  use option::OptionTrait;

  use super::HUNDRED_PERCENT;
  use rules_tokens::royalties::erc2981;
  use rules_tokens::utils::zeroable::{ U16Zeroable, U128Zeroable };

  //
  // Storage
  //

  struct Storage {
    _royalties_receiver: starknet::ContractAddress,
    _royalties_percentage: u16,
  }

  //
  // Impl
  //

  impl ERC2981 of erc2981::IERC2981 {
    fn supports_interface(interface_id: u32) -> bool {
      if interface_id == erc2981::IERC2981_ID {
        true
      } else {
        false
      }
    }

    fn royalty_info(token_id: u256, sale_price: u256) -> (starknet::ContractAddress, u256) {
      assert(sale_price.high.is_zero(), 'Unsupported sale price');

      let royalties_receiver_ = _royalties_receiver::read();
      let royalties_percentage_ = _royalties_percentage::read();

      let mut royalty_amount = 0_u256;

      if (royalties_percentage_.is_non_zero()) {
        let (q, r) = DivRem::<u128>::div_rem(
          sale_price.low,
          u128_try_as_non_zero(
            Into::<u16, felt252>::into(HUNDRED_PERCENT / royalties_percentage_).try_into().unwrap()
          ).unwrap()
        );
        royalty_amount = u256 { low: q + r, high: 0 };
      }

      (royalties_receiver_, royalty_amount)
    }
  }

  #[view]
  fn supports_interface(interface_id: u32) -> bool {
    ERC2981::supports_interface(interface_id)
  }

  #[view]
  fn royalty_info(token_id: u256, sale_price: u256) -> (starknet::ContractAddress, u256) {
    ERC2981::royalty_info(:token_id, :sale_price)
  }

  //
  // Internals
  //

  #[internal]
  fn _set_royalty_receiver(new_receiver: starknet::ContractAddress) {
    _royalties_receiver::write(new_receiver);
  }

  #[internal]
  fn _set_royalty_percentage(new_percentage: u16) {
    assert(new_percentage <= HUNDRED_PERCENT, 'Invalid percentage');
    _royalties_percentage::write(new_percentage);
  }
}
