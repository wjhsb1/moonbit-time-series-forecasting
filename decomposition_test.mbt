///|
test "additive components reconstruct every available observation" {
  let series = time_series(
    [0L, 1L, 2L, 3L, 4L, 5L],
    [11.0, 9.0, 13.0, 11.0, 15.0, 13.0],
    "x",
  ).unwrap()
  let result = decompose_additive(series, 2).unwrap()
  let observed = result.observed()
  let trend = result.trend()
  let seasonal = result.seasonal()
  let residual = result.residual()
  let available = result.available()
  for index = 0; index < result.length(); index = index + 1 {
    if available[index] {
      assert_true(
        (trend[index] + seasonal[index] + residual[index] - observed[index]).abs() <
        1.0e-9,
      )
    }
  }
  assert_eq(available, [false, true, true, true, true, false])
}

///|
test "additive seasonal factors normalize to zero" {
  let series = time_series(
    [0L, 1L, 2L, 3L, 4L, 5L, 6L, 7L],
    [9.0, 11.0, 9.0, 11.0, 9.0, 11.0, 9.0, 11.0],
    "x",
  ).unwrap()
  let factors = decompose_additive(series, 2).unwrap().seasonal_factors()
  assert_true((factors[0] + factors[1]).abs() < 1.0e-12)
}

///|
test "multiplicative components reconstruct and normalize" {
  let series = time_series(
    [0L, 1L, 2L, 3L, 4L, 5L, 6L, 7L],
    [8.0, 12.0, 8.0, 12.0, 8.0, 12.0, 8.0, 12.0],
    "x",
  ).unwrap()
  let result = decompose_multiplicative(series, 2).unwrap()
  let factors = result.seasonal_factors()
  assert_true(((factors[0] + factors[1]) / 2.0 - 1.0).abs() < 1.0e-12)
  let observed = result.observed()
  let trend = result.trend()
  let seasonal = result.seasonal()
  let residual = result.residual()
  for index, available in result.available() {
    if available {
      assert_true(
        (trend[index] * seasonal[index] * residual[index] - observed[index]).abs() <
        1.0e-9,
      )
    }
  }
}

///|
test "decomposition validates period data and multiplicative domain" {
  let short = time_series([0L, 1L, 2L], [1.0, 2.0, 1.0], "x").unwrap()
  assert_eq(decompose_additive(short, 2), Err(InsufficientData(3, 4)))
  assert_eq(decompose_additive(short, 0), Err(InvalidPeriod(0)))
  let zero = time_series([0L, 1L, 2L, 3L], [1.0, 2.0, 0.0, 2.0], "x").unwrap()
  assert_eq(
    decompose_multiplicative(zero, 2),
    Err(NonPositiveMultiplicativeValue(2)),
  )
}
