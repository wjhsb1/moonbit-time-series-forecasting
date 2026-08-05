///|
fn transformed_series(
  source : TimeSeries,
  timestamps : Array[Int64],
  values : Array[Double],
  suffix : String,
) -> Result[TimeSeries, TimeSeriesError] {
  time_series(timestamps, values, source.series_name + " " + suffix)
}

///|
pub fn TimeSeries::cumulative_sum(
  self : TimeSeries,
) -> Result[TimeSeries, TimeSeriesError] {
  let values : Array[Double] = []
  let mut total = 0.0
  for index, value in self.values_data {
    total = total + value
    if !finite_number(total) {
      return Err(NonFiniteValue(index))
    }
    values.push(total)
  }
  transformed_series(
    self,
    self.timestamps_data.copy(),
    values,
    "cumulative_sum",
  )
}

///|
pub fn TimeSeries::cumulative_mean(
  self : TimeSeries,
) -> Result[TimeSeries, TimeSeriesError] {
  let sums = match self.cumulative_sum() {
    Err(error) => return Err(error)
    Ok(result) => result
  }
  let values = Array::makei(sums.length(), fn(index) {
    sums.values_data[index] / (index + 1).to_double()
  })
  transformed_series(
    self,
    self.timestamps_data.copy(),
    values,
    "cumulative_mean",
  )
}

///|
pub fn TimeSeries::percentage_change(
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
    let previous = self.values_data[index - period]
    if previous == 0.0 {
      return Err(UndefinedPercentageMetric(index - period))
    }
    timestamps.push(self.timestamps_data[index])
    values.push((self.values_data[index] - previous) / previous.abs())
  }
  transformed_series(self, timestamps, values, "percentage_change")
}

///|
pub fn TimeSeries::rebase(
  self : TimeSeries,
  base : Double,
) -> Result[TimeSeries, TimeSeriesError] {
  if !finite_number(base) {
    return Err(NonFiniteValue(0))
  }
  if self.values_data[0] == 0.0 {
    return Err(UndefinedScaledMetric)
  }
  let factor = base / self.values_data[0]
  let values : Array[Double] = []
  for index, value in self.values_data {
    let rebased = value * factor
    if !finite_number(rebased) {
      return Err(NonFiniteValue(index))
    }
    values.push(rebased)
  }
  transformed_series(self, self.timestamps_data.copy(), values, "rebased")
}

///|
pub fn TimeSeries::clip(
  self : TimeSeries,
  lower : Double,
  upper : Double,
) -> Result[TimeSeries, TimeSeriesError] {
  if !finite_number(lower) || !finite_number(upper) || lower > upper {
    return Err(InvalidRange(lower, upper))
  }
  let values = self.values_data.map(fn(value) {
    if value < lower {
      lower
    } else if value > upper {
      upper
    } else {
      value
    }
  })
  transformed_series(self, self.timestamps_data.copy(), values, "clipped")
}

///|
pub fn TimeSeries::winsorize(
  self : TimeSeries,
  lower_probability : Double,
  upper_probability : Double,
) -> Result[TimeSeries, TimeSeriesError] {
  if !finite_number(lower_probability) ||
    !finite_number(upper_probability) ||
    lower_probability < 0.0 ||
    upper_probability > 1.0 ||
    lower_probability >= upper_probability {
    return Err(InvalidRange(lower_probability, upper_probability))
  }
  let lower = quantile(self.values_data, lower_probability).unwrap()
  let upper = quantile(self.values_data, upper_probability).unwrap()
  self.clip(lower, upper)
}

///|
fn aggregate_block_values(
  values : Array[Double],
  start : Int,
  end : Int,
  mode : BlockAggregation,
) -> Double {
  match mode {
    BlockFirst => values[start]
    BlockLast => values[end - 1]
    BlockSum | BlockMean => {
      let mut total = 0.0
      for index = start; index < end; index = index + 1 {
        total = total + values[index]
      }
      if mode == BlockMean {
        total / (end - start).to_double()
      } else {
        total
      }
    }
    BlockMin => {
      let mut minimum = values[start]
      for index = start + 1; index < end; index = index + 1 {
        if values[index] < minimum {
          minimum = values[index]
        }
      }
      minimum
    }
    BlockMax => {
      let mut maximum = values[start]
      for index = start + 1; index < end; index = index + 1 {
        if values[index] > maximum {
          maximum = values[index]
        }
      }
      maximum
    }
  }
}

///|
/// Aggregates consecutive observation blocks and uses each block's final timestamp.
pub fn TimeSeries::aggregate_blocks(
  self : TimeSeries,
  block_size : Int,
  mode : BlockAggregation,
  include_partial : Bool,
) -> Result[TimeSeries, TimeSeriesError] {
  if block_size <= 0 {
    return Err(InvalidWindow(block_size))
  }
  if block_size > self.length() && !include_partial {
    return Err(InsufficientData(self.length(), block_size))
  }
  let timestamps : Array[Int64] = []
  let values : Array[Double] = []
  let mut start = 0
  while start < self.length() {
    let proposed_end = start + block_size
    let end = if proposed_end < self.length() {
      proposed_end
    } else {
      self.length()
    }
    if end - start < block_size && !include_partial {
      break
    }
    timestamps.push(self.timestamps_data[end - 1])
    values.push(aggregate_block_values(self.values_data, start, end, mode))
    start = end
  }
  transformed_series(self, timestamps, values, "block_aggregate")
}

///|
pub fn chronological_split(
  series : TimeSeries,
  training_end : Int,
) -> Result[(TimeSeries, TimeSeries), TimeSeriesError] {
  if training_end <= 0 || training_end >= series.length() {
    return Err(InvalidSlice(0, training_end, series.length()))
  }
  let training = series.slice(0, training_end).unwrap()
  let testing = series.slice(training_end, series.length()).unwrap()
  Ok((training, testing))
}
