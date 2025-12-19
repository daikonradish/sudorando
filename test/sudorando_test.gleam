import gleeunit
import sudorando

pub fn main() -> Nil {
  gleeunit.main()
}

// gleeunit test functions end in `_test`
pub fn rand_int_test() {
  let randfloat1 = sudorando.rand_float(3)
  let sample1 = sudorando.sample_many(randfloat1, 100)
  let randfloat2 = sudorando.rand_float(3)
  let sample2 = sudorando.sample_many(randfloat2, 100)
  assert sample1 == sample2
}
