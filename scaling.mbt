///|
fn scaled_series(
  source : TimeSeries,
  values : Array[Double],
  suffix : String,
) -> TimeSeries {
  {
    timestamps_data: source.timestamps_data.copy(),
    values_data: values,
    series_name: source.series_name + " " + suffix,
  }
}

///|
pub fn fit_standard_scaler(
  series : TimeSeries,
) -> Result[StandardScaler, TimeSeriesError] {
  let variance = population_variance(series.values_data).unwrap()
  if variance == 0.0 {
    return Err(UndefinedScaledMetric)
  }
  Ok({
    standard_center: array_mean(series.values_data),
    standard_scale: variance.sqrt(),
  })
}

///|
pub fn StandardScaler::mean(self : StandardScaler) -> Double {
  self.standard_center
}

///|
pub fn StandardScaler::scale(self : StandardScaler) -> Double {
  self.standard_scale
}

///|
pub fn StandardScaler::transform_value(
  self : StandardScaler,
  value : Double,
) -> Result[Double, TimeSeriesError] {
  if !finite_number(value) {
    return Err(NonFiniteValue(0))
  }
  Ok((value - self.standard_center) / self.standard_scale)
}

///|
pub fn StandardScaler::inverse_value(
  self : StandardScaler,
  value : Double,
) -> Result[Double, TimeSeriesError] {
  if !finite_number(value) {
    return Err(NonFiniteValue(0))
  }
  Ok(value * self.standard_scale + self.standard_center)
}

///|
pub fn StandardScaler::transform(
  self : StandardScaler,
  series : TimeSeries,
) -> Result[TimeSeries, TimeSeriesError] {
  let values : Array[Double] = []
  for value in series.values_data {
    values.push((value - self.standard_center) / self.standard_scale)
  }
  Ok(scaled_series(series, values, "standardized"))
}

///|
pub fn StandardScaler::inverse_transform(
  self : StandardScaler,
  series : TimeSeries,
) -> Result[TimeSeries, TimeSeriesError] {
  let values = series.values_data.map(fn(value) {
    value * self.standard_scale + self.standard_center
  })
  Ok(scaled_series(series, values, "standard_restored"))
}

///|
pub fn fit_min_max_scaler(
  series : TimeSeries,
  target_minimum : Double,
  target_maximum : Double,
) -> Result[MinMaxScaler, TimeSeriesError] {
  if !finite_number(target_minimum) ||
    !finite_number(target_maximum) ||
    target_minimum >= target_maximum {
    return Err(InvalidRange(target_minimum, target_maximum))
  }
  let statistics = describe(series.values_data).unwrap()
  if statistics.minimum == statistics.maximum {
    return Err(UndefinedScaledMetric)
  }
  Ok({
    data_minimum: statistics.minimum,
    data_maximum: statistics.maximum,
    target_minimum,
    target_maximum,
  })
}

///|
fn min_max_forward(scaler : MinMaxScaler, value : Double) -> Double {
  scaler.target_minimum +
  (value - scaler.data_minimum) /
  (scaler.data_maximum - scaler.data_minimum) *
  (scaler.target_maximum - scaler.target_minimum)
}

///|
fn min_max_inverse(scaler : MinMaxScaler, value : Double) -> Double {
  scaler.data_minimum +
  (value - scaler.target_minimum) /
  (scaler.target_maximum - scaler.target_minimum) *
  (scaler.data_maximum - scaler.data_minimum)
}

///|
pub fn MinMaxScaler::transform_value(
  self : MinMaxScaler,
  value : Double,
) -> Result[Double, TimeSeriesError] {
  if !finite_number(value) {
    return Err(NonFiniteValue(0))
  }
  Ok(min_max_forward(self, value))
}

///|
pub fn MinMaxScaler::inverse_value(
  self : MinMaxScaler,
  value : Double,
) -> Result[Double, TimeSeriesError] {
  if !finite_number(value) {
    return Err(NonFiniteValue(0))
  }
  Ok(min_max_inverse(self, value))
}

///|
pub fn MinMaxScaler::transform(
  self : MinMaxScaler,
  series : TimeSeries,
) -> Result[TimeSeries, TimeSeriesError] {
  Ok(
    scaled_series(
      series,
      series.values_data.map(fn(value) { min_max_forward(self, value) }),
      "min_max_scaled",
    ),
  )
}

///|
pub fn MinMaxScaler::inverse_transform(
  self : MinMaxScaler,
  series : TimeSeries,
) -> Result[TimeSeries, TimeSeriesError] {
  Ok(
    scaled_series(
      series,
      series.values_data.map(fn(value) { min_max_inverse(self, value) }),
      "min_max_restored",
    ),
  )
}

///|
pub fn fit_robust_scaler(
  series : TimeSeries,
) -> Result[RobustScaler, TimeSeriesError] {
  let center = median(series.values_data).unwrap()
  let q1 = quantile(series.values_data, 0.25).unwrap()
  let q3 = quantile(series.values_data, 0.75).unwrap()
  let scale = q3 - q1
  if scale == 0.0 {
    return Err(UndefinedScaledMetric)
  }
  Ok({ robust_center: center, robust_scale: scale })
}

///|
pub fn RobustScaler::center(self : RobustScaler) -> Double {
  self.robust_center
}

///|
pub fn RobustScaler::scale(self : RobustScaler) -> Double {
  self.robust_scale
}

///|
pub fn RobustScaler::transform(
  self : RobustScaler,
  series : TimeSeries,
) -> Result[TimeSeries, TimeSeriesError] {
  Ok(
    scaled_series(
      series,
      series.values_data.map(fn(value) {
        (value - self.robust_center) / self.robust_scale
      }),
      "robust_scaled",
    ),
  )
}

///|
pub fn RobustScaler::inverse_transform(
  self : RobustScaler,
  series : TimeSeries,
) -> Result[TimeSeries, TimeSeriesError] {
  Ok(
    scaled_series(
      series,
      series.values_data.map(fn(value) {
        value * self.robust_scale + self.robust_center
      }),
      "robust_restored",
    ),
  )
}
