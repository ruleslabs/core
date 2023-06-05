use array::{ ArrayTrait, SpanTrait };
use traits::{ Into, TryInto };
use option::OptionTrait;
use starknet::{
  StorageAccess,
  storage_address_from_base_and_offset,
  storage_read_syscall,
  storage_write_syscall,
  SyscallResult,
  StorageBaseAddress,
};

// locals
use rules_tokens::core::interface::Scarcity;
use rules_tokens::core::interface::CardModel;

impl ScarcityStorageAccess of StorageAccess::<Scarcity> {
  fn read(address_domain: u32, base: StorageBaseAddress) -> SyscallResult::<Scarcity> {
    Result::Ok(
      Scarcity {
        max_supply: storage_read_syscall(
          address_domain, storage_address_from_base_and_offset(base, 0_u8)
        )?.try_into().unwrap(),
        name: storage_read_syscall(
          address_domain, storage_address_from_base_and_offset(base, 1_u8)
        )?,
      }
    )
  }

  fn write(address_domain: u32, base: StorageBaseAddress, value: Scarcity) -> SyscallResult::<()> {
    storage_write_syscall(address_domain, storage_address_from_base_and_offset(base, 0_u8), value.max_supply.into())?;

    storage_write_syscall(address_domain, storage_address_from_base_and_offset(base, 1_u8), value.name)
  }
}

impl CardModelStorageAccess of StorageAccess::<CardModel> {
  fn read(address_domain: u32, base: StorageBaseAddress) -> SyscallResult::<CardModel> {
    Result::Ok(
      CardModel {
        artist_name: storage_read_syscall(
          address_domain, storage_address_from_base_and_offset(base, 0_u8)
        )?,
        season: storage_read_syscall(
          address_domain, storage_address_from_base_and_offset(base, 1_u8)
        )?,
        scarcity: storage_read_syscall(
          address_domain, storage_address_from_base_and_offset(base, 2_u8)
        )?,
      }
    )
  }

  fn write(address_domain: u32, base: StorageBaseAddress, value: CardModel) -> SyscallResult::<()> {
    storage_write_syscall(address_domain, storage_address_from_base_and_offset(base, 0_u8), value.artist_name)?;

    storage_write_syscall(address_domain, storage_address_from_base_and_offset(base, 1_u8), value.season)?;

    storage_write_syscall(address_domain, storage_address_from_base_and_offset(base, 1_u8), value.scarcity)
  }
}
