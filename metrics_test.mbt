///|
test "forecast metrics match hand values" {
  assert_eq(mae([2.0, 4.0], [1.0, 6.0]).unwrap(), 1.5)
  assert_eq(mse([2.0, 4.0], [1.0, 6.0]).unwrap(), 2.5)
  assert_true(
    (rmse([2.0, 4.0], [1.0, 6.0]).unwrap() - 2.5.sqrt()).abs() < 1.0e-12,
  )
  assert_eq(bias([2.0, 4.0], [1.0, 6.0]).unwrap(), 0.5)
}

///|
test "percentage metrics have explicit zero behavior" {
  assert_eq(mape([0.0], [1.0]), Err(UndefinedPercentageMetric(0)))
  assert_true(
    (smape([0.0, 2.0], [0.0, 4.0]).unwrap() - 100.0 / 3.0).abs() < 1.0e-12,
  )
}

///|
test "MASE uses seasonal naive training scale" {
  let score = mase([5.0, 7.0], [4.0, 9.0], [1.0, 3.0, 5.0, 7.0], 1).unwrap()
  assert_true((score - 0.75).abs() < 1.0e-12)
  assert_eq(mase([2.0], [1.0], [3.0, 3.0, 3.0], 1), Err(UndefinedScaledMetric))
}

///|
test "directional accuracy compares consecutive movements" {
  assert_eq(
    directional_accuracy([1.0, 3.0, 2.0, 4.0], [1.0, 2.0, 3.0, 4.0]).unwrap(),
    2.0 / 3.0,
  )
}

///|
test "metrics reject mismatched empty and nonfinite inputs" {
  assert_eq(mae([1.0], [1.0, 2.0]), Err(MetricLengthMismatch(1, 2)))
  assert_eq(mae([], []), Err(EmptySeries))
  assert_eq(mae([1.0], [@double.infinity]), Err(NonFiniteValue(0)))
}

///|
test "metric report contains all deterministic scores" {
  let report = metric_report(
    [2.0, 4.0, 6.0],
    [1.0, 5.0, 6.0],
    [0.0, 2.0, 4.0, 6.0],
    1,
  ).unwrap()
  assert_true(report.mae > 0.0)
  assert_true(report.rmse > 0.0)
  assert_true(report.mase >= 0.0)
  assert_true(report.directional_accuracy >= 0.0)
}
