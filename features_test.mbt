///|
test "forecast feature matrix aligns history with future targets" {
  let series = time_series(
    [0L, 1L, 2L, 3L, 4L, 5L, 6L],
    [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0],
    "line",
  ).unwrap()
  let dataset = build_forecast_features(
    series,
    [LagValue(1), LagValue(2), RollingMeanValue(3), DifferenceValue(1)],
    1,
  ).unwrap()
  assert_eq(dataset.row_count(), 4)
  assert_eq(dataset.feature_count(), 4)
  assert_eq(dataset.row(0).unwrap(), [2.0, 1.0, 2.0, 1.0])
  assert_eq(dataset.targets(), [4.0, 5.0, 6.0, 7.0])
  assert_eq(dataset.target_timestamps(), [3L, 4L, 5L, 6L])
}

///|
test "multi-step target horizon never enters feature rows" {
  let series = time_series(
    [0L, 1L, 2L, 3L, 4L, 5L],
    [10.0, 20.0, 30.0, 999.0, 999.0, 999.0],
    "shift",
  ).unwrap()
  let dataset = build_forecast_features(series, [LagValue(1)], 2).unwrap()
  assert_eq(dataset.row(0).unwrap(), [10.0])
  assert_eq(dataset.targets()[0], 999.0)
  assert_eq(dataset.origin_timestamps()[0], 1L)
  assert_eq(dataset.target_timestamps()[0], 3L)
}

///|
test "rolling feature variants use only the origin window" {
  let series = time_series([0L, 1L, 2L, 3L], [1.0, 3.0, 5.0, 7.0], "x").unwrap()
  let dataset = build_forecast_features(
    series,
    [CurrentValue, RollingMinValue(2), RollingMaxValue(2), RollingStdValue(2)],
    1,
  ).unwrap()
  let row = dataset.row(0).unwrap()
  assert_eq(row[0], 3.0)
  assert_eq(row[1], 1.0)
  assert_eq(row[2], 3.0)
  assert_eq(row[3], 1.0)
}

///|
test "feature names describe ordered specifications" {
  assert_eq(
    feature_names([
      CurrentValue,
      LagValue(2),
      DifferenceValue(3),
      RollingMeanValue(4),
    ]),
    ["current", "lag_2", "difference_3", "rolling_mean_4"],
  )
}

///|
test "feature construction validates specs horizon and data length" {
  let series = time_series([0L, 1L, 2L], [1.0, 2.0, 3.0], "x").unwrap()
  assert_eq(build_forecast_features(series, [], 1), Err(EmptySeries))
  assert_eq(
    build_forecast_features(series, [LagValue(0)], 1),
    Err(InvalidPeriod(0)),
  )
  assert_eq(
    build_forecast_features(series, [RollingMeanValue(0)], 1),
    Err(InvalidWindow(0)),
  )
  assert_eq(
    build_forecast_features(series, [LagValue(1)], 0),
    Err(InvalidSteps(0)),
  )
  assert_eq(
    build_forecast_features(series, [LagValue(2)], 2),
    Err(InsufficientData(3, 5)),
  )
}
