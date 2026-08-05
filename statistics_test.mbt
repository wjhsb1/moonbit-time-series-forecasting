///|
test "descriptive statistics match hand calculations" {
  let summary = describe([1.0, 2.0, 3.0, 4.0]).unwrap()
  assert_eq(summary.count, 4)
  assert_eq(summary.minimum, 1.0)
  assert_eq(summary.maximum, 4.0)
  assert_eq(summary.mean, 2.5)
  assert_eq(summary.median, 2.5)
  assert_eq(summary.first_quartile, 1.75)
  assert_eq(summary.third_quartile, 3.25)
  assert_eq(summary.population_variance, 1.25)
  assert_true((summary.sample_variance - 5.0 / 3.0).abs() < 1.0e-12)
}

///|
test "quantile uses linear interpolation and preserves input" {
  let values = [4.0, 1.0, 3.0, 2.0]
  assert_eq(quantile(values, 0.0).unwrap(), 1.0)
  assert_eq(quantile(values, 0.25).unwrap(), 1.75)
  assert_eq(quantile(values, 0.5).unwrap(), 2.5)
  assert_eq(quantile(values, 1.0).unwrap(), 4.0)
  assert_eq(values, [4.0, 1.0, 3.0, 2.0])
}

///|
test "robust spread and moments are deterministic" {
  assert_eq(median_absolute_deviation([1.0, 2.0, 3.0, 100.0]).unwrap(), 1.0)
  assert_true(skewness([1.0, 2.0, 3.0, 4.0]).unwrap().abs() < 1.0e-12)
  assert_true(excess_kurtosis([1.0, 2.0, 3.0, 4.0]).unwrap() < 0.0)
}

///|
test "covariance and correlation validate paired arrays" {
  assert_eq(
    population_covariance([1.0, 2.0, 3.0], [2.0, 4.0, 6.0]).unwrap(),
    4.0 / 3.0,
  )
  assert_true(
    (pearson_correlation([1.0, 2.0, 3.0], [2.0, 4.0, 6.0]).unwrap() - 1.0).abs() <
    1.0e-12,
  )
  assert_eq(
    population_covariance([1.0], [1.0, 2.0]),
    Err(MetricLengthMismatch(1, 2)),
  )
}

///|
test "statistics reject invalid probabilities and undefined scale" {
  assert_eq(quantile([1.0], -0.1), Err(InvalidProbability(-0.1)))
  assert_eq(quantile([1.0], 1.1), Err(InvalidProbability(1.1)))
  assert_eq(sample_variance([1.0]), Err(InsufficientData(1, 2)))
  assert_eq(skewness([2.0, 2.0, 2.0]), Err(UndefinedScaledMetric))
  assert_eq(
    pearson_correlation([1.0, 1.0], [2.0, 3.0]),
    Err(UndefinedScaledMetric),
  )
}
