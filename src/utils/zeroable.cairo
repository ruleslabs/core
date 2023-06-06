// Not available in cairo@1.1.0 but coming soon
impl U128Zeroable of Zeroable<u128> {
  fn zero() -> u128 {
    0
  }
  #[inline(always)]
  fn is_zero(self: u128) -> bool {
    self == U128Zeroable::zero()
  }
  #[inline(always)]
  fn is_non_zero(self: u128) -> bool {
    self != U128Zeroable::zero()
  }
}

// Not available in cairo@1.1.0 but coming soon
impl U256Zeroable of Zeroable<u256> {
  fn zero() -> u256 {
    0
  }
  #[inline(always)]
  fn is_zero(self: u256) -> bool {
    self == U256Zeroable::zero()
  }
  #[inline(always)]
  fn is_non_zero(self: u256) -> bool {
    self != U256Zeroable::zero()
  }
}
