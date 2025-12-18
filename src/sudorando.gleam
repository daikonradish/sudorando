import atomic_array.{type AtomicArray}
import gleam/int

// 2^32 - 1 and 2^64 -1 respectively.
const mask32: Int = 4_294_967_295

const mask32f: Float = 4_294_967_295.0

const mask64: Int = 18_446_744_073_709_551_615

// 0x5851f42d4c957f2dULL
const pcg32_mult: Int = 6_364_136_223_846_793_005

// yopu need
// something that can create a random int
// and then take that random int and then creeate
// a new float / int

// typedef struct { uint64_t state;  uint64_t inc; } pcg32_random_t;
pub opaque type Prng {
  Pcg32(AtomicArray)
  // Kiss(AtomicArray)
  // Cong(AtomicArray)
  // Other strategies can go here.
}

pub opaque type Generator {
  UInt32(Prng)
  // UInt64(PrngAlgorithm) can also go here.
}

pub opaque type Rand(a) {
  RInt(gen: Generator, f: fn(Generator) -> a)
  RFloat(gen: Generator, f: fn(Generator) -> a)
  RBoundedInt(
    gen: Generator,
    f: fn(Generator, Int, Int) -> a,
    min: Int,
    max: Int,
  )
  RBoundedFloat(
    gen: Generator,
    f: fn(Generator, Float, Float) -> a,
    min: Float,
    max: Float,
  )
}

pub fn rand_int(seed: Int) -> Rand(Int) {
  RInt(UInt32(pcg32(seed)), fn(g) -> Int { generate(g) })
}

pub fn rand_float(seed: Int) -> Rand(Float) {
  RInt(UInt32(pcg32(seed)), fn(g) -> Float { to_unit_uint32(generate(g)) })
}

pub fn sample(rand: Rand(a)) -> a {
  case rand {
    RInt(gen, f) -> f(gen)
    RFloat(gen, f) -> f(gen)
    RBoundedInt(gen, f, min, max) -> f(gen, min, max)
    RBoundedFloat(gen, f, min, max) -> f(gen, min, max)
  }
}

pub fn sample_many(rand: Rand(a), n: Int) -> List(a) {
  case n {
    0 -> []
    _ -> [sample(rand), ..sample_many(rand, n - 1)]
  }
}

pub fn generate(generator: Generator) -> Int {
  case generator {
    UInt32(prng) -> {
      handler(prng)
    }
  }
}

fn handler(prng: Prng) -> Int {
  case prng {
    Pcg32(internals) -> {
      // Mutating code should go here.
      // Any functions defined outside of this scope
      // should be pure.
      // 1. first read the internals
      let assert Ok(state) = atomic_array.get(internals, 0)
      let assert Ok(incr) = atomic_array.get(internals, 1)
      // pcg_transition function is pure.
      let new_state = pcg32_transition(state, incr)
      // Now update the internals.
      let assert Ok(_) = atomic_array.set(internals, 0, new_state)
      // pcg_output, taking the old state.
      pcg32_output(state, incr)
    }
  }
}

//    void seed(uint64_t initstate, uint64_t initseq = 1) {
//      state = 0U;
//      inc = (initseq << 1u) | 1u;
//      nextUInt();
//      state += initstate;
//      nextUInt();
//    }
pub fn pcg32(seed: Int) -> Prng {
  // new atopmic array with 2 elemnts
  let incr = 13_298_047
  let s =
    pcg32_transition(
      pcg32_transition(seed + pcg32_transition(0, incr), incr) + seed,
      incr,
    )
  let arr = atomic_array.new_unsigned(2)
  let _ = atomic_array.set(arr, 0, s)
  let _ = atomic_array.set(arr, 1, incr)
  Pcg32(arr)
}

// uint32_t nextUInt() {
//     uint64_t oldstate = state;
//     state = oldstate * PCG32_MULT + inc;
//     uint32_t xorshifted = (uint32_t) (((oldstate >> 18u) ^ oldstate) >> 27u);
//     uint32_t rot = (uint32_t) (oldstate >> 59u);
//     return (xorshifted >> rot) | (xorshifted << ((~rot + 1u) & 31));
// }
fn pcg32_transition(s: Int, incr: Int) -> Int {
  uint64({ s * pcg32_mult } + incr)
}

fn pcg32_output(s: Int, incr: Int) -> Int {
  let xorred =
    uint32(int.bitwise_shift_right(
      int.bitwise_exclusive_or(int.bitwise_shift_right(s, 18), s),
      27,
    ))
  let rotated = uint32(int.bitwise_shift_right(s, 59))
  uint32(int.bitwise_or(
    int.bitwise_shift_right(xorred, rotated),
    int.bitwise_shift_left(
      xorred,
      int.bitwise_and({ int.bitwise_not(rotated) + 1 }, 31),
    ),
  ))
}

fn uint32(n: Int) -> Int {
  int.bitwise_and(n, mask32)
}

fn uint64(n: Int) -> Int {
  int.bitwise_and(n, mask64)
}

fn to_unit_uint32(i: Int) -> Float {
  int.to_float(i) /. mask32f
}
