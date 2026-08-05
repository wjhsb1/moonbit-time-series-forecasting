///|
test "trailing rolling aggregates align to window end" {
  let series = time_series([0L, 1L, 2L, 3L], [1.0, 2.0, 3.0, 4.0], "x").unwrap()
  assert_eq(series.moving_sum(2).unwrap().values(), [3.0, 5.0, 7.0])
  assert_eq(series.moving_mean(2).unwrap().values(), [1.5, 2.5, 3.5])
  assert_eq(series.moving_mean(2).unwrap().timestamps(), [1L, 2L, 3L])
  assert_eq(series.moving_min(3).unwrap().values(), [1.0, 2.0])
  assert_eq(series.moving_max(3).unwrap().values(), [3.0, 4.0])
}

///|
test "rolling median quantile and standard deviation are exact" {
  let series = time_series([0L, 1L, 2L, 3L], [1.0, 100.0, 3.0, 5.0], "x").unwrap()
  assert_eq(series.moving_median(3).unwrap().values(), [3.0, 5.0])
  assert_eq(series.moving_quantile(3, 0.25).unwrap().values(), [2.0, 4.0])
  let stddev = series.moving_standard_deviation(2).unwrap().values()
  assert_eq(stddev[0], 49.5)
  assert_eq(stddev[2], 1.0)
}

///|
test "weighted moving average applies oldest-to-newest weights" {
  let series = time_series([0L, 1L, 2L, 3L], [1.0, 2.0, 3.0, 4.0], "x").unwrap()
  assert_eq(series.weighted_moving_average([1.0, 2.0]).unwrap().values(), [
    5.0 / 3.0,
    8.0 / 3.0,
    11.0 / 3.0,
  ])
}

///|
test "exponential moving average retains all timestamps" {
  let series = time_series([0L, 1L, 2L], [10.0, 14.0, 13.0], "x").unwrap()
  let result = series.exponential_moving_average(0.5).unwrap()
  assert_eq(result.values(), [10.0, 12.0, 12.5])
  assert_eq(result.timestamps(), [0L, 1L, 2L])
}

///|
test "rolling functions reject invalid windows weights and probability" {
  let series = time_series([0L, 1L], [1.0, 2.0], "x").unwrap()
  assert_eq(series.moving_mean(0), Err(InvalidWindow(0)))
  assert_eq(series.moving_mean(3), Err(InsufficientData(2, 3)))
  assert_eq(
    series.weighted_moving_average([1.0, -1.0]),
    Err(InvalidWeight(1, -1.0)),
  )
  assert_eq(series.moving_quantile(2, 1.1), Err(InvalidProbability(1.1)))
}
