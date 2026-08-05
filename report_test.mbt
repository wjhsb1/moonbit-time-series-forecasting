///|
test "forecast JSON uses strict control escapes" {
  let series = time_series([0L, 1L], [1.0, 2.0], "x").unwrap()
  let base = fit_naive(series).unwrap().forecast(1).unwrap()
  let forecast = forecast_data(
    base.timestamps(),
    base.values(),
    "season\nmodel\u{0}",
  ).unwrap()
  let json = forecast_to_json(forecast)
  assert_true(json.contains("season\\nmodel\\u0000"))
  assert_false(json.contains("\\u{"))
  assert_true(json.contains("\"timestamps\":[2]"))
}

///|
test "forecast text includes model and aligned rows" {
  let series = time_series([0L, 5L], [1.0, 2.0], "x").unwrap()
  let text = forecast_to_text(fit_naive(series).unwrap().forecast(2).unwrap())
  assert_true(text.contains("model: naive"))
  assert_true(text.contains("10,2"))
  assert_true(text.contains("15,2"))
}

///|
test "decomposition backtest selection and diagnostics export JSON" {
  let series = time_series(
    [0L, 1L, 2L, 3L, 4L, 5L],
    [2.0, 4.0, 2.0, 4.0, 2.0, 4.0],
    "x",
  ).unwrap()
  let decomposition = decompose_additive(series, 2).unwrap()
  assert_true(decomposition_to_json(decomposition).contains("\"available\""))
  let backtest_result = backtest(series, NaiveSpec, ExpandingConfig(4, 1, 1)).unwrap()
  assert_true(backtest_to_json(backtest_result).contains("\"folds\""))
  let selection = select_model(
    series,
    [MeanSpec, NaiveSpec],
    ExpandingConfig(4, 1, 1),
    SelectMae,
  ).unwrap()
  assert_true(selection_to_json(selection).contains("\"best_index\""))
  let summary = residual_summary([1.0, -1.0]).unwrap()
  assert_true(residual_summary_to_json(summary).contains("\"mean\":0"))
}
