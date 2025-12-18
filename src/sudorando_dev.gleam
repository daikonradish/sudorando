import prng/random.{type Generator}
import prng/seed.{type Seed}
import sudorando

import gleam/io
import gleam/yielder

import gleamy/bench

fn run_sample(seed: Int) -> List(Float) {
  let randfloat = sudorando.rand_float(seed)
  sudorando.sample_many(randfloat, 10_000)
}

fn sample_prng_manual(s: Int) -> List(Float) {
  let gen = random.float(0.0, 0.1)
  let seed = seed.new(s)
  do_sample_prng(seed, gen, 10_000)
}

// well, this would just be traverseM over the state monad.
fn do_sample_prng(seed: Seed, gen: Generator(Float), n: Int) -> List(Float) {
  case n {
    0 -> []
    _ -> {
      let newstate = random.step(gen, seed)
      [newstate.0, ..do_sample_prng(newstate.1, gen, n - 1)]
    }
  }
}

fn sample_prng_yielder_api(s: Int) -> List(Float) {
  let gen = random.float(0.0, 0.1)
  let seed = seed.new(s)
  let y = random.to_yielder(gen, seed)
  y |> yielder.take(10_000) |> yielder.to_list()
}

pub fn main() -> Nil {
  bench.run(
    [
      bench.Input("RANDOM_SEED_1", 3_209_485),
      bench.Input("RANDOM_SEED_2", 2_309_482_093),
      bench.Input("RANDOM_SEED_3", 29_845_773),
      bench.Input("RANDOM_SEED_4", 186_125),
      bench.Input("RANDOM_SEED_5", 2397),
      bench.Input("RANDOM_SEED_6", 12_498_798),
      bench.Input("RANDOM_SEED_7", 9_947_732),
    ],
    [
      bench.Function("sudorando", run_sample),
      bench.Function("prng-manual", sample_prng_manual),
      //bench.Function("prng-yielder", sample_prng_yielder_api),
    ],
    [bench.Duration(1000), bench.Warmup(100)],
  )
  |> bench.table([bench.P(50)])
  |> io.println()
}
