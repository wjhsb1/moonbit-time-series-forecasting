///|
test "simple exponential smoothing matches hand calculation" {
  let series = time_series([0L, 1L, 2L], [10.0, 14.0, 13.0], "x").unwrap()
  let model = fit_ses(series, 0.5).unwrap()
  assert_eq(model.level(), 12.5)
  assert_eq(model.fitted_values(), [10.0, 10.0, 12.0])
  assert_eq(model.residuals(), [0.0, 4.0, 1.0])
  assert_eq(model.forecast(2).unwrap().values(), [12.5, 12.5])
}

///|
test "Holt linear extends fitted level and trend" {
  let series = time_series([0L, 10L, 20L, 30L], [2.0, 4.0, 6.0, 8.0], "line").unwrap()
  let model = fit_holt(series, 0.5, 0.5).unwrap()
  assert_true((model.level() - 8.0).abs() < 1.0e-12)
  assert_true((model.trend() - 2.0).abs() < 1.0e-12)
  assert_eq(model.forecast(2).unwrap().values(), [10.0, 12.0])
  assert_eq(model.forecast(2).unwrap().timestamps(), [40L, 50L])
}

///|
test "damped Holt uses a geometric trend sum" {
  let series = time_series([0L, 1L, 2L], [1.0, 3.0, 5.0], "line").unwrap()
  let model = fit_damped_holt(series, 1.0, 1.0, 0.5).unwrap()
  let values = model.forecast(2).unwrap().values()
  assert_true((values[0] - 6.0).abs() < 1.0e-12)
  assert_true((values[1] - 6.5).abs() < 1.0e-12)
}

///|
test "smoothing validates parameters and regular sampling" {
  let series = time_series([0L, 1L], [1.0, 2.0], "x").unwrap()
  assert_eq(fit_ses(series, 0.0), Err(InvalidSmoothingParameter("alpha", 0.0)))
  assert_eq(
    fit_holt(series, 0.5, 1.1),
    Err(InvalidSmoothingParameter("beta", 1.1)),
  )
  assert_eq(
    fit_damped_holt(series, 0.5, 0.5, 0.0),
    Err(InvalidSmoothingParameter("damping", 0.0)),
  )
  let irregular = time_series([0L, 2L, 5L], [1.0, 2.0, 3.0], "x").unwrap()
  assert_eq(fit_ses(irregular, 0.5), Err(IrregularInterval(2)))
}
