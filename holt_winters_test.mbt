///|
test "additive Holt-Winters preserves a stable two-value season" {
  let series = time_series(
    [0L, 1L, 2L, 3L, 4L, 5L, 6L, 7L],
    [10.0, 12.0, 10.0, 12.0, 10.0, 12.0, 10.0, 12.0],
    "season",
  ).unwrap()
  let model = fit_holt_winters(series, 2, 0.5, 0.2, 0.5, Additive).unwrap()
  let values = model.forecast(4).unwrap().values()
  assert_eq(values.length(), 4)
  assert_true((values[0] - 10.0).abs() < 1.0e-9)
  assert_true((values[1] - 12.0).abs() < 1.0e-9)
  assert_true((values[2] - 10.0).abs() < 1.0e-9)
  assert_true((values[3] - 12.0).abs() < 1.0e-9)
}

///|
test "multiplicative Holt-Winters preserves proportional seasonality" {
  let series = time_series(
    [0L, 1L, 2L, 3L, 4L, 5L],
    [8.0, 12.0, 8.0, 12.0, 8.0, 12.0],
    "season",
  ).unwrap()
  let values = fit_holt_winters(series, 2, 0.4, 0.3, 0.5, Multiplicative)
    .unwrap()
    .forecast(2)
    .unwrap()
    .values()
  assert_true((values[0] - 8.0).abs() < 1.0e-9)
  assert_true((values[1] - 12.0).abs() < 1.0e-9)
}

///|
test "Holt-Winters validates domain period and parameters" {
  let zero = time_series([0L, 1L, 2L, 3L], [1.0, 2.0, 0.0, 2.0], "x").unwrap()
  assert_eq(
    fit_holt_winters(zero, 2, 0.5, 0.5, 0.5, Multiplicative),
    Err(NonPositiveMultiplicativeValue(2)),
  )
  let short = time_series([0L, 1L, 2L], [1.0, 2.0, 1.0], "x").unwrap()
  assert_eq(
    fit_holt_winters(short, 2, 0.5, 0.5, 0.5, Additive),
    Err(InsufficientData(3, 4)),
  )
  let regular = time_series([0L, 1L, 2L, 3L], [1.0, 2.0, 1.0, 2.0], "x").unwrap()
  assert_eq(
    fit_holt_winters(regular, 0, 0.5, 0.5, 0.5, Additive),
    Err(InvalidPeriod(0)),
  )
  assert_eq(
    fit_holt_winters(regular, 2, 0.5, 0.5, 1.2, Additive),
    Err(InvalidSmoothingParameter("gamma", 1.2)),
  )
}

///|
test "Holt-Winters exposes aligned fitted values and residuals" {
  let series = time_series([0L, 1L, 2L, 3L], [2.0, 4.0, 2.0, 4.0], "x").unwrap()
  let model = fit_holt_winters(series, 2, 0.5, 0.5, 0.5, Additive).unwrap()
  assert_eq(model.fitted_values().length(), 4)
  assert_eq(model.residuals().length(), 4)
  assert_eq(model.model_name(), "holt_winters_additive")
}
