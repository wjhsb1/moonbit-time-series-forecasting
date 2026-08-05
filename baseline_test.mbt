///|
test "baseline models produce exact multi-step forecasts" {
  let series = time_series([0L, 10L, 20L, 30L], [2.0, 4.0, 6.0, 8.0], "x").unwrap()
  assert_eq(fit_mean(series).unwrap().forecast(3).unwrap().values(), [
    5.0, 5.0, 5.0,
  ])
  assert_eq(fit_naive(series).unwrap().forecast(3).unwrap().values(), [
    8.0, 8.0, 8.0,
  ])
  assert_eq(fit_drift(series).unwrap().forecast(2).unwrap().values(), [
    10.0, 12.0,
  ])
}

///|
test "baseline forecasts advance the validated interval" {
  let series = time_series([100L, 110L, 120L], [1.0, 2.0, 3.0], "x").unwrap()
  let forecast = fit_naive(series).unwrap().forecast(3).unwrap()
  assert_eq(forecast.timestamps(), [130L, 140L, 150L])
  assert_eq(forecast.model_name(), "naive")
}

///|
test "seasonal naive repeats the final cycle" {
  let series = time_series(
    [0L, 1L, 2L, 3L, 4L, 5L],
    [1.0, 2.0, 3.0, 1.0, 2.0, 3.0],
    "x",
  ).unwrap()
  assert_eq(
    fit_seasonal_naive(series, 3).unwrap().forecast(5).unwrap().values(),
    [1.0, 2.0, 3.0, 1.0, 2.0],
  )
}

///|
test "baseline fitting and forecasting reject invalid inputs" {
  let one = time_series([0L], [2.0], "one").unwrap()
  assert_eq(fit_mean(one), Err(InsufficientData(1, 2)))
  let irregular = time_series([0L, 2L, 5L], [1.0, 2.0, 3.0], "bad").unwrap()
  assert_eq(fit_naive(irregular), Err(IrregularInterval(2)))
  let regular = time_series([0L, 1L, 2L], [1.0, 2.0, 3.0], "x").unwrap()
  assert_eq(fit_seasonal_naive(regular, 0), Err(InvalidPeriod(0)))
  assert_eq(fit_seasonal_naive(regular, 3), Err(InsufficientData(3, 4)))
  assert_eq(fit_naive(regular).unwrap().forecast(0), Err(InvalidSteps(0)))
}

///|
test "forecast accessors return defensive copies" {
  let series = time_series([0L, 1L], [1.0, 2.0], "x").unwrap()
  let forecast = fit_mean(series).unwrap().forecast(2).unwrap()
  let values = forecast.values()
  values[0] = 99.0
  assert_eq(forecast.values(), [1.5, 1.5])
}
