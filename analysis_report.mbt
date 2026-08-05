///|
fn string_array_json(values : Array[String]) -> String {
  let mut result = "["
  for index, value in values {
    if index > 0 {
      result = result + ","
    }
    result = result + "\"\{json_escape(value)}\""
  }
  result + "]"
}

///|
fn double_matrix_json(rows : Array[Array[Double]]) -> String {
  let mut result = "["
  for index, row in rows {
    if index > 0 {
      result = result + ","
    }
    result = result + double_array_json(row)
  }
  result + "]"
}

///|
pub fn time_series_to_json(series : TimeSeries) -> String {
  "{\"name\":\"\{json_escape(series.series_name)}\",\"timestamps\":\{int64_array_json(series.timestamps_data)},\"values\":\{double_array_json(series.values_data)}}"
}

///|
pub fn metric_report_to_json(report : MetricReport) -> String {
  "{\"mae\":\{report.mae},\"mse\":\{report.mse},\"rmse\":\{report.rmse},\"bias\":\{report.bias},\"mape\":\{report.mape},\"smape\":\{report.smape},\"mase\":\{report.mase},\"directional_accuracy\":\{report.directional_accuracy}}"
}

///|
pub fn extended_metric_report_to_json(report : ExtendedMetricReport) -> String {
  "{\"median_absolute_error\":\{report.median_absolute_error},\"maximum_absolute_error\":\{report.maximum_absolute_error},\"weighted_absolute_percentage_error\":\{report.weighted_absolute_percentage_error},\"root_mean_squared_log_error\":\{report.root_mean_squared_log_error},\"relative_absolute_error\":\{report.relative_absolute_error},\"relative_squared_error\":\{report.relative_squared_error},\"r_squared\":\{report.r_squared}}"
}

///|
pub fn feature_dataset_to_json(dataset : ForecastFeatureDataset) -> String {
  "{\"horizon\":\{dataset.feature_horizon},\"feature_names\":\{string_array_json(feature_names(dataset.feature_specifications))},\"origin_timestamps\":\{int64_array_json(dataset.feature_origin_timestamps)},\"target_timestamps\":\{int64_array_json(dataset.feature_target_timestamps)},\"rows\":\{double_matrix_json(dataset.feature_rows)},\"targets\":\{double_array_json(dataset.feature_targets)}}"
}

///|
pub fn aligned_pair_to_json(pair : AlignedSeriesPair) -> String {
  "{\"left_name\":\"\{json_escape(pair.aligned_left_name)}\",\"right_name\":\"\{json_escape(pair.aligned_right_name)}\",\"timestamps\":\{int64_array_json(pair.aligned_timestamps)},\"left_values\":\{double_array_json(pair.aligned_left_values)},\"right_values\":\{double_array_json(pair.aligned_right_values)}}"
}

///|
pub fn period_diagnostic_to_json(diagnostic : PeriodDiagnostic) -> String {
  "{\"period\":\{diagnostic.period},\"observations\":\{diagnostic.observations},\"autocorrelation\":\{diagnostic.autocorrelation},\"seasonal_strength\":\{diagnostic.seasonal_strength},\"trend_strength\":\{diagnostic.trend_strength}}"
}

///|
pub fn cross_correlation_to_json(result : CrossCorrelationResult) -> String {
  "{\"lag\":\{result.lag},\"correlation\":\{result.correlation},\"paired_observations\":\{result.paired_observations}}"
}
