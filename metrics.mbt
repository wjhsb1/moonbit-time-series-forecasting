///|
fn validate_metric_arrays(
  actual : Array[Double],
  predicted : Array[Double],
) -> Result[Unit, TimeSeriesError] {
  if actual.length() != predicted.length() {
    return Err(MetricLengthMismatch(actual.length(), predicted.length()))
  }
  if actual.is_empty() {
    return Err(EmptySeries)
  }
  for index, value in actual {
    if !finite_number(value) {
      return Err(NonFiniteValue(index))
    }
  }
  for index, value in predicted {
    if !finite_number(value) {
      return Err(NonFiniteValue(index))
    }
  }
  Ok(())
}

///|
pub fn mae(
  actual : Array[Double],
  predicted : Array[Double],
) -> Result[Double, TimeSeriesError] {
  match validate_metric_arrays(actual, predicted) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let mut total = 0.0
  for index = 0; index < actual.length(); index = index + 1 {
    total = total + (predicted[index] - actual[index]).abs()
  }
  Ok(total / actual.length().to_double())
}

///|
pub fn mse(
  actual : Array[Double],
  predicted : Array[Double],
) -> Result[Double, TimeSeriesError] {
  match validate_metric_arrays(actual, predicted) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let mut total = 0.0
  for index = 0; index < actual.length(); index = index + 1 {
    let error = predicted[index] - actual[index]
    total = total + error * error
  }
  Ok(total / actual.length().to_double())
}

///|
pub fn rmse(
  actual : Array[Double],
  predicted : Array[Double],
) -> Result[Double, TimeSeriesError] {
  match mse(actual, predicted) {
    Ok(value) => Ok(value.sqrt())
    Err(error) => Err(error)
  }
}

///|
/// Positive bias means forecasts are high on average.
pub fn bias(
  actual : Array[Double],
  predicted : Array[Double],
) -> Result[Double, TimeSeriesError] {
  match validate_metric_arrays(actual, predicted) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let mut total = 0.0
  for index = 0; index < actual.length(); index = index + 1 {
    total = total + predicted[index] - actual[index]
  }
  Ok(total / actual.length().to_double())
}

///|
/// Returns mean absolute percentage error in percent.
pub fn mape(
  actual : Array[Double],
  predicted : Array[Double],
) -> Result[Double, TimeSeriesError] {
  match validate_metric_arrays(actual, predicted) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let mut total = 0.0
  for index = 0; index < actual.length(); index = index + 1 {
    if actual[index] == 0.0 {
      return Err(UndefinedPercentageMetric(index))
    }
    total = total +
      (predicted[index] - actual[index]).abs() / actual[index].abs()
  }
  Ok(100.0 * total / actual.length().to_double())
}

///|
/// Returns symmetric mean absolute percentage error in percent.
pub fn smape(
  actual : Array[Double],
  predicted : Array[Double],
) -> Result[Double, TimeSeriesError] {
  match validate_metric_arrays(actual, predicted) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let mut total = 0.0
  for index = 0; index < actual.length(); index = index + 1 {
    let denominator = actual[index].abs() + predicted[index].abs()
    if denominator > 0.0 {
      total = total +
        2.0 * (predicted[index] - actual[index]).abs() / denominator
    }
  }
  Ok(100.0 * total / actual.length().to_double())
}

///|
/// Scales MAE by the in-sample seasonal-naive error.
pub fn mase(
  actual : Array[Double],
  predicted : Array[Double],
  training : Array[Double],
  period : Int,
) -> Result[Double, TimeSeriesError] {
  let forecast_mae = match mae(actual, predicted) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if period <= 0 {
    return Err(InvalidPeriod(period))
  }
  if training.length() <= period {
    return Err(InsufficientData(training.length(), period + 1))
  }
  for index, value in training {
    if !finite_number(value) {
      return Err(NonFiniteValue(index))
    }
  }
  let mut scale = 0.0
  for index = period; index < training.length(); index = index + 1 {
    scale = scale + (training[index] - training[index - period]).abs()
  }
  scale = scale / (training.length() - period).to_double()
  if scale == 0.0 {
    return Err(UndefinedScaledMetric)
  }
  Ok(forecast_mae / scale)
}

///|
pub fn directional_accuracy(
  actual : Array[Double],
  predicted : Array[Double],
) -> Result[Double, TimeSeriesError] {
  match validate_metric_arrays(actual, predicted) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  if actual.length() < 2 {
    return Err(InsufficientData(actual.length(), 2))
  }
  let mut matches = 0
  for index = 1; index < actual.length(); index = index + 1 {
    let actual_change = actual[index] - actual[index - 1]
    let predicted_change = predicted[index] - predicted[index - 1]
    if (actual_change > 0.0 && predicted_change > 0.0) ||
      (actual_change < 0.0 && predicted_change < 0.0) ||
      (actual_change == 0.0 && predicted_change == 0.0) {
      matches = matches + 1
    }
  }
  Ok(matches.to_double() / (actual.length() - 1).to_double())
}

///|
pub fn metric_report(
  actual : Array[Double],
  predicted : Array[Double],
  training : Array[Double],
  period : Int,
) -> Result[MetricReport, TimeSeriesError] {
  let mae_value = match mae(actual, predicted) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let mse_value = match mse(actual, predicted) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let bias_value = match bias(actual, predicted) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let mape_value = match mape(actual, predicted) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let smape_value = match smape(actual, predicted) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let mase_value = match mase(actual, predicted, training, period) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let directional_value = match directional_accuracy(actual, predicted) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  Ok({
    mae: mae_value,
    mse: mse_value,
    rmse: mse_value.sqrt(),
    bias: bias_value,
    mape: mape_value,
    smape: smape_value,
    mase: mase_value,
    directional_accuracy: directional_value,
  })
}
