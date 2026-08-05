///|
fn sorted_finite_values(
  values : Array[Double],
) -> Result[Array[Double], TimeSeriesError] {
  match validate_finite_values(values) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let sorted = values.copy()
  for index = 1; index < sorted.length(); index = index + 1 {
    let current = sorted[index]
    let mut position = index
    while position > 0 && sorted[position - 1] > current {
      sorted[position] = sorted[position - 1]
      position = position - 1
    }
    sorted[position] = current
  }
  Ok(sorted)
}

///|
fn quantile_from_sorted(values : Array[Double], probability : Double) -> Double {
  if values.length() == 1 {
    return values[0]
  }
  let position = probability * (values.length() - 1).to_double()
  let mut lower = 0
  while lower + 1 < values.length() && (lower + 1).to_double() <= position {
    lower = lower + 1
  }
  if lower == values.length() - 1 {
    return values[lower]
  }
  let fraction = position - lower.to_double()
  values[lower] + fraction * (values[lower + 1] - values[lower])
}

///|
/// Computes a linearly interpolated quantile without mutating input.
pub fn quantile(
  values : Array[Double],
  probability : Double,
) -> Result[Double, TimeSeriesError] {
  if !finite_number(probability) || probability < 0.0 || probability > 1.0 {
    return Err(InvalidProbability(probability))
  }
  let sorted = match sorted_finite_values(values) {
    Err(error) => return Err(error)
    Ok(result) => result
  }
  Ok(quantile_from_sorted(sorted, probability))
}

///|
pub fn median(values : Array[Double]) -> Result[Double, TimeSeriesError] {
  quantile(values, 0.5)
}

///|
pub fn population_variance(
  values : Array[Double],
) -> Result[Double, TimeSeriesError] {
  match validate_finite_values(values) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let mean = array_mean(values)
  let mut total = 0.0
  for value in values {
    let centered = value - mean
    total = total + centered * centered
  }
  Ok(total / values.length().to_double())
}

///|
pub fn sample_variance(
  values : Array[Double],
) -> Result[Double, TimeSeriesError] {
  match validate_finite_values(values) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  if values.length() < 2 {
    return Err(InsufficientData(values.length(), 2))
  }
  let mean = array_mean(values)
  let mut total = 0.0
  for value in values {
    let centered = value - mean
    total = total + centered * centered
  }
  Ok(total / (values.length() - 1).to_double())
}

///|
pub fn median_absolute_deviation(
  values : Array[Double],
) -> Result[Double, TimeSeriesError] {
  let center = match median(values) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let deviations = values.map(fn(value) { (value - center).abs() })
  median(deviations)
}

///|
pub fn skewness(values : Array[Double]) -> Result[Double, TimeSeriesError] {
  let variance = match population_variance(values) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if variance == 0.0 {
    return Err(UndefinedScaledMetric)
  }
  let mean = array_mean(values)
  let mut third_moment = 0.0
  for value in values {
    let centered = value - mean
    third_moment = third_moment + centered * centered * centered
  }
  third_moment = third_moment / values.length().to_double()
  Ok(third_moment / (variance.sqrt() * variance))
}

///|
pub fn excess_kurtosis(
  values : Array[Double],
) -> Result[Double, TimeSeriesError] {
  let variance = match population_variance(values) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if variance == 0.0 {
    return Err(UndefinedScaledMetric)
  }
  let mean = array_mean(values)
  let mut fourth_moment = 0.0
  for value in values {
    let centered = value - mean
    fourth_moment = fourth_moment + centered * centered * centered * centered
  }
  fourth_moment = fourth_moment / values.length().to_double()
  Ok(fourth_moment / (variance * variance) - 3.0)
}

///|
pub fn population_covariance(
  left : Array[Double],
  right : Array[Double],
) -> Result[Double, TimeSeriesError] {
  match validate_metric_arrays(left, right) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let left_mean = array_mean(left)
  let right_mean = array_mean(right)
  let mut total = 0.0
  for index = 0; index < left.length(); index = index + 1 {
    total = total + (left[index] - left_mean) * (right[index] - right_mean)
  }
  Ok(total / left.length().to_double())
}

///|
pub fn pearson_correlation(
  left : Array[Double],
  right : Array[Double],
) -> Result[Double, TimeSeriesError] {
  let covariance = match population_covariance(left, right) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let left_variance = population_variance(left).unwrap()
  let right_variance = population_variance(right).unwrap()
  if left_variance == 0.0 || right_variance == 0.0 {
    return Err(UndefinedScaledMetric)
  }
  Ok(covariance / (left_variance * right_variance).sqrt())
}

///|
pub fn describe(
  values : Array[Double],
) -> Result[DescriptiveStatistics, TimeSeriesError] {
  let sorted = match sorted_finite_values(values) {
    Err(error) => return Err(error)
    Ok(result) => result
  }
  if values.length() < 2 {
    return Err(InsufficientData(values.length(), 2))
  }
  let mut total = 0.0
  for value in values {
    total = total + value
  }
  let population = population_variance(values).unwrap()
  let sample = sample_variance(values).unwrap()
  let q1 = quantile_from_sorted(sorted, 0.25)
  let q3 = quantile_from_sorted(sorted, 0.75)
  Ok({
    count: values.length(),
    sum: total,
    minimum: sorted[0],
    maximum: sorted[sorted.length() - 1],
    range: sorted[sorted.length() - 1] - sorted[0],
    mean: total / values.length().to_double(),
    median: quantile_from_sorted(sorted, 0.5),
    first_quartile: q1,
    third_quartile: q3,
    interquartile_range: q3 - q1,
    population_variance: population,
    sample_variance: sample,
    population_standard_deviation: population.sqrt(),
    sample_standard_deviation: sample.sqrt(),
    median_absolute_deviation: median_absolute_deviation(values).unwrap(),
    skewness: match skewness(values) {
      Ok(value) => value
      Err(_) => 0.0
    },
    excess_kurtosis: match excess_kurtosis(values) {
      Ok(value) => value
      Err(_) => 0.0
    },
  })
}
