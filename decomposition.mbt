///|
fn centered_trend(
  values : Array[Double],
  period : Int,
) -> (Array[Double], Array[Bool]) {
  let trend = Array::make(values.length(), 0.0)
  let available = Array::make(values.length(), false)
  let half = period / 2
  if period % 2 == 1 {
    for center = half; center < values.length() - half; center = center + 1 {
      let mut total = 0.0
      for index = center - half; index <= center + half; index = index + 1 {
        total = total + values[index]
      }
      trend[center] = total / period.to_double()
      available[center] = true
    }
  } else {
    for center = half; center < values.length() - half; center = center + 1 {
      let mut total = 0.5 * values[center - half] + 0.5 * values[center + half]
      for index = center - half + 1; index < center + half; index = index + 1 {
        total = total + values[index]
      }
      trend[center] = total / period.to_double()
      available[center] = true
    }
  }
  (trend, available)
}

///|
fn build_decomposition(
  series : TimeSeries,
  period : Int,
  mode : Seasonality,
) -> Result[Decomposition, TimeSeriesError] {
  if period < 2 {
    return Err(InvalidPeriod(period))
  }
  if series.length() < period * 2 {
    return Err(InsufficientData(series.length(), period * 2))
  }
  match series.regular_interval() {
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
  let (trend, available) = centered_trend(series.values_data, period)
  let factor_totals = Array::make(period, 0.0)
  let factor_counts = Array::make(period, 0)
  for index = 0; index < series.length(); index = index + 1 {
    if available[index] {
      let phase = index % period
      let detrended = match mode {
        Additive => series.values_data[index] - trend[index]
        Multiplicative => series.values_data[index] / trend[index]
      }
      factor_totals[phase] = factor_totals[phase] + detrended
      factor_counts[phase] = factor_counts[phase] + 1
    }
  }
  let factors = Array::make(period, if mode == Additive { 0.0 } else { 1.0 })
  for phase = 0; phase < period; phase = phase + 1 {
    if factor_counts[phase] > 0 {
      factors[phase] = factor_totals[phase] / factor_counts[phase].to_double()
    }
  }
  let mut factor_mean = 0.0
  for factor in factors {
    factor_mean = factor_mean + factor
  }
  factor_mean = factor_mean / period.to_double()
  for phase = 0; phase < period; phase = phase + 1 {
    factors[phase] = match mode {
      Additive => factors[phase] - factor_mean
      Multiplicative => factors[phase] / factor_mean
    }
  }
  let seasonal = Array::make(series.length(), 0.0)
  let residual = Array::make(
    series.length(),
    if mode == Additive {
      0.0
    } else {
      1.0
    },
  )
  for index = 0; index < series.length(); index = index + 1 {
    seasonal[index] = factors[index % period]
    if available[index] {
      residual[index] = match mode {
        Additive => series.values_data[index] - trend[index] - seasonal[index]
        Multiplicative =>
          series.values_data[index] / (trend[index] * seasonal[index])
      }
    }
  }
  Ok({
    decomposition_mode: mode,
    decomposition_observed: series.values_data.copy(),
    decomposition_trend: trend,
    decomposition_seasonal: seasonal,
    decomposition_residual: residual,
    decomposition_available: available,
    decomposition_factors: factors,
    decomposition_period: period,
  })
}

///|
pub fn decompose_additive(
  series : TimeSeries,
  period : Int,
) -> Result[Decomposition, TimeSeriesError] {
  build_decomposition(series, period, Additive)
}

///|
pub fn decompose_multiplicative(
  series : TimeSeries,
  period : Int,
) -> Result[Decomposition, TimeSeriesError] {
  build_decomposition(series, period, Multiplicative)
}
