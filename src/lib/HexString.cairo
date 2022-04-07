from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.uint256 import Uint256, uint256_eq, uint256_unsigned_div_rem, uint256_mul, uint256_add
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.pow import pow

const MAX_DEPTH = 30

func uint256_to_hs{ range_check_ptr }(value: Uint256) -> (res_len: felt, res: felt*):
  alloc_locals

  let (local res) = alloc()

  let (value_eq) = uint256_eq(value, Uint256(0, 0))
  if value_eq == 1:
    assert res[0] = 48
    return (res_len=1, res=res)
  end

  let (res_len) = _uint256_to_hs(value=value, res=res, leading_zeros=0)
  return (res_len, res)
end

func _uint256_to_hs{ range_check_ptr }(value: Uint256, res: felt*, leading_zeros: felt) -> (res_len: felt):
  alloc_locals

  let (zeros_word, remaining_leading_zeros) = _leading_zeros(leading_zeros=leading_zeros, depth=0)

  let (value_eq) = uint256_eq(value, Uint256(0, 0))
  if value_eq == 1:
    if zeros_word == 0:
      return (0)
    end
    assert res[0] = zeros_word
    let (res_len) = _uint256_to_hs(value=value, res=res + 1, leading_zeros=remaining_leading_zeros)
    return (res_len=res_len + 1)
  end

  let (word, remainder, leading_zeros, word_len) = _uint256_to_hs_word(value=value, depth_offset=leading_zeros, leading_zeros=0)
  let (offset_exponent) = pow(256, word_len)
  assert res[0] = zeros_word * offset_exponent + word
  let (res_len) = _uint256_to_hs(value=remainder, res=res + 1, leading_zeros=leading_zeros + remaining_leading_zeros)
  return (res_len=res_len + 1)
end

func _uint256_to_hs_word{
    range_check_ptr
  }(value: Uint256, depth_offset: felt, leading_zeros: felt) -> (word: felt, remainder: Uint256, leading_zeros: felt, word_len: felt):
  alloc_locals

  let (will_overflow) = is_le(MAX_DEPTH, depth_offset)
  if will_overflow == 1:
    return (word=0, remainder=value, leading_zeros=0, word_len=0)
  end

  let (q, r) = uint256_unsigned_div_rem(value, Uint256(0x10, 0))
  let (quotient_null) = uint256_eq(q, Uint256(0, 0))

  if quotient_null == 1:
    let (char) = _hex_digit_to_hs(digit=r.low)
    return (word=char, remainder=q, leading_zeros=0, word_len=1)
  end

  let (word, remainder, leading_zeros, word_len) = _uint256_to_hs_word(value=q, depth_offset=depth_offset, leading_zeros=leading_zeros)

  let (will_overflow) = is_le(MAX_DEPTH, word_len + depth_offset)
  if will_overflow == 1:
    let (mul_remainder: Uint256, _) = uint256_mul(remainder, Uint256(16, 0))
    let (new_remainder: Uint256, _) = uint256_add(mul_remainder, r)

    let (null_new_remainder) = uint256_eq(new_remainder, Uint256(0, 0))
    if null_new_remainder == 1:
      return (word=word, remainder=new_remainder, leading_zeros=leading_zeros + 1, word_len=word_len)
    end
    return (word=word, remainder=new_remainder, leading_zeros=leading_zeros, word_len=word_len)
  end

  let (char) = _hex_digit_to_hs(r.low)
  let new_word = word * 256 + char
  return (word=new_word, remainder=remainder, leading_zeros=0, word_len=word_len + 1)
end

func _hex_digit_to_hs{ range_check_ptr }(digit: felt) -> (char: felt):
  let (decimal_char) = is_le(digit, 9)

  if decimal_char == 1:
    return (char=digit + 48)
  end
  return (char=digit + 87)
end

func _leading_zeros{ range_check_ptr }(leading_zeros: felt, depth: felt) -> (word: felt, remaining_leading_zeros: felt):
  if leading_zeros == 0:
    return (word=0, remaining_leading_zeros=0)
  end

  let (will_overflow) = is_le(MAX_DEPTH, depth)
  if will_overflow == 1:
    return (word=0, remaining_leading_zeros=leading_zeros)
  end

  let (word, remaining_leading_zeros) = _leading_zeros(leading_zeros=leading_zeros - 1, depth=depth + 1)
  return (word=word * 256 + 48, remaining_leading_zeros=remaining_leading_zeros)
end
