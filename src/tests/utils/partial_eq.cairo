use traits::PartialEq;

// locals
use rules_tokens::core::interface::{ Metadata };

impl MetadataEq of PartialEq<Metadata> {
  fn eq(lhs: @Metadata, rhs: @Metadata) -> bool {
    *lhs.hash == *rhs.hash
  }

  #[inline(always)]
  fn ne(lhs: @Metadata, rhs: @Metadata) -> bool {
    !(lhs == rhs)
  }
}
