///|
fn available_component_values(
  component : Array[Double],
  available : Array[Bool],
) -> Array[Double] {
  let values : Array[Double] = []
  for index = 0; index < component.length(); index = index + 1 {
    if available[index] {
      values.push(component[index])
    }
  }
  values
}

///|
fn component_strength(
  component : Array[Double],
  residual : Array[Double],
  available : Array[Bool],
) -> Double {
  let residual_values = available_component_values(residual, available)
  let combined : Array[Double] = []
  for index = 0; index < component.length(); index = index + 1 {
    if available[index] {
      combined.push(component[index] + residual[index])
    }
  }
  let denominator = population_variance(combined).unwrap()
  if denominator == 0.0 {
    return 0.0
  }
  let numerator = population_variance(residual_values).unwrap()
  let strength = 1.0 - numerator / denominator
  if strength < 0.0 {
    0.0
  } else if strength > 1.0 {
    1.0
  } else {
    strength
  }
}

///|
pub fn seasonal_profile(
  series : TimeSeries,
  period : Int,
  mode : Seasonality,
) -> Result[Array[Double], TimeSeriesError] {
  if period < 2 {
    return Err(InvalidPeriod(period))
  }
  if series.length() < period * 2 {
    return Err(InsufficientData(series.length(), period * 2))
  }
  if mode == Multiplicative {
    for index, value in series.values_data {
      if value <= 0.0 {
        return Err(NonPositiveMultiplicativeValue(index))
      }
    }
  }
  let totals = Array::make(period, 0.0)
  let counts = Array::make(period, 0)
  for index, value in series.values_data {
    let phase = index % period
    totals[phase] = totals[phase] + value
    counts[phase] = counts[phase] + 1
  }
  let profile = Array::make(period, 0.0)
  for phase = 0; phase < period; phase = phase + 1 {
    profile[phase] = totals[phase] / counts[phase].to_double()
  }
  let overall = array_mean(series.values_data)
  for phase = 0; phase < period; phase = phase + 1 {
    profile[phase] = match mode {
      Additive => profile[phase] - overall
      Multiplicative => profile[phase] / overall
    }
  }
  Ok(profile)
}

///|
pub fn seasonally_adjust(
  series : TimeSeries,
  period : Int,
  mode : Seasonality,
) -> Result[TimeSeries, TimeSeriesError] {
  let profile = match seasonal_profile(series, period, mode) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let values : Array[Double] = []
  for index, observed in series.values_data {
    values.push(
      match mode {
        Additive => observed - profile[index % period]
        Multiplicative => observed / profile[index % period]
      },
    )
  }
  Ok({
    timestamps_data: series.timestamps_data.copy(),
    values_data: values,
    series_name: series.series_name + " seasonally_adjusted",
  })
}

///|
pub fn diagnose_period(
  series : TimeSeries,
  period : Int,
) -> Result[PeriodDiagnostic, TimeSeriesError] {
  if period < 2 {
    return Err(InvalidPeriod(period))
  }
  if series.length() < period * 2 {
    return Err(InsufficientData(series.length(), period * 2))
  }
  let correlation = match autocorrelation(series.values_data, period) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let decomposition = match decompose_additive(series, period) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  Ok({
    period,
    observations: series.length(),
    autocorrelation: correlation,
    seasonal_strength: component_strength(
      decomposition.decomposition_seasonal,
      decomposition.decomposition_residual,
      decomposition.decomposition_available,
    ),
    trend_strength: component_strength(
      decomposition.decomposition_trend,
      decomposition.decomposition_residual,
      decomposition.decomposition_available,
    ),
  })
}

///|
/// Ranks candidates by descending absolute period autocorrelation, preserving ties.
pub fn rank_periods(
  series : TimeSeries,
  periods : Array[Int],
) -> Result[Array[PeriodDiagnostic], TimeSeriesError] {
  if periods.is_empty() {
    return Err(EmptySeries)
  }
  for index = 0; index < periods.length(); index = index + 1 {
    for prior = 0; prior < index; prior = prior + 1 {
      if periods[index] == periods[prior] {
        return Err(DuplicatePeriod(periods[index]))
      }
    }
  }
  let diagnostics : Array[PeriodDiagnostic] = []
  for period in periods {
    match diagnose_period(series, period) {
      Err(error) => return Err(error)
      Ok(result) => diagnostics.push(result)
    }
  }
  for index = 1; index < diagnostics.length(); index = index + 1 {
    let current = diagnostics[index]
    let current_score = current.autocorrelation.abs()
    let mut position = index
    while position > 0 &&
          diagnostics[position - 1].autocorrelation.abs() < current_score {
      diagnostics[position] = diagnostics[position - 1]
      position = position - 1
    }
    diagnostics[position] = current
  }
  Ok(diagnostics)
}
