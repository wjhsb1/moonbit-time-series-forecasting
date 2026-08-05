///|
fn validate_forecast_alignment(
  forecasts : Array[Forecast],
) -> Result[Unit, TimeSeriesError] {
  if forecasts.is_empty() {
    return Err(EmptySeries)
  }
  let expected_timestamps = forecasts[0].forecast_timestamps
  for index = 1; index < forecasts.length(); index = index + 1 {
    if forecasts[index].forecast_timestamps != expected_timestamps ||
      forecasts[index].forecast_values.length() !=
      forecasts[0].forecast_values.length() {
      return Err(ForecastAlignmentMismatch(index))
    }
  }
  Ok(())
}

///|
pub fn weighted_forecast(
  forecasts : Array[Forecast],
  weights : Array[Double],
  name : String,
) -> Result[Forecast, TimeSeriesError] {
  match validate_forecast_alignment(forecasts) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  if forecasts.length() != weights.length() {
    return Err(LengthMismatch(forecasts.length(), weights.length()))
  }
  let mut total_weight = 0.0
  for index, weight in weights {
    if !finite_number(weight) || weight < 0.0 {
      return Err(InvalidWeight(index, weight))
    }
    total_weight = total_weight + weight
  }
  if total_weight == 0.0 {
    return Err(UndefinedScaledMetric)
  }
  let values = Array::make(forecasts[0].length(), 0.0)
  for forecast_index, forecast in forecasts {
    for step = 0; step < forecast.length(); step = step + 1 {
      values[step] = values[step] +
        forecast.forecast_values[step] * weights[forecast_index] / total_weight
    }
  }
  for index, value in values {
    if !finite_number(value) {
      return Err(NonFiniteValue(index))
    }
  }
  Ok({
    forecast_timestamps: forecasts[0].forecast_timestamps.copy(),
    forecast_values: values,
    forecast_model_name: name,
  })
}

///|
pub fn mean_forecast(
  forecasts : Array[Forecast],
  name : String,
) -> Result[Forecast, TimeSeriesError] {
  if forecasts.is_empty() {
    return Err(EmptySeries)
  }
  weighted_forecast(forecasts, Array::make(forecasts.length(), 1.0), name)
}

///|
pub fn median_forecast(
  forecasts : Array[Forecast],
  name : String,
) -> Result[Forecast, TimeSeriesError] {
  match validate_forecast_alignment(forecasts) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let values : Array[Double] = []
  for step = 0; step < forecasts[0].length(); step = step + 1 {
    let step_values : Array[Double] = []
    for forecast in forecasts {
      step_values.push(forecast.forecast_values[step])
    }
    values.push(median(step_values).unwrap())
  }
  Ok({
    forecast_timestamps: forecasts[0].forecast_timestamps.copy(),
    forecast_values: values,
    forecast_model_name: name,
  })
}

///|
/// Converts nonnegative validation errors into normalized inverse-error weights.
pub fn inverse_error_weights(
  errors : Array[Double],
) -> Result[Array[Double], TimeSeriesError] {
  if errors.is_empty() {
    return Err(EmptySeries)
  }
  let mut zero_count = 0
  for index, error in errors {
    if !finite_number(error) || error < 0.0 {
      return Err(InvalidWeight(index, error))
    }
    if error == 0.0 {
      zero_count = zero_count + 1
    }
  }
  if zero_count > 0 {
    return Ok(
      errors.map(fn(error) {
        if error == 0.0 {
          1.0 / zero_count.to_double()
        } else {
          0.0
        }
      }),
    )
  }
  let inverse = errors.map(fn(error) { 1.0 / error })
  let mut total = 0.0
  for value in inverse {
    total = total + value
  }
  Ok(inverse.map(fn(value) { value / total }))
}

///|
fn candidates_by_score(result : SelectionResult) -> Array[CandidateScore] {
  let sorted = result.successful_candidates.copy()
  for index = 1; index < sorted.length(); index = index + 1 {
    let current = sorted[index]
    let mut position = index
    while position > 0 &&
          sorted[position - 1].candidate_score > current.candidate_score {
      sorted[position] = sorted[position - 1]
      position = position - 1
    }
    sorted[position] = current
  }
  sorted
}

///|
/// Refits the best successful candidates on the full series and combines them.
pub fn selection_ensemble(
  series : TimeSeries,
  selection : SelectionResult,
  steps : Int,
  max_models : Int,
) -> Result[Forecast, TimeSeriesError] {
  if max_models <= 0 {
    return Err(InvalidModelCount(max_models))
  }
  if steps <= 0 {
    return Err(InvalidSteps(steps))
  }
  let ranked = candidates_by_score(selection)
  let count = if max_models < ranked.length() {
    max_models
  } else {
    ranked.length()
  }
  if count == 0 {
    return Err(NoValidCandidate)
  }
  let forecasts : Array[Forecast] = []
  let errors : Array[Double] = []
  for index = 0; index < count; index = index + 1 {
    let forecast = match
      fit_and_forecast(series, ranked[index].candidate_spec, steps) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    forecasts.push(forecast)
    errors.push(ranked[index].candidate_score)
  }
  let weights = match inverse_error_weights(errors) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  weighted_forecast(forecasts, weights, "selection_ensemble")
}
