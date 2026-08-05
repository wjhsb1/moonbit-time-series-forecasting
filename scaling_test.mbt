///|
test "standard scaler transforms and restores a series" {
  let series = time_series([0L, 1L, 2L], [1.0, 2.0, 3.0], "x").unwrap()
  let scaler = fit_standard_scaler(series).unwrap()
  assert_eq(scaler.mean(), 2.0)
  let transformed = scaler.transform(series).unwrap()
  assert_true(transformed.values()[0] < 0.0)
  assert_eq(transformed.values()[1], 0.0)
  let restored = scaler.inverse_transform(transformed).unwrap().values()
  for index = 0; index < restored.length(); index = index + 1 {
    assert_true((restored[index] - series.values()[index]).abs() < 1.0e-12)
  }
}

///|
test "min-max scaler maps fitted endpoints to target range" {
  let series = time_series([0L, 1L, 2L], [10.0, 15.0, 20.0], "x").unwrap()
  let scaler = fit_min_max_scaler(series, -1.0, 1.0).unwrap()
  assert_eq(scaler.transform(series).unwrap().values(), [-1.0, 0.0, 1.0])
  assert_eq(
    scaler
    .inverse_transform(scaler.transform(series).unwrap())
    .unwrap()
    .values(),
    [10.0, 15.0, 20.0],
  )
}

///|
test "robust scaler uses median and interquartile range" {
  let series = time_series([0L, 1L, 2L, 3L], [1.0, 2.0, 3.0, 100.0], "x").unwrap()
  let scaler = fit_robust_scaler(series).unwrap()
  assert_eq(scaler.center(), 2.5)
  assert_eq(scaler.scale(), 25.5)
  let restored = scaler
    .inverse_transform(scaler.transform(series).unwrap())
    .unwrap()
  for index = 0; index < series.length(); index = index + 1 {
    assert_true(
      (restored.values()[index] - series.values()[index]).abs() < 1.0e-12,
    )
  }
}

///|
test "scalers reject constant data and invalid target ranges" {
  let constant = time_series([0L, 1L], [2.0, 2.0], "x").unwrap()
  assert_eq(fit_standard_scaler(constant), Err(UndefinedScaledMetric))
  assert_eq(fit_robust_scaler(constant), Err(UndefinedScaledMetric))
  let series = time_series([0L, 1L], [1.0, 2.0], "x").unwrap()
  assert_eq(fit_min_max_scaler(series, 1.0, 1.0), Err(InvalidRange(1.0, 1.0)))
}
