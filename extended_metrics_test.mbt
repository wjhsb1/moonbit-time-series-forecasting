///|
test "robust and worst-case errors match hand values" {
  assert_eq(
    median_absolute_error([1.0, 2.0, 3.0], [1.0, 4.0, 2.0]).unwrap(),
    1.0,
  )
  assert_eq(max_absolute_error([1.0, 2.0, 3.0], [1.0, 4.0, 2.0]).unwrap(), 2.0)
  assert_eq(wape([1.0, 2.0, 3.0], [1.0, 4.0, 2.0]).unwrap(), 50.0)
}

///|
test "relative errors and R squared compare against actual mean" {
  assert_eq(r_squared_score([1.0, 2.0, 3.0], [1.0, 2.0, 3.0]).unwrap(), 1.0)
  assert_eq(
    relative_absolute_error([1.0, 2.0, 3.0], [2.0, 2.0, 2.0]).unwrap(),
    1.0,
  )
  assert_eq(
    relative_squared_error([1.0, 2.0, 3.0], [2.0, 2.0, 2.0]).unwrap(),
    1.0,
  )
}

///|
test "quantile loss is asymmetric" {
  assert_eq(quantile_loss([10.0], [8.0], 0.9).unwrap(), 1.8)
  assert_true(
    (quantile_loss([10.0], [12.0], 0.9).unwrap() - 0.2).abs() < 1.0e-12,
  )
  assert_eq(quantile_loss([1.0], [1.0], 0.0), Err(InvalidProbability(0.0)))
}

///|
test "forecast skill compares model and benchmark errors" {
  let skill = forecast_skill_rmse([1.0, 2.0, 3.0], [1.0, 2.0, 3.0], [
    2.0, 2.0, 2.0,
  ]).unwrap()
  assert_eq(skill, 1.0)
  assert_eq(
    forecast_skill_rmse([1.0, 1.0], [1.0, 1.0], [1.0, 1.0]),
    Err(UndefinedScaledMetric),
  )
}

///|
test "logarithmic metrics validate nonnegative domain" {
  assert_eq(rmsle([0.0, 3.0], [0.0, 3.0]).unwrap(), 0.0)
  assert_eq(rmsle([-1.0], [0.0]), Err(NegativeMetricValue(0)))
  assert_eq(wape([0.0, 0.0], [1.0, 1.0]), Err(UndefinedScaledMetric))
}
