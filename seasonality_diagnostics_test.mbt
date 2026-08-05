///|
test "period diagnostic recognizes a stable season" {
  let series = time_series(
    [0L, 1L, 2L, 3L, 4L, 5L, 6L, 7L],
    [8.0, 12.0, 8.0, 12.0, 8.0, 12.0, 8.0, 12.0],
    "season",
  ).unwrap()
  let diagnostic = diagnose_period(series, 2).unwrap()
  assert_true((diagnostic.autocorrelation - 0.75).abs() < 1.0e-12)
  assert_true((diagnostic.seasonal_strength - 1.0).abs() < 1.0e-12)
  assert_eq(diagnostic.period, 2)
}

///|
test "candidate periods rank by absolute autocorrelation stably" {
  let series = time_series(
    [0L, 1L, 2L, 3L, 4L, 5L, 6L, 7L],
    [1.0, 3.0, 1.0, 3.0, 1.0, 3.0, 1.0, 3.0],
    "season",
  ).unwrap()
  let ranked = rank_periods(series, [3, 2]).unwrap()
  assert_eq(ranked[0].period, 2)
  assert_eq(ranked[1].period, 3)
}

///|
test "seasonal profiles normalize additive and multiplicative factors" {
  let series = time_series(
    [0L, 1L, 2L, 3L, 4L, 5L],
    [8.0, 12.0, 8.0, 12.0, 8.0, 12.0],
    "season",
  ).unwrap()
  assert_eq(seasonal_profile(series, 2, Additive).unwrap(), [-2.0, 2.0])
  let factors = seasonal_profile(series, 2, Multiplicative).unwrap()
  assert_true(((factors[0] + factors[1]) / 2.0 - 1.0).abs() < 1.0e-12)
}

///|
test "seasonal adjustment removes a stable pattern" {
  let series = time_series(
    [0L, 1L, 2L, 3L, 4L, 5L],
    [8.0, 12.0, 8.0, 12.0, 8.0, 12.0],
    "season",
  ).unwrap()
  assert_eq(seasonally_adjust(series, 2, Additive).unwrap().values(), [
    10.0, 10.0, 10.0, 10.0, 10.0, 10.0,
  ])
}

///|
test "period diagnostics reject invalid and duplicate candidates" {
  let series = time_series([0L, 1L, 2L, 3L], [1.0, 2.0, 1.0, 2.0], "x").unwrap()
  assert_eq(diagnose_period(series, 0), Err(InvalidPeriod(0)))
  assert_eq(rank_periods(series, []), Err(EmptySeries))
  assert_eq(rank_periods(series, [2, 2]), Err(DuplicatePeriod(2)))
}
