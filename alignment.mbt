///|
fn exact_alignment(
  left : TimeSeries,
  right : TimeSeries,
) -> Result[AlignedSeriesPair, TimeSeriesError] {
  if left.length() != right.length() {
    return Err(LengthMismatch(left.length(), right.length()))
  }
  for index = 0; index < left.length(); index = index + 1 {
    if left.timestamps_data[index] != right.timestamps_data[index] {
      return Err(SeriesAlignmentMismatch(index))
    }
  }
  Ok({
    aligned_timestamps: left.timestamps_data.copy(),
    aligned_left_values: left.values_data.copy(),
    aligned_right_values: right.values_data.copy(),
    aligned_left_name: left.series_name,
    aligned_right_name: right.series_name,
  })
}

///|
fn inner_alignment(
  left : TimeSeries,
  right : TimeSeries,
) -> Result[AlignedSeriesPair, TimeSeriesError] {
  let timestamps : Array[Int64] = []
  let left_values : Array[Double] = []
  let right_values : Array[Double] = []
  let mut left_index = 0
  let mut right_index = 0
  while left_index < left.length() && right_index < right.length() {
    let left_timestamp = left.timestamps_data[left_index]
    let right_timestamp = right.timestamps_data[right_index]
    if left_timestamp == right_timestamp {
      timestamps.push(left_timestamp)
      left_values.push(left.values_data[left_index])
      right_values.push(right.values_data[right_index])
      left_index = left_index + 1
      right_index = right_index + 1
    } else if left_timestamp < right_timestamp {
      left_index = left_index + 1
    } else {
      right_index = right_index + 1
    }
  }
  if timestamps.is_empty() {
    return Err(NoTimestampOverlap)
  }
  Ok({
    aligned_timestamps: timestamps,
    aligned_left_values: left_values,
    aligned_right_values: right_values,
    aligned_left_name: left.series_name,
    aligned_right_name: right.series_name,
  })
}

///|
pub fn align_series(
  left : TimeSeries,
  right : TimeSeries,
  mode : AlignmentMode,
) -> Result[AlignedSeriesPair, TimeSeriesError] {
  match mode {
    ExactAlignment => exact_alignment(left, right)
    InnerAlignment => inner_alignment(left, right)
  }
}

///|
fn operation_name(operation : SeriesOperation) -> String {
  match operation {
    AddSeries => "sum"
    SubtractSeries => "difference"
    MultiplySeries => "product"
    DivideSeries => "ratio"
  }
}

///|
pub fn combine_series(
  left : TimeSeries,
  right : TimeSeries,
  alignment : AlignmentMode,
  operation : SeriesOperation,
) -> Result[TimeSeries, TimeSeriesError] {
  let pair = match align_series(left, right, alignment) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let values : Array[Double] = []
  for index = 0; index < pair.length(); index = index + 1 {
    if operation == DivideSeries && pair.aligned_right_values[index] == 0.0 {
      return Err(DivisionByZero(index))
    }
    let value = match operation {
      AddSeries =>
        pair.aligned_left_values[index] + pair.aligned_right_values[index]
      SubtractSeries =>
        pair.aligned_left_values[index] - pair.aligned_right_values[index]
      MultiplySeries =>
        pair.aligned_left_values[index] * pair.aligned_right_values[index]
      DivideSeries =>
        pair.aligned_left_values[index] / pair.aligned_right_values[index]
    }
    if !finite_number(value) {
      return Err(NonFiniteValue(index))
    }
    values.push(value)
  }
  time_series(
    pair.aligned_timestamps,
    values,
    pair.aligned_left_name +
    "_" +
    operation_name(operation) +
    "_" +
    pair.aligned_right_name,
  )
}

///|
pub fn weighted_series(
  left : TimeSeries,
  right : TimeSeries,
  alignment : AlignmentMode,
  left_weight : Double,
  right_weight : Double,
) -> Result[TimeSeries, TimeSeriesError] {
  if !finite_number(left_weight) || left_weight < 0.0 {
    return Err(InvalidWeight(0, left_weight))
  }
  if !finite_number(right_weight) || right_weight < 0.0 {
    return Err(InvalidWeight(1, right_weight))
  }
  let total_weight = left_weight + right_weight
  if total_weight == 0.0 {
    return Err(UndefinedScaledMetric)
  }
  let pair = match align_series(left, right, alignment) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let values = Array::makei(pair.length(), fn(index) {
    (
      pair.aligned_left_values[index] * left_weight +
      pair.aligned_right_values[index] * right_weight
    ) /
    total_weight
  })
  time_series(pair.aligned_timestamps, values, "weighted_series")
}

///|
pub fn aligned_correlation(
  left : TimeSeries,
  right : TimeSeries,
  alignment : AlignmentMode,
) -> Result[Double, TimeSeriesError] {
  let pair = match align_series(left, right, alignment) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  pearson_correlation(pair.aligned_left_values, pair.aligned_right_values)
}

///|
fn cross_correlation_pair(
  pair : AlignedSeriesPair,
  lag : Int,
) -> Result[Double, TimeSeriesError] {
  let absolute_lag = if lag < 0 { -lag } else { lag }
  if absolute_lag >= pair.length() - 1 {
    return Err(InvalidLag(lag, pair.length()))
  }
  let left_values : Array[Double] = []
  let right_values : Array[Double] = []
  if lag >= 0 {
    for index = lag; index < pair.length(); index = index + 1 {
      left_values.push(pair.aligned_left_values[index - lag])
      right_values.push(pair.aligned_right_values[index])
    }
  } else {
    let shift = -lag
    for index = shift; index < pair.length(); index = index + 1 {
      left_values.push(pair.aligned_left_values[index])
      right_values.push(pair.aligned_right_values[index - shift])
    }
  }
  pearson_correlation(left_values, right_values)
}

///|
pub fn cross_correlation(
  left : TimeSeries,
  right : TimeSeries,
  lag : Int,
) -> Result[Double, TimeSeriesError] {
  let pair = match align_series(left, right, ExactAlignment) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  cross_correlation_pair(pair, lag)
}

///|
fn better_cross_correlation(
  candidate_lag : Int,
  candidate : Double,
  best_lag : Int,
  best : Double,
) -> Bool {
  if candidate.abs() != best.abs() {
    return candidate.abs() > best.abs()
  }
  if candidate != best {
    return candidate > best
  }
  let candidate_distance = if candidate_lag < 0 {
    -candidate_lag
  } else {
    candidate_lag
  }
  let best_distance = if best_lag < 0 { -best_lag } else { best_lag }
  if candidate_distance != best_distance {
    candidate_distance < best_distance
  } else {
    candidate_lag < best_lag
  }
}

///|
pub fn best_cross_correlation(
  left : TimeSeries,
  right : TimeSeries,
  max_lag : Int,
) -> Result[CrossCorrelationResult, TimeSeriesError] {
  let pair = match align_series(left, right, ExactAlignment) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if max_lag <= 0 || max_lag >= pair.length() - 1 {
    return Err(InvalidLag(max_lag, pair.length()))
  }
  let mut best_lag = -max_lag
  let mut best = match cross_correlation_pair(pair, best_lag) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  for lag = -max_lag + 1; lag <= max_lag; lag = lag + 1 {
    let correlation = match cross_correlation_pair(pair, lag) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    if better_cross_correlation(lag, correlation, best_lag, best) {
      best_lag = lag
      best = correlation
    }
  }
  Ok({
    lag: best_lag,
    correlation: best,
    paired_observations: pair.length() -
    (if best_lag < 0 { -best_lag } else { best_lag }),
  })
}
