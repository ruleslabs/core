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
use rules_tokens::core::interface::{ Scarcity, CardModel, Metadata };

// Scarcity

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

// Card Model

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
        scarcity_id: storage_read_syscall(
          address_domain, storage_address_from_base_and_offset(base, 2_u8)
        )?,
      }
    )
  }

  fn write(address_domain: u32, base: StorageBaseAddress, value: CardModel) -> SyscallResult::<()> {
    storage_write_syscall(address_domain, storage_address_from_base_and_offset(base, 0_u8), value.artist_name)?;

    storage_write_syscall(address_domain, storage_address_from_base_and_offset(base, 1_u8), value.season)?;

    storage_write_syscall(address_domain, storage_address_from_base_and_offset(base, 2_u8), value.scarcity_id)
  }
}

// Metadata

impl MetadataStorageAccess of StorageAccess::<Metadata> {
  fn read(address_domain: u32, base: StorageBaseAddress) -> SyscallResult::<Metadata> {
    Result::Ok(
      Metadata {
        multihash_identifier: storage_read_syscall(
          address_domain, storage_address_from_base_and_offset(base, 0_u8)
        )?.try_into().unwrap(),
        hash: u256 {
          low: storage_read_syscall(
            address_domain, storage_address_from_base_and_offset(base, 1_u8)
          )?.try_into().unwrap(),
          high: storage_read_syscall(
            address_domain, storage_address_from_base_and_offset(base, 2_u8)
          )?.try_into().unwrap(),
        }
      }
    )
  }

  fn write(address_domain: u32, base: StorageBaseAddress, value: Metadata) -> SyscallResult::<()> {
    storage_write_syscall(
      address_domain,
      storage_address_from_base_and_offset(base, 0_u8),
      value.multihash_identifier.into()
    )?;

    storage_write_syscall(address_domain, storage_address_from_base_and_offset(base, 1_u8), value.hash.low.into())?;

    storage_write_syscall(address_domain, storage_address_from_base_and_offset(base, 2_u8), value.hash.high.into())
  }
}
