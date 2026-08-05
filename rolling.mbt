///|
fn validate_window(
  series : TimeSeries,
  window : Int,
) -> Result[Unit, TimeSeriesError] {
  if window <= 0 {
    return Err(InvalidWindow(window))
  }
  if series.length() < window {
    return Err(InsufficientData(series.length(), window))
  }
  Ok(())
}

///|
fn trailing_timestamps(series : TimeSeries, window : Int) -> Array[Int64] {
  let timestamps : Array[Int64] = []
  for end = window - 1; end < series.length(); end = end + 1 {
    timestamps.push(series.timestamps_data[end])
  }
  timestamps
}

///|
fn rolling_series(
  series : TimeSeries,
  window : Int,
  values : Array[Double],
  suffix : String,
) -> TimeSeries {
  {
    timestamps_data: trailing_timestamps(series, window),
    values_data: values,
    series_name: series.series_name + " " + suffix,
  }
}

///|
fn window_copy(series : TimeSeries, start : Int, window : Int) -> Array[Double] {
  let values : Array[Double] = []
  for index = start; index < start + window; index = index + 1 {
    values.push(series.values_data[index])
  }
  values
}

///|
pub fn TimeSeries::moving_sum(
  self : TimeSeries,
  window : Int,
) -> Result[TimeSeries, TimeSeriesError] {
  match validate_window(self, window) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let values : Array[Double] = []
  let mut total = 0.0
  for index = 0; index < self.length(); index = index + 1 {
    total = total + self.values_data[index]
    if index >= window {
      total = total - self.values_data[index - window]
    }
    if index >= window - 1 {
      values.push(total)
    }
  }
  Ok(rolling_series(self, window, values, "moving_sum"))
}

///|
pub fn TimeSeries::moving_mean(
  self : TimeSeries,
  window : Int,
) -> Result[TimeSeries, TimeSeriesError] {
  match self.moving_sum(window) {
    Err(error) => Err(error)
    Ok(result) =>
      Ok({
        timestamps_data: result.timestamps_data,
        values_data: result.values_data.map(fn(value) {
          value / window.to_double()
        }),
        series_name: self.series_name + " moving_mean",
      })
  }
}

///|
pub fn TimeSeries::moving_min(
  self : TimeSeries,
  window : Int,
) -> Result[TimeSeries, TimeSeriesError] {
  match validate_window(self, window) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let values : Array[Double] = []
  for start = 0; start + window <= self.length(); start = start + 1 {
    let mut minimum = self.values_data[start]
    for index = start + 1; index < start + window; index = index + 1 {
      if self.values_data[index] < minimum {
        minimum = self.values_data[index]
      }
    }
    values.push(minimum)
  }
  Ok(rolling_series(self, window, values, "moving_min"))
}

///|
pub fn TimeSeries::moving_max(
  self : TimeSeries,
  window : Int,
) -> Result[TimeSeries, TimeSeriesError] {
  match validate_window(self, window) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let values : Array[Double] = []
  for start = 0; start + window <= self.length(); start = start + 1 {
    let mut maximum = self.values_data[start]
    for index = start + 1; index < start + window; index = index + 1 {
      if self.values_data[index] > maximum {
        maximum = self.values_data[index]
      }
    }
    values.push(maximum)
  }
  Ok(rolling_series(self, window, values, "moving_max"))
}

///|
pub fn TimeSeries::moving_quantile(
  self : TimeSeries,
  window : Int,
  probability : Double,
) -> Result[TimeSeries, TimeSeriesError] {
  if !finite_number(probability) || probability < 0.0 || probability > 1.0 {
    return Err(InvalidProbability(probability))
  }
  match validate_window(self, window) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let values : Array[Double] = []
  for start = 0; start + window <= self.length(); start = start + 1 {
    values.push(
      quantile(window_copy(self, start, window), probability).unwrap(),
    )
  }
  Ok(rolling_series(self, window, values, "moving_quantile"))
}

///|
pub fn TimeSeries::moving_median(
  self : TimeSeries,
  window : Int,
) -> Result[TimeSeries, TimeSeriesError] {
  self.moving_quantile(window, 0.5)
}

///|
pub fn TimeSeries::moving_standard_deviation(
  self : TimeSeries,
  window : Int,
) -> Result[TimeSeries, TimeSeriesError] {
  match validate_window(self, window) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let values : Array[Double] = []
  for start = 0; start + window <= self.length(); start = start + 1 {
    values.push(
      population_variance(window_copy(self, start, window)).unwrap().sqrt(),
    )
  }
  Ok(rolling_series(self, window, values, "moving_standard_deviation"))
}

///|
pub fn TimeSeries::weighted_moving_average(
  self : TimeSeries,
  weights : Array[Double],
) -> Result[TimeSeries, TimeSeriesError] {
  let window = weights.length()
  match validate_window(self, window) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let mut weight_total = 0.0
  for index, weight in weights {
    if !finite_number(weight) || weight < 0.0 {
      return Err(InvalidWeight(index, weight))
    }
    weight_total = weight_total + weight
  }
  if weight_total == 0.0 {
    return Err(UndefinedScaledMetric)
  }
  let values : Array[Double] = []
  for start = 0; start + window <= self.length(); start = start + 1 {
    let mut total = 0.0
    for offset = 0; offset < window; offset = offset + 1 {
      total = total + self.values_data[start + offset] * weights[offset]
    }
    values.push(total / weight_total)
  }
  Ok(rolling_series(self, window, values, "weighted_moving_average"))
}

///|
pub fn TimeSeries::exponential_moving_average(
  self : TimeSeries,
  alpha : Double,
) -> Result[TimeSeries, TimeSeriesError] {
  match validate_smoothing_parameter("alpha", alpha) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let values : Array[Double] = [self.values_data[0]]
  let mut level = self.values_data[0]
  for index = 1; index < self.length(); index = index + 1 {
    level = alpha * self.values_data[index] + (1.0 - alpha) * level
    values.push(level)
  }
  Ok({
    timestamps_data: self.timestamps_data.copy(),
    values_data: values,
    series_name: self.series_name + " exponential_moving_average",
  })
}
