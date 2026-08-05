///|
test "lag aligns prior values with later timestamps" {
  let series = time_series([0L, 1L, 2L, 3L], [1.0, 3.0, 6.0, 10.0], "x").unwrap()
  let lagged = series.lag(2).unwrap()
  assert_eq(lagged.timestamps(), [2L, 3L])
  assert_eq(lagged.values(), [1.0, 3.0])
}

///|
test "differences preserve aligned timestamps" {
  let series = time_series([0L, 1L, 2L, 3L], [1.0, 3.0, 6.0, 10.0], "x").unwrap()
  assert_eq(series.difference(1).unwrap().values(), [2.0, 3.0, 4.0])
  assert_eq(series.difference(1).unwrap().timestamps(), [1L, 2L, 3L])
  assert_eq(series.seasonal_difference(2).unwrap().values(), [5.0, 7.0])
}

///|
test "first difference restoration reconstructs future levels" {
  let restored = restore_first_difference(10.0, [2.0, -1.0, 4.0]).unwrap()
  assert_eq(restored, [12.0, 11.0, 15.0])
  assert_eq(
    restore_first_difference(1.0, [@double.infinity]),
    Err(NonFiniteValue(0)),
  )
}

///|
test "linear trend and detrending match a straight line" {
  let series = time_series([0L, 1L, 2L, 3L], [2.0, 5.0, 8.0, 11.0], "line").unwrap()
  let trend = series.linear_trend().unwrap()
  assert_true((trend.intercept - 2.0).abs() < 1.0e-12)
  assert_true((trend.slope - 3.0).abs() < 1.0e-12)
  assert_eq(series.detrend_linear().unwrap().values(), [0.0, 0.0, 0.0, 0.0])
}

///|
test "transformations reject invalid periods and short data" {
  let series = time_series([0L, 1L], [1.0, 2.0], "x").unwrap()
  assert_eq(series.lag(0), Err(InvalidPeriod(0)))
  assert_eq(series.difference(2), Err(InsufficientData(2, 3)))
  assert_eq(series.linear_trend(), Err(InsufficientData(2, 3)))
}
