///|
fn validate_smoothing_parameter(
  name : String,
  value : Double,
) -> Result[Unit, TimeSeriesError] {
  if !finite_number(value) || value <= 0.0 || value > 1.0 {
    return Err(InvalidSmoothingParameter(name, value))
  }
  Ok(())
}

///|
fn smoothing_interval(series : TimeSeries) -> Result[Int64, TimeSeriesError] {
  if series.length() < 2 {
    return Err(InsufficientData(series.length(), 2))
  }
  series.regular_interval()
}

///|
/// Fits simple exponential smoothing with the first observation as initial level.
pub fn fit_ses(
  series : TimeSeries,
  alpha : Double,
) -> Result[FittedSmoothing, TimeSeriesError] {
  match validate_smoothing_parameter("alpha", alpha) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let interval = match smoothing_interval(series) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let fitted : Array[Double] = [series.values_data[0]]
  let residuals : Array[Double] = [0.0]
  let mut level = series.values_data[0]
  for index = 1; index < series.length(); index = index + 1 {
    fitted.push(level)
    residuals.push(series.values_data[index] - level)
    level = alpha * series.values_data[index] + (1.0 - alpha) * level
  }
  Ok({
    smoothing_kind: SimpleSmoothing,
    final_level: level,
    final_trend: 0.0,
    damping_factor: 1.0,
    smoothing_interval: interval,
    smoothing_last_timestamp: series.timestamps_data[series.length() - 1],
    fitted_data: fitted,
    residual_data: residuals,
    smoothing_name: "ses",
  })
}

///|
fn fit_holt_internal(
  series : TimeSeries,
  alpha : Double,
  beta : Double,
  damping : Double,
  damped : Bool,
) -> Result[FittedSmoothing, TimeSeriesError] {
  match validate_smoothing_parameter("alpha", alpha) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  match validate_smoothing_parameter("beta", beta) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  if damped {
    match validate_smoothing_parameter("damping", damping) {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
  }
  let interval = match smoothing_interval(series) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let fitted : Array[Double] = [series.values_data[0]]
  let residuals : Array[Double] = [0.0]
  let mut level = series.values_data[0]
  let mut trend = series.values_data[1] - series.values_data[0]
  for index = 1; index < series.length(); index = index + 1 {
    let forecast = level + damping * trend
    fitted.push(forecast)
    residuals.push(series.values_data[index] - forecast)
    let previous_level = level
    level = alpha * series.values_data[index] + (1.0 - alpha) * forecast
    trend = beta * (level - previous_level) + (1.0 - beta) * damping * trend
  }
  Ok({
    smoothing_kind: if damped {
      DampedHoltSmoothing
    } else {
      HoltSmoothing
    },
    final_level: level,
    final_trend: trend,
    damping_factor: damping,
    smoothing_interval: interval,
    smoothing_last_timestamp: series.timestamps_data[series.length() - 1],
    fitted_data: fitted,
    residual_data: residuals,
    smoothing_name: if damped {
      "damped_holt"
    } else {
      "holt"
    },
  })
}

///|
pub fn fit_holt(
  series : TimeSeries,
  alpha : Double,
  beta : Double,
) -> Result[FittedSmoothing, TimeSeriesError] {
  fit_holt_internal(series, alpha, beta, 1.0, false)
}

///|
pub fn fit_damped_holt(
  series : TimeSeries,
  alpha : Double,
  beta : Double,
  damping : Double,
) -> Result[FittedSmoothing, TimeSeriesError] {
  fit_holt_internal(series, alpha, beta, damping, true)
}

///|
pub fn FittedSmoothing::level(self : FittedSmoothing) -> Double {
  self.final_level
}

///|
pub fn FittedSmoothing::trend(self : FittedSmoothing) -> Double {
  self.final_trend
}

///|
pub fn FittedSmoothing::fitted_values(self : FittedSmoothing) -> Array[Double] {
  self.fitted_data.copy()
}

///|
pub fn FittedSmoothing::residuals(self : FittedSmoothing) -> Array[Double] {
  self.residual_data.copy()
}

///|
pub fn FittedSmoothing::model_name(self : FittedSmoothing) -> String {
  self.smoothing_name
}

///|
pub fn FittedSmoothing::forecast(
  self : FittedSmoothing,
  steps : Int,
) -> Result[Forecast, TimeSeriesError] {
  if steps <= 0 {
    return Err(InvalidSteps(steps))
  }
  let timestamps : Array[Int64] = []
  let values : Array[Double] = []
  let mut damped_sum = 0.0
  let mut damping_power = 1.0
  for offset = 1; offset <= steps; offset = offset + 1 {
    timestamps.push(
      self.smoothing_last_timestamp +
      self.smoothing_interval * offset.to_int64(),
    )
    let value = match self.smoothing_kind {
      SimpleSmoothing => self.final_level
      HoltSmoothing => self.final_level + self.final_trend * offset.to_double()
      DampedHoltSmoothing => {
        damping_power = damping_power * self.damping_factor
        damped_sum = damped_sum + damping_power
        self.final_level + self.final_trend * damped_sum
      }
    }
    values.push(value)
  }
  Ok({
    forecast_timestamps: timestamps,
    forecast_values: values,
    forecast_model_name: self.smoothing_name,
  })
}
