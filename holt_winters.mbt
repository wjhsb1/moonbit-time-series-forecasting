///|
fn initial_seasonal_level(series : TimeSeries, period : Int) -> Double {
  let mut total = 0.0
  for index = 0; index < period; index = index + 1 {
    total = total + series.values_data[index]
  }
  total / period.to_double()
}

///|
fn initial_seasonal_trend(series : TimeSeries, period : Int) -> Double {
  let mut total = 0.0
  for index = 0; index < period; index = index + 1 {
    total = total +
      (series.values_data[index + period] - series.values_data[index]) /
      period.to_double()
  }
  total / period.to_double()
}

///|
fn initial_seasonal_factors(
  series : TimeSeries,
  period : Int,
  mode : Seasonality,
  level : Double,
) -> Array[Double] {
  let factors : Array[Double] = []
  for index = 0; index < period; index = index + 1 {
    factors.push(
      match mode {
        Additive => series.values_data[index] - level
        Multiplicative => series.values_data[index] / level
      },
    )
  }
  factors
}

///|
/// Fits additive or multiplicative Holt-Winters state equations.
pub fn fit_holt_winters(
  series : TimeSeries,
  period : Int,
  alpha : Double,
  beta : Double,
  gamma : Double,
  mode : Seasonality,
) -> Result[FittedHoltWinters, TimeSeriesError] {
  if period <= 0 {
    return Err(InvalidPeriod(period))
  }
  if series.length() < period * 2 {
    return Err(InsufficientData(series.length(), period * 2))
  }
  match validate_smoothing_parameter("alpha", alpha) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  match validate_smoothing_parameter("beta", beta) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  match validate_smoothing_parameter("gamma", gamma) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  if mode == Multiplicative {
    for index, value in series.values_data {
      if value <= 0.0 {
        return Err(NonPositiveMultiplicativeValue(index))
      }
    }
  }
  let interval = match series.regular_interval() {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let mut level = initial_seasonal_level(series, period)
  if mode == Multiplicative && level <= 0.0 {
    return Err(NonPositiveMultiplicativeValue(0))
  }
  let mut trend = initial_seasonal_trend(series, period)
  let factors = initial_seasonal_factors(series, period, mode, level)
  let fitted : Array[Double] = []
  let residuals : Array[Double] = []
  for index = 0; index < period; index = index + 1 {
    fitted.push(series.values_data[index])
    residuals.push(0.0)
  }
  for index = period; index < series.length(); index = index + 1 {
    let seasonal_index = index % period
    let factor = factors[seasonal_index]
    let predicted = match mode {
      Additive => level + trend + factor
      Multiplicative => (level + trend) * factor
    }
    fitted.push(predicted)
    residuals.push(series.values_data[index] - predicted)
    let previous_level = level
    match mode {
      Additive => {
        level = alpha * (series.values_data[index] - factor) +
          (1.0 - alpha) * (level + trend)
        trend = beta * (level - previous_level) + (1.0 - beta) * trend
        factors[seasonal_index] = gamma * (series.values_data[index] - level) +
          (1.0 - gamma) * factor
      }
      Multiplicative => {
        level = alpha * (series.values_data[index] / factor) +
          (1.0 - alpha) * (level + trend)
        trend = beta * (level - previous_level) + (1.0 - beta) * trend
        factors[seasonal_index] = gamma * (series.values_data[index] / level) +
          (1.0 - gamma) * factor
      }
    }
  }
  Ok({
    seasonal_mode: mode,
    seasonal_period: period,
    seasonal_level: level,
    seasonal_trend: trend,
    seasonal_factors: factors.copy(),
    seasonal_interval: interval,
    seasonal_last_timestamp: series.timestamps_data[series.length() - 1],
    seasonal_training_length: series.length(),
    seasonal_fitted_data: fitted,
    seasonal_residual_data: residuals,
    seasonal_model_name: match mode {
      Additive => "holt_winters_additive"
      Multiplicative => "holt_winters_multiplicative"
    },
  })
}

///|
pub fn FittedHoltWinters::fitted_values(
  self : FittedHoltWinters,
) -> Array[Double] {
  self.seasonal_fitted_data.copy()
}

///|
pub fn FittedHoltWinters::residuals(self : FittedHoltWinters) -> Array[Double] {
  self.seasonal_residual_data.copy()
}

///|
pub fn FittedHoltWinters::model_name(self : FittedHoltWinters) -> String {
  self.seasonal_model_name
}

///|
pub fn FittedHoltWinters::seasonal_indices(
  self : FittedHoltWinters,
) -> Array[Double] {
  self.seasonal_factors.copy()
}

///|
pub fn FittedHoltWinters::forecast(
  self : FittedHoltWinters,
  steps : Int,
) -> Result[Forecast, TimeSeriesError] {
  if steps <= 0 {
    return Err(InvalidSteps(steps))
  }
  let timestamps : Array[Int64] = []
  let values : Array[Double] = []
  for offset = 1; offset <= steps; offset = offset + 1 {
    timestamps.push(
      self.seasonal_last_timestamp + self.seasonal_interval * offset.to_int64(),
    )
    let factor_index = (self.seasonal_training_length + offset - 1) %
      self.seasonal_period
    let base = self.seasonal_level + self.seasonal_trend * offset.to_double()
    values.push(
      match self.seasonal_mode {
        Additive => base + self.seasonal_factors[factor_index]
        Multiplicative => base * self.seasonal_factors[factor_index]
      },
    )
  }
  Ok({
    forecast_timestamps: timestamps,
    forecast_values: values,
    forecast_model_name: self.seasonal_model_name,
  })
}
