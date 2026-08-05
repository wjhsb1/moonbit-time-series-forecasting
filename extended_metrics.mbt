///|
fn absolute_errors(
  actual : Array[Double],
  predicted : Array[Double],
) -> Result[Array[Double], TimeSeriesError] {
  match validate_metric_arrays(actual, predicted) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  Ok(
    Array::makei(actual.length(), fn(index) {
      (predicted[index] - actual[index]).abs()
    }),
  )
}

///|
pub fn median_absolute_error(
  actual : Array[Double],
  predicted : Array[Double],
) -> Result[Double, TimeSeriesError] {
  let errors = match absolute_errors(actual, predicted) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  median(errors)
}

///|
pub fn max_absolute_error(
  actual : Array[Double],
  predicted : Array[Double],
) -> Result[Double, TimeSeriesError] {
  let errors = match absolute_errors(actual, predicted) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let mut maximum = errors[0]
  for index = 1; index < errors.length(); index = index + 1 {
    if errors[index] > maximum {
      maximum = errors[index]
    }
  }
  Ok(maximum)
}

///|
/// Returns total absolute error divided by total absolute actual value, in percent.
pub fn wape(
  actual : Array[Double],
  predicted : Array[Double],
) -> Result[Double, TimeSeriesError] {
  let errors = match absolute_errors(actual, predicted) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let mut numerator = 0.0
  let mut denominator = 0.0
  for index = 0; index < actual.length(); index = index + 1 {
    numerator = numerator + errors[index]
    denominator = denominator + actual[index].abs()
  }
  if denominator == 0.0 {
    return Err(UndefinedScaledMetric)
  }
  Ok(100.0 * numerator / denominator)
}

///|
pub fn rmsle(
  actual : Array[Double],
  predicted : Array[Double],
) -> Result[Double, TimeSeriesError] {
  match validate_metric_arrays(actual, predicted) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let mut total = 0.0
  for index = 0; index < actual.length(); index = index + 1 {
    if actual[index] < 0.0 || predicted[index] < 0.0 {
      return Err(NegativeMetricValue(index))
    }
    let difference = @math.ln_1p(predicted[index]) - @math.ln_1p(actual[index])
    total = total + difference * difference
  }
  Ok((total / actual.length().to_double()).sqrt())
}

///|
pub fn quantile_loss(
  actual : Array[Double],
  predicted : Array[Double],
  probability : Double,
) -> Result[Double, TimeSeriesError] {
  if !finite_number(probability) || probability <= 0.0 || probability >= 1.0 {
    return Err(InvalidProbability(probability))
  }
  match validate_metric_arrays(actual, predicted) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let mut total = 0.0
  for index = 0; index < actual.length(); index = index + 1 {
    let error = actual[index] - predicted[index]
    total = total +
      (if error >= 0.0 {
        probability * error
      } else {
        (1.0 - probability) * -error
      })
  }
  Ok(total / actual.length().to_double())
}

///|
fn mean_baseline_absolute_error(actual : Array[Double]) -> Double {
  let mean = array_mean(actual)
  let mut total = 0.0
  for value in actual {
    total = total + (value - mean).abs()
  }
  total
}

///|
fn mean_baseline_squared_error(actual : Array[Double]) -> Double {
  let mean = array_mean(actual)
  let mut total = 0.0
  for value in actual {
    let centered = value - mean
    total = total + centered * centered
  }
  total
}

///|
pub fn relative_absolute_error(
  actual : Array[Double],
  predicted : Array[Double],
) -> Result[Double, TimeSeriesError] {
  let errors = match absolute_errors(actual, predicted) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let denominator = mean_baseline_absolute_error(actual)
  if denominator == 0.0 {
    return Err(UndefinedScaledMetric)
  }
  let mut numerator = 0.0
  for error in errors {
    numerator = numerator + error
  }
  Ok(numerator / denominator)
}

///|
pub fn relative_squared_error(
  actual : Array[Double],
  predicted : Array[Double],
) -> Result[Double, TimeSeriesError] {
  match validate_metric_arrays(actual, predicted) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let denominator = mean_baseline_squared_error(actual)
  if denominator == 0.0 {
    return Err(UndefinedScaledMetric)
  }
  let mut numerator = 0.0
  for index = 0; index < actual.length(); index = index + 1 {
    let error = predicted[index] - actual[index]
    numerator = numerator + error * error
  }
  Ok(numerator / denominator)
}

///|
pub fn r_squared_score(
  actual : Array[Double],
  predicted : Array[Double],
) -> Result[Double, TimeSeriesError] {
  match relative_squared_error(actual, predicted) {
    Err(error) => Err(error)
    Ok(value) => Ok(1.0 - value)
  }
}

///|
pub fn forecast_skill_rmse(
  actual : Array[Double],
  predicted : Array[Double],
  benchmark : Array[Double],
) -> Result[Double, TimeSeriesError] {
  let model_error = match rmse(actual, predicted) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let benchmark_error = match rmse(actual, benchmark) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if benchmark_error == 0.0 {
    return Err(UndefinedScaledMetric)
  }
  Ok(1.0 - model_error / benchmark_error)
}

///|
pub fn extended_metric_report(
  actual : Array[Double],
  predicted : Array[Double],
) -> Result[ExtendedMetricReport, TimeSeriesError] {
  Ok({
    median_absolute_error: match median_absolute_error(actual, predicted) {
      Ok(v) => v
      Err(e) => return Err(e)
    },
    maximum_absolute_error: match max_absolute_error(actual, predicted) {
      Ok(v) => v
      Err(e) => return Err(e)
    },
    weighted_absolute_percentage_error: match wape(actual, predicted) {
      Ok(v) => v
      Err(e) => return Err(e)
    },
    root_mean_squared_log_error: match rmsle(actual, predicted) {
      Ok(v) => v
      Err(e) => return Err(e)
    },
    relative_absolute_error: match relative_absolute_error(actual, predicted) {
      Ok(v) => v
      Err(e) => return Err(e)
    },
    relative_squared_error: match relative_squared_error(actual, predicted) {
      Ok(v) => v
      Err(e) => return Err(e)
    },
    r_squared: match r_squared_score(actual, predicted) {
      Ok(v) => v
      Err(e) => return Err(e)
    },
  })
}
