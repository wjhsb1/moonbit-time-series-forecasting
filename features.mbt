///|
fn feature_lookback(spec : FeatureSpec) -> Result[Int, TimeSeriesError] {
  match spec {
    CurrentValue => Ok(0)
    LagValue(period) | DifferenceValue(period) =>
      if period <= 0 {
        Err(InvalidPeriod(period))
      } else {
        Ok(period)
      }
    RollingMeanValue(window)
    | RollingMinValue(window)
    | RollingMaxValue(window)
    | RollingStdValue(window) =>
      if window <= 0 {
        Err(InvalidWindow(window))
      } else {
        Ok(window - 1)
      }
  }
}

///|
fn rolling_feature_mean(
  series : TimeSeries,
  origin : Int,
  window : Int,
) -> Double {
  let mut total = 0.0
  for index = origin - window + 1; index <= origin; index = index + 1 {
    total = total + series.values_data[index]
  }
  total / window.to_double()
}

///|
fn rolling_feature_min(
  series : TimeSeries,
  origin : Int,
  window : Int,
) -> Double {
  let start = origin - window + 1
  let mut minimum = series.values_data[start]
  for index = start + 1; index <= origin; index = index + 1 {
    if series.values_data[index] < minimum {
      minimum = series.values_data[index]
    }
  }
  minimum
}

///|
fn rolling_feature_max(
  series : TimeSeries,
  origin : Int,
  window : Int,
) -> Double {
  let start = origin - window + 1
  let mut maximum = series.values_data[start]
  for index = start + 1; index <= origin; index = index + 1 {
    if series.values_data[index] > maximum {
      maximum = series.values_data[index]
    }
  }
  maximum
}

///|
fn rolling_feature_std(
  series : TimeSeries,
  origin : Int,
  window : Int,
) -> Double {
  let mean = rolling_feature_mean(series, origin, window)
  let mut total = 0.0
  for index = origin - window + 1; index <= origin; index = index + 1 {
    let centered = series.values_data[index] - mean
    total = total + centered * centered
  }
  (total / window.to_double()).sqrt()
}

///|
fn feature_value(
  series : TimeSeries,
  origin : Int,
  spec : FeatureSpec,
) -> Double {
  match spec {
    CurrentValue => series.values_data[origin]
    LagValue(period) => series.values_data[origin - period]
    DifferenceValue(period) =>
      series.values_data[origin] - series.values_data[origin - period]
    RollingMeanValue(window) => rolling_feature_mean(series, origin, window)
    RollingMinValue(window) => rolling_feature_min(series, origin, window)
    RollingMaxValue(window) => rolling_feature_max(series, origin, window)
    RollingStdValue(window) => rolling_feature_std(series, origin, window)
  }
}

///|
pub fn FeatureSpec::name(self : FeatureSpec) -> String {
  match self {
    CurrentValue => "current"
    LagValue(period) => "lag_\{period}"
    DifferenceValue(period) => "difference_\{period}"
    RollingMeanValue(window) => "rolling_mean_\{window}"
    RollingMinValue(window) => "rolling_min_\{window}"
    RollingMaxValue(window) => "rolling_max_\{window}"
    RollingStdValue(window) => "rolling_std_\{window}"
  }
}

///|
pub fn feature_names(specs : Array[FeatureSpec]) -> Array[String] {
  specs.map(fn(spec) { spec.name() })
}

///|
/// Builds chronological supervised rows using observations available at each origin.
pub fn build_forecast_features(
  series : TimeSeries,
  specs : Array[FeatureSpec],
  horizon : Int,
) -> Result[ForecastFeatureDataset, TimeSeriesError] {
  if specs.is_empty() {
    return Err(EmptySeries)
  }
  if horizon <= 0 {
    return Err(InvalidSteps(horizon))
  }
  let mut maximum_lookback = 0
  for spec in specs {
    let lookback = match feature_lookback(spec) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    if lookback > maximum_lookback {
      maximum_lookback = lookback
    }
  }
  let required = maximum_lookback + horizon + 1
  if series.length() < required {
    return Err(InsufficientData(series.length(), required))
  }
  let rows : Array[Array[Double]] = []
  let targets : Array[Double] = []
  let origin_timestamps : Array[Int64] = []
  let target_timestamps : Array[Int64] = []
  for origin = maximum_lookback
      origin + horizon < series.length()
      origin = origin + 1 {
    let row : Array[Double] = []
    for spec in specs {
      row.push(feature_value(series, origin, spec))
    }
    let target_index = origin + horizon
    rows.push(row)
    targets.push(series.values_data[target_index])
    origin_timestamps.push(series.timestamps_data[origin])
    target_timestamps.push(series.timestamps_data[target_index])
  }
  Ok({
    feature_rows: rows,
    feature_targets: targets,
    feature_origin_timestamps: origin_timestamps,
    feature_target_timestamps: target_timestamps,
    feature_specifications: specs.copy(),
    feature_horizon: horizon,
  })
}
