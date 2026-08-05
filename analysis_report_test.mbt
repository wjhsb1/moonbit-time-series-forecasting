///|
test "series and metric reports export stable JSON fields" {
  let series = time_series([0L, 1L], [1.0, 2.0], "line\nseries").unwrap()
  let series_json = time_series_to_json(series)
  assert_true(series_json.contains("line\\nseries"))
  assert_true(series_json.contains("\"timestamps\":[0,1]"))
  let report = metric_report([1.0, 2.0], [1.0, 3.0], [0.0, 1.0, 2.0], 1).unwrap()
  assert_true(metric_report_to_json(report).contains("\"rmse\""))
}

///|
test "feature and alignment reports preserve row structure" {
  let series = time_series([0L, 1L, 2L], [1.0, 2.0, 3.0], "x").unwrap()
  let dataset = build_forecast_features(series, [CurrentValue], 1).unwrap()
  let json = feature_dataset_to_json(dataset)
  assert_true(json.contains("\"feature_names\":[\"current\"]"))
  assert_true(json.contains("\"rows\":[[1],[2]]"))
  let pair = align_series(series, series, ExactAlignment).unwrap()
  assert_true(aligned_pair_to_json(pair).contains("\"right_values\":[1,2,3]"))
}

///|
test "period and extended metric reports export their measured values" {
  let series = time_series([0L, 1L, 2L, 3L], [1.0, 2.0, 1.0, 2.0], "x").unwrap()
  assert_true(
    period_diagnostic_to_json(diagnose_period(series, 2).unwrap()).contains(
      "\"period\":2",
    ),
  )
  let report = extended_metric_report([1.0, 2.0], [1.0, 3.0]).unwrap()
  assert_true(extended_metric_report_to_json(report).contains("\"r_squared\""))
}
