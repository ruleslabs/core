from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.pow import pow
from starkware.cairo.common.uint256 import Uint256, uint256_unsigned_div_rem, uint256_eq
from starkware.cairo.common.math_cmp import is_le

const MAX_DEPTH = 30;

func uint256_to_hs{range_check_ptr}(value: Uint256) -> (res_len: felt, res: felt*) {
  alloc_locals;

  let (local res) = alloc();

  let (value_eq) = uint256_eq(value, Uint256(0, 0));
  if (value_eq == 1) {
    assert res[0] = 48;
    return (res_len=1, res=res);
  }

  let (res_len) = _uint256_to_hs(value, res);
  return (res_len=res_len, res=res);
}

func _uint256_to_hs{range_check_ptr}(value: Uint256, res: felt*) -> (res_len: felt) {
  alloc_locals;

  let (value_eq) = uint256_eq(value, Uint256(0, 0));
  if (value_eq == 1) {
    return (res_len=0);
  }

  let (local running_total, remainder) = _uint256_to_hs_partial(value, 0);
  let (res_len) = _uint256_to_hs(remainder, res);
  assert res[res_len] = running_total;
  return (res_len=res_len + 1);
}

func _uint256_to_hs_partial{range_check_ptr}(value: Uint256, depth: felt) -> (
  running_total: felt, remainder: Uint256
) {
  alloc_locals;

  let (local word_exponent) = pow(2, 8 * depth);

  let (q, r) = uint256_unsigned_div_rem(value, Uint256(16, 0));
  assert r.high = 0;
  let (quotient_eq) = uint256_eq(q, Uint256(0, 0));
  if (quotient_eq == 1) {
    let (char) = _hex_digit_to_hs(digit=r.low);
    let res = word_exponent * char;
    return (running_total=res, remainder=q);
  }
  if (depth == MAX_DEPTH) {
    let (char) = _hex_digit_to_hs(digit=r.low);
    let res = word_exponent * char;
    return (running_total=res, remainder=q);
  }

  let (running_total, remainder) = _uint256_to_hs_partial(q, depth + 1);
  let (char) = _hex_digit_to_hs(digit=r.low);
  let res = word_exponent * char + running_total;
  return (running_total=res, remainder=remainder);
}

func _hex_digit_to_hs{range_check_ptr}(digit: felt) -> (char: felt) {
  let decimal_char = is_le(digit, 9);

  if (decimal_char == 1) {
    return (char=digit + 48);
  }
  return (char=digit + 87);
}
