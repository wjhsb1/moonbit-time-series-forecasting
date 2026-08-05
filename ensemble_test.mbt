///|
test "mean and median ensembles combine aligned forecasts" {
  let first = forecast_data([10L, 20L], [2.0, 8.0], "first").unwrap()
  let second = forecast_data([10L, 20L], [4.0, 4.0], "second").unwrap()
  let third = forecast_data([10L, 20L], [100.0, 6.0], "third").unwrap()
  assert_eq(mean_forecast([first, second], "mean").unwrap().values(), [3.0, 6.0])
  assert_eq(
    median_forecast([first, second, third], "median").unwrap().values(),
    [4.0, 6.0],
  )
}

///|
test "weighted ensemble normalizes nonnegative weights" {
  let first = forecast_data([1L, 2L], [1.0, 3.0], "a").unwrap()
  let second = forecast_data([1L, 2L], [5.0, 7.0], "b").unwrap()
  assert_eq(
    weighted_forecast([first, second], [3.0, 1.0], "weighted").unwrap().values(),
    [2.0, 4.0],
  )
}

///|
test "ensemble rejects count weight and timestamp mismatches" {
  let first = forecast_data([1L], [1.0], "a").unwrap()
  let shifted = forecast_data([2L], [1.0], "b").unwrap()
  assert_eq(mean_forecast([], "empty"), Err(EmptySeries))
  assert_eq(
    weighted_forecast([first], [1.0, 2.0], "bad"),
    Err(LengthMismatch(1, 2)),
  )
  assert_eq(
    weighted_forecast([first, shifted], [1.0, 1.0], "bad"),
    Err(ForecastAlignmentMismatch(1)),
  )
  assert_eq(
    weighted_forecast([first], [-1.0], "bad"),
    Err(InvalidWeight(0, -1.0)),
  )
}

///|
test "inverse error weights prefer lower errors and handle exact models" {
  assert_eq(inverse_error_weights([2.0, 1.0]).unwrap(), [1.0 / 3.0, 2.0 / 3.0])
  assert_eq(inverse_error_weights([0.0, 2.0, 0.0]).unwrap(), [0.5, 0.0, 0.5])
}

///|
test "selection ensemble refits successful candidates on full history" {
  let series = time_series(
    [0L, 1L, 2L, 3L, 4L, 5L],
    [1.0, 2.0, 3.0, 4.0, 5.0, 6.0],
    "line",
  ).unwrap()
  let selection = select_model(
    series,
    [NaiveSpec, DriftSpec],
    ExpandingConfig(3, 1, 1),
    SelectRmse,
  ).unwrap()
  let forecast = selection_ensemble(series, selection, 2, 2).unwrap()
  assert_eq(forecast.timestamps(), [6L, 7L])
  assert_eq(forecast.model_name(), "selection_ensemble")
  assert_true(forecast.values()[0] >= 6.0)
}
