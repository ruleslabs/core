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
    ScarcityStorageAccess::read_at_offset_internal(:address_domain, :base, offset: 0)
  }

  fn write(address_domain: u32, base: StorageBaseAddress, value: Scarcity) -> SyscallResult::<()> {
    ScarcityStorageAccess::write_at_offset_internal(:address_domain, :base, offset: 0, :value)
  }

  fn read_at_offset_internal(address_domain: u32, base: StorageBaseAddress, offset: u8) -> SyscallResult::<Scarcity> {
    Result::Ok(
      Scarcity {
        max_supply: storage_read_syscall(
          address_domain, storage_address_from_base_and_offset(base, offset)
        )?.try_into().unwrap(),
        name: storage_read_syscall(
          address_domain, storage_address_from_base_and_offset(base, offset + 1)
        )?,
      }
    )
  }

  fn write_at_offset_internal(
    address_domain: u32,
    base: StorageBaseAddress,
    offset: u8,
    value: Scarcity
  ) -> SyscallResult::<()> {
    storage_write_syscall(
      address_domain,
      storage_address_from_base_and_offset(base, offset),
      value.max_supply.into()
    )?;

    storage_write_syscall(address_domain, storage_address_from_base_and_offset(base, offset + 1), value.name)
  }

  fn size_internal(value: Scarcity) -> u8 {
    2
  }
}

// Card Model

impl CardModelStorageAccess of StorageAccess::<CardModel> {
  fn read(address_domain: u32, base: StorageBaseAddress) -> SyscallResult::<CardModel> {
    CardModelStorageAccess::read_at_offset_internal(:address_domain, :base, offset: 0)
  }

  fn write(address_domain: u32, base: StorageBaseAddress, value: CardModel) -> SyscallResult::<()> {
    CardModelStorageAccess::write_at_offset_internal(:address_domain, :base, offset: 0, :value)
  }

  fn read_at_offset_internal(address_domain: u32, base: StorageBaseAddress, offset: u8) -> SyscallResult<CardModel> {
    Result::Ok(
      CardModel {
        artist_name: storage_read_syscall(
          address_domain, storage_address_from_base_and_offset(base, offset)
        )?,
        season: storage_read_syscall(
          address_domain, storage_address_from_base_and_offset(base, offset + 1)
        )?,
        scarcity_id: storage_read_syscall(
          address_domain, storage_address_from_base_and_offset(base, offset + 2)
        )?,
      }
    )
  }

  fn write_at_offset_internal(
    address_domain: u32,
    base: StorageBaseAddress,
    offset: u8,
    value: CardModel
  ) -> SyscallResult::<()> {
    storage_write_syscall(address_domain, storage_address_from_base_and_offset(base, offset), value.artist_name)?;

    storage_write_syscall(address_domain, storage_address_from_base_and_offset(base, offset + 1), value.season)?;

    storage_write_syscall(address_domain, storage_address_from_base_and_offset(base, offset + 2), value.scarcity_id)
  }

  fn size_internal(value: CardModel) -> u8 {
    3
  }
}

// Metadata

impl MetadataStorageAccess of StorageAccess::<Metadata> {
  fn read(address_domain: u32, base: StorageBaseAddress) -> SyscallResult::<Metadata> {
    MetadataStorageAccess::read_at_offset_internal(:address_domain, :base, offset: 0)
  }

  fn write(address_domain: u32, base: StorageBaseAddress, value: Metadata) -> SyscallResult::<()> {
    MetadataStorageAccess::write_at_offset_internal(:address_domain, :base, offset: 0, :value)
  }

  fn read_at_offset_internal(address_domain: u32, base: StorageBaseAddress, offset: u8) -> SyscallResult<Metadata> {
    Result::Ok(
      Metadata {
        multihash_identifier: storage_read_syscall(
          address_domain, storage_address_from_base_and_offset(base, offset)
        )?.try_into().unwrap(),
        hash: u256 {
          low: storage_read_syscall(
            address_domain, storage_address_from_base_and_offset(base, offset + 1)
          )?.try_into().unwrap(),
          high: storage_read_syscall(
            address_domain, storage_address_from_base_and_offset(base, offset + 2)
          )?.try_into().unwrap(),
        }
      }
    )
  }

  fn write_at_offset_internal(
    address_domain: u32,
    base: StorageBaseAddress,
    offset: u8,
    value: Metadata
  ) -> SyscallResult<()> {
    storage_write_syscall(
      address_domain,
      storage_address_from_base_and_offset(base, offset),
      value.multihash_identifier.into()
    )?;

    storage_write_syscall(
      address_domain,
      storage_address_from_base_and_offset(base, offset + 1),
      value.hash.low.into()
    )?;

    storage_write_syscall(
      address_domain,
      storage_address_from_base_and_offset(base, offset + 2),
      value.hash.high.into()
    )
  }

  fn size_internal(value: Metadata) -> u8 {
    3
  }
}
