use array::{ ArrayTrait, SpanTrait };
use traits::PartialEq;

// locals
use rules_tokens::core::interface::{ Scarcity, CardModel, Metadata };

impl ScarcityEq of PartialEq<Scarcity> {
  fn eq(lhs: Scarcity, rhs: Scarcity) -> bool {
    lhs.max_supply == rhs.max_supply & lhs.name == rhs.name
  }

  #[inline(always)]
  fn ne(lhs: Scarcity, rhs: Scarcity) -> bool {
    !(lhs == rhs)
  }
}

impl CardModelEq of PartialEq<CardModel> {
  fn eq(lhs: CardModel, rhs: CardModel) -> bool {
    lhs.artist_name == rhs.artist_name & lhs.scarcity == rhs.scarcity & lhs.season == rhs.season
  }

  #[inline(always)]
  fn ne(lhs: CardModel, rhs: CardModel) -> bool {
    !(lhs == rhs)
  }
}

impl MetadataEq of PartialEq<Metadata> {
  fn eq(lhs: Metadata, rhs: Metadata) -> bool {
    lhs.multihash_identifier == rhs.multihash_identifier & lhs.hash == rhs.hash
  }

  #[inline(always)]
  fn ne(lhs: Metadata, rhs: Metadata) -> bool {
    !(lhs == rhs)
  }
}
