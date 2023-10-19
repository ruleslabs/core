use traits::PartialEq;

// locals
use rules_tokens::core::interface::{ Scarcity, CardModel, Pack };

impl ScarcityEq of PartialEq<Scarcity> {
  fn eq(lhs: @Scarcity, rhs: @Scarcity) -> bool {
    (*lhs.max_supply == *rhs.max_supply) & (*lhs.name == *rhs.name)
  }

  #[inline(always)]
  fn ne(lhs: @Scarcity, rhs: @Scarcity) -> bool {
    !(lhs == rhs)
  }
}

impl CardModelEq of PartialEq<CardModel> {
  fn eq(lhs: @CardModel, rhs: @CardModel) -> bool {
    (*lhs.artist_name == *rhs.artist_name) & (*lhs.scarcity_id == *rhs.scarcity_id) & (*lhs.season == *rhs.season)
  }

  #[inline(always)]
  fn ne(lhs: @CardModel, rhs: @CardModel) -> bool {
    !(lhs == rhs)
  }
}

impl PackEq of PartialEq<Pack> {
  fn eq(lhs: @Pack, rhs: @Pack) -> bool {
    *lhs.name == *rhs.name
  }

  #[inline(always)]
  fn ne(lhs: @Pack, rhs: @Pack) -> bool {
    !(lhs == rhs)
  }
}
