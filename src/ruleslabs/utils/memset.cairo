from starkware.cairo.common.uint256 import Uint256

func uint256_memset(dst: Uint256*, value: Uint256, n: felt) {
  struct LoopFrame {
    dst: Uint256*,
  }

  if (n == 0) {
    return ();
  }

  %{ vm_enter_scope({'n': ids.n}) %}
  tempvar frame = LoopFrame(dst=dst);

  loop:
  let frame = [cast(ap - LoopFrame.SIZE, LoopFrame*)];
  assert [frame.dst] = value;

  let continue_loop = [ap];
  // Reserve space for continue_loop.
  let next_frame = cast(ap + 1, LoopFrame*);
  next_frame.dst = frame.dst + Uint256.SIZE, ap++;
  %{
    n -= 1
    ids.continue_loop = 1 if n > 0 else 0
  %}
  static_assert next_frame + LoopFrame.SIZE == ap + 1;
  jmp loop if continue_loop != 0, ap++;
  // Assert that the loop executed n times.
  assert n = (cast(next_frame.dst, felt) - cast(dst, felt)) / Uint256.SIZE;

  %{ vm_exit_scope() %}
  return ();
}
