use traits::Into;

// locals
use super::constants;

fn hash_u256(n: u256) -> felt252 {
  let mut hash = pedersen(0, constants::U256_TYPE_HASH);
  hash = pedersen(hash, n.low.into());
  hash = pedersen(hash, n.high.into());

  pedersen(hash, 3)
}
