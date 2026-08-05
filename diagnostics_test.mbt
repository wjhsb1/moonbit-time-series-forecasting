///|
test "residual summary is deterministic" {
  let summary = residual_summary([1.0, -1.0, 1.0, -1.0]).unwrap()
  assert_eq(summary.count, 4)
  assert_eq(summary.mean, 0.0)
  assert_eq(summary.mean_absolute, 1.0)
  assert_eq(summary.root_mean_square, 1.0)
  assert_eq(summary.minimum, -1.0)
  assert_eq(summary.maximum, 1.0)
}

///|
test "autocorrelation uses the full centered denominator" {
  assert_eq(autocorrelation([1.0, -1.0, 1.0, -1.0], 1).unwrap(), -0.75)
  assert_eq(autocorrelation([1.0, -1.0, 1.0, -1.0], 2).unwrap(), 0.5)
  assert_eq(autocorrelations([1.0, -1.0, 1.0, -1.0], 2).unwrap(), [-0.75, 0.5])
}

///|
test "portmanteau and Durbin-Watson statistics are finite" {
  let residuals = [1.0, -1.0, 1.0, -1.0, 1.0, -1.0]
  let result = portmanteau_statistic(residuals, 2).unwrap()
  assert_eq(result.lags, 2)
  assert_true(result.statistic > 0.0)
  assert_true(durbin_watson(residuals).unwrap() > 0.0)
}

///|
test "diagnostics validate finite data variance and lags" {
  assert_eq(residual_summary([]), Err(EmptySeries))
  assert_eq(residual_summary([@double.infinity]), Err(NonFiniteValue(0)))
  assert_eq(autocorrelation([1.0, 2.0], 0), Err(InvalidLag(0, 2)))
  assert_eq(autocorrelation([1.0, 2.0], 2), Err(InvalidLag(2, 2)))
  assert_eq(autocorrelation([2.0, 2.0, 2.0], 1), Err(UndefinedScaledMetric))
}

///|
test "sign runs count consecutive residual regimes" {
  assert_eq(sign_runs([1.0, 2.0, -1.0, -2.0, 0.0, 3.0]).unwrap(), 3)
}
