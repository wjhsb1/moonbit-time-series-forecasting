///|
fn validate_transform_period(
  length : Int,
  period : Int,
) -> Result[Unit, TimeSeriesError] {
  if period <= 0 {
    return Err(InvalidPeriod(period))
  }
  if length <= period {
    return Err(InsufficientData(length, period + 1))
  }
  Ok(())
}

///|
/// Returns values from `period` observations earlier, aligned to later timestamps.
pub fn TimeSeries::lag(
  self : TimeSeries,
  period : Int,
) -> Result[TimeSeries, TimeSeriesError] {
  match validate_transform_period(self.length(), period) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let timestamps : Array[Int64] = []
  let values : Array[Double] = []
  for index = period; index < self.length(); index = index + 1 {
    timestamps.push(self.timestamps_data[index])
    values.push(self.values_data[index - period])
  }
  Ok({
    timestamps_data: timestamps,
    values_data: values,
    series_name: self.series_name,
  })
}

///|
/// Subtracts each observation from the observation `period` positions earlier.
pub fn TimeSeries::difference(
  self : TimeSeries,
  period : Int,
) -> Result[TimeSeries, TimeSeriesError] {
  match validate_transform_period(self.length(), period) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let timestamps : Array[Int64] = []
  let values : Array[Double] = []
  for index = period; index < self.length(); index = index + 1 {
    timestamps.push(self.timestamps_data[index])
    values.push(self.values_data[index] - self.values_data[index - period])
  }
  Ok({
    timestamps_data: timestamps,
    values_data: values,
    series_name: self.series_name + " difference",
  })
}

///|
pub fn TimeSeries::seasonal_difference(
  self : TimeSeries,
  period : Int,
) -> Result[TimeSeries, TimeSeriesError] {
  self.difference(period)
}

///|
/// Restores level forecasts from first-difference forecasts and the last level.
pub fn restore_first_difference(
  last_value : Double,
  differences : Array[Double],
) -> Result[Array[Double], TimeSeriesError] {
  if !finite_number(last_value) {
    return Err(NonFiniteValue(0))
  }
  let restored : Array[Double] = []
  let mut level = last_value
  for index, difference in differences {
    if !finite_number(difference) {
      return Err(NonFiniteValue(index))
    }
    level = level + difference
    if !finite_number(level) {
      return Err(NonFiniteValue(index))
    }
    restored.push(level)
  }
  Ok(restored)
}

///|
/// Fits an ordinary least-squares line against observation positions.
pub fn TimeSeries::linear_trend(
  self : TimeSeries,
) -> Result[LinearTrend, TimeSeriesError] {
  if self.length() < 3 {
    return Err(InsufficientData(self.length(), 3))
  }
  let n = self.length().to_double()
  let mean_x = (n - 1.0) / 2.0
  let mut mean_y = 0.0
  for value in self.values_data {
    mean_y = mean_y + value
  }
  mean_y = mean_y / n
  let mut numerator = 0.0
  let mut denominator = 0.0
  for index, value in self.values_data {
    let centered_x = index.to_double() - mean_x
    numerator = numerator + centered_x * (value - mean_y)
    denominator = denominator + centered_x * centered_x
  }
  let slope = numerator / denominator
  Ok({ intercept: mean_y - slope * mean_x, slope })
}

///|
/// Removes the fitted linear trend while retaining original timestamps.
pub fn TimeSeries::detrend_linear(
  self : TimeSeries,
) -> Result[TimeSeries, TimeSeriesError] {
  let trend = match self.linear_trend() {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let values : Array[Double] = []
  for index, value in self.values_data {
    values.push(value - (trend.intercept + trend.slope * index.to_double()))
  }
  Ok({
    timestamps_data: self.timestamps_data.copy(),
    values_data: values,
    series_name: self.series_name + " detrended",
  })
}
