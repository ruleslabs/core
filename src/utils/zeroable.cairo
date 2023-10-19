use zeroable::Zeroable;

// locals
use rules_tokens::core::interface::{ Scarcity, CardModel, Pack, Metadata };
use super::partial_eq::{ CardModelEq, PackEq, ScarcityEq };

impl CardModelZeroable of Zeroable<CardModel> {
  fn zero() -> CardModel {
    CardModel {
      artist_name: 0,
      season: 0,
      scarcity_id: 0,
    }
  }

  #[inline(always)]
  fn is_zero(self: CardModel) -> bool {
    self == CardModelZeroable::zero()
  }

  #[inline(always)]
  fn is_non_zero(self: CardModel) -> bool {
    self != CardModelZeroable::zero()
  }
}

impl ScarcityZeroable of Zeroable<Scarcity> {
  fn zero() -> Scarcity {
    Scarcity {
      max_supply: 0,
      name: 0,
    }
  }

  #[inline(always)]
  fn is_zero(self: Scarcity) -> bool {
    self == ScarcityZeroable::zero()
  }

  #[inline(always)]
  fn is_non_zero(self: Scarcity) -> bool {
    self != ScarcityZeroable::zero()
  }
}

impl PackZeroable of Zeroable<Pack> {
  fn zero() -> Pack {
    Pack {
      name: 0,
    }
  }

  #[inline(always)]
  fn is_zero(self: Pack) -> bool {
    self == PackZeroable::zero()
  }

  #[inline(always)]
  fn is_non_zero(self: Pack) -> bool {
    self != PackZeroable::zero()
  }
}
