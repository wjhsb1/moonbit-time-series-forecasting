///|
fn finite_number(value : Double) -> Bool {
  !value.is_nan() && value != @double.infinity && value != @double.neg_infinity
}

///|
/// Validates and copies a finite univariate time series.
pub fn time_series(
  timestamps : Array[Int64],
  values : Array[Double],
  name : String,
) -> Result[TimeSeries, TimeSeriesError] {
  if timestamps.is_empty() {
    return Err(EmptySeries)
  }
  if timestamps.length() != values.length() {
    return Err(LengthMismatch(timestamps.length(), values.length()))
  }
  for index, value in values {
    if !finite_number(value) {
      return Err(NonFiniteValue(index))
    }
  }
  for index = 1; index < timestamps.length(); index = index + 1 {
    if timestamps[index] <= timestamps[index - 1] {
      return Err(NonIncreasingTimestamp(index))
    }
  }
  Ok({
    timestamps_data: timestamps.copy(),
    values_data: values.copy(),
    series_name: name,
  })
}

///|
pub fn TimeSeries::length(self : TimeSeries) -> Int {
  self.values_data.length()
}

///|
pub fn TimeSeries::name(self : TimeSeries) -> String {
  self.series_name
}

///|
pub fn TimeSeries::timestamps(self : TimeSeries) -> Array[Int64] {
  self.timestamps_data.copy()
}

///|
pub fn TimeSeries::values(self : TimeSeries) -> Array[Double] {
  self.values_data.copy()
}

///|
pub fn TimeSeries::regular_interval(
  self : TimeSeries,
) -> Result[Int64, TimeSeriesError] {
  if self.length() < 2 {
    return Err(InsufficientData(self.length(), 2))
  }
  let interval = self.timestamps_data[1] - self.timestamps_data[0]
  for index = 2; index < self.length(); index = index + 1 {
    if self.timestamps_data[index] - self.timestamps_data[index - 1] != interval {
      return Err(IrregularInterval(index))
    }
  }
  Ok(interval)
}

///|
pub fn TimeSeries::slice(
  self : TimeSeries,
  start : Int,
  end : Int,
) -> Result[TimeSeries, TimeSeriesError] {
  if start < 0 || start >= end || end > self.length() {
    return Err(InvalidSlice(start, end, self.length()))
  }
  let timestamps : Array[Int64] = []
  let values : Array[Double] = []
  for index = start; index < end; index = index + 1 {
    timestamps.push(self.timestamps_data[index])
    values.push(self.values_data[index])
  }
  Ok({
    timestamps_data: timestamps,
    values_data: values,
    series_name: self.series_name,
  })
}

///|
pub fn TimeSeries::head(
  self : TimeSeries,
  count : Int,
) -> Result[TimeSeries, TimeSeriesError] {
  self.slice(0, count)
}

///|
pub fn TimeSeries::tail(
  self : TimeSeries,
  count : Int,
) -> Result[TimeSeries, TimeSeriesError] {
  if count <= 0 || count > self.length() {
    return Err(
      InvalidSlice(self.length() - count, self.length(), self.length()),
    )
  }
  self.slice(self.length() - count, self.length())
}
