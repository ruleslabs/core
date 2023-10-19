use zeroable::Zeroable;

// locals
use rules_tokens::core::interface::{ Metadata };
use super::partial_eq::{ MetadataEq };

impl MetadataZeroable of Zeroable<Metadata> {
  fn zero() -> Metadata {
    Metadata {
      hash: array![].span(),
    }
  }

  #[inline(always)]
  fn is_zero(self: Metadata) -> bool {
    self == MetadataZeroable::zero()
  }

  #[inline(always)]
  fn is_non_zero(self: Metadata) -> bool {
    self != MetadataZeroable::zero()
  }
}
