///|
fn validate_finite_values(
  values : Array[Double],
) -> Result[Unit, TimeSeriesError] {
  if values.is_empty() {
    return Err(EmptySeries)
  }
  for index, value in values {
    if !finite_number(value) {
      return Err(NonFiniteValue(index))
    }
  }
  Ok(())
}

///|
fn array_mean(values : Array[Double]) -> Double {
  let mut total = 0.0
  for value in values {
    total = total + value
  }
  total / values.length().to_double()
}

///|
pub fn residual_summary(
  residuals : Array[Double],
) -> Result[ResidualSummary, TimeSeriesError] {
  match validate_finite_values(residuals) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let mean = array_mean(residuals)
  let mut squared_total = 0.0
  let mut absolute_total = 0.0
  let mut variance_total = 0.0
  let mut minimum = residuals[0]
  let mut maximum = residuals[0]
  for value in residuals {
    squared_total = squared_total + value * value
    absolute_total = absolute_total + value.abs()
    let centered = value - mean
    variance_total = variance_total + centered * centered
    if value < minimum {
      minimum = value
    }
    if value > maximum {
      maximum = value
    }
  }
  let variance = variance_total / residuals.length().to_double()
  Ok({
    count: residuals.length(),
    mean,
    variance,
    standard_deviation: variance.sqrt(),
    mean_absolute: absolute_total / residuals.length().to_double(),
    root_mean_square: (squared_total / residuals.length().to_double()).sqrt(),
    minimum,
    maximum,
  })
}

///|
pub fn autocovariance(
  values : Array[Double],
  lag : Int,
) -> Result[Double, TimeSeriesError] {
  match validate_finite_values(values) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  if lag < 0 || lag >= values.length() {
    return Err(InvalidLag(lag, values.length()))
  }
  let mean = array_mean(values)
  let mut total = 0.0
  for index = lag; index < values.length(); index = index + 1 {
    total = total + (values[index] - mean) * (values[index - lag] - mean)
  }
  Ok(total / values.length().to_double())
}

///|
pub fn autocorrelation(
  values : Array[Double],
  lag : Int,
) -> Result[Double, TimeSeriesError] {
  if lag <= 0 || lag >= values.length() {
    return Err(InvalidLag(lag, values.length()))
  }
  let variance = match autocovariance(values, 0) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if variance == 0.0 {
    return Err(UndefinedScaledMetric)
  }
  match autocovariance(values, lag) {
    Err(error) => Err(error)
    Ok(value) => Ok(value / variance)
  }
}

///|
pub fn autocorrelations(
  values : Array[Double],
  max_lag : Int,
) -> Result[Array[Double], TimeSeriesError] {
  if max_lag <= 0 || max_lag >= values.length() {
    return Err(InvalidLag(max_lag, values.length()))
  }
  let result : Array[Double] = []
  for lag = 1; lag <= max_lag; lag = lag + 1 {
    match autocorrelation(values, lag) {
      Err(error) => return Err(error)
      Ok(value) => result.push(value)
    }
  }
  Ok(result)
}

///|
/// Computes a Ljung-Box-style Q statistic without inferring a p-value.
pub fn portmanteau_statistic(
  residuals : Array[Double],
  max_lag : Int,
) -> Result[PortmanteauResult, TimeSeriesError] {
  let correlations = match autocorrelations(residuals, max_lag) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let n = residuals.length().to_double()
  let mut total = 0.0
  for index, correlation in correlations {
    let lag = index + 1
    total = total +
      correlation * correlation / (residuals.length() - lag).to_double()
  }
  Ok({
    observations: residuals.length(),
    lags: max_lag,
    statistic: n * (n + 2.0) * total,
    autocorrelations: correlations,
  })
}

///|
pub fn durbin_watson(
  residuals : Array[Double],
) -> Result[Double, TimeSeriesError] {
  match validate_finite_values(residuals) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  if residuals.length() < 2 {
    return Err(InsufficientData(residuals.length(), 2))
  }
  let mut numerator = 0.0
  let mut denominator = 0.0
  for index, value in residuals {
    denominator = denominator + value * value
    if index > 0 {
      let difference = value - residuals[index - 1]
      numerator = numerator + difference * difference
    }
  }
  if denominator == 0.0 {
    return Err(UndefinedScaledMetric)
  }
  Ok(numerator / denominator)
}

///|
/// Counts runs of positive and negative values; zeros do not start a new run.
pub fn sign_runs(residuals : Array[Double]) -> Result[Int, TimeSeriesError] {
  match validate_finite_values(residuals) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let mut runs = 0
  let mut previous_sign = 0
  for value in residuals {
    let sign = if value > 0.0 { 1 } else if value < 0.0 { -1 } else { 0 }
    if sign != 0 && sign != previous_sign {
      runs = runs + 1
      previous_sign = sign
    }
  }
  Ok(runs)
}
