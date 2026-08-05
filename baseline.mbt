///|
fn baseline_interval(series : TimeSeries) -> Result[Int64, TimeSeriesError] {
  if series.length() < 2 {
    return Err(InsufficientData(series.length(), 2))
  }
  series.regular_interval()
}

///|
fn make_baseline(
  series : TimeSeries,
  kind : BaselineKind,
  level : Double,
  drift : Double,
  cycle : Array[Double],
  name : String,
) -> Result[FittedBaseline, TimeSeriesError] {
  let interval = match baseline_interval(series) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  Ok({
    baseline_kind: kind,
    interval,
    last_timestamp: series.timestamps_data[series.length() - 1],
    level,
    drift,
    seasonal_cycle: cycle.copy(),
    baseline_name: name,
  })
}

///|
/// Fits the arithmetic-mean baseline.
pub fn fit_mean(series : TimeSeries) -> Result[FittedBaseline, TimeSeriesError] {
  if series.length() < 2 {
    return Err(InsufficientData(series.length(), 2))
  }
  let mut total = 0.0
  for value in series.values_data {
    total = total + value
  }
  make_baseline(
    series,
    MeanBaseline,
    total / series.length().to_double(),
    0.0,
    [],
    "mean",
  )
}

///|
/// Fits the last-observation-carried-forward baseline.
pub fn fit_naive(
  series : TimeSeries,
) -> Result[FittedBaseline, TimeSeriesError] {
  if series.length() < 2 {
    return Err(InsufficientData(series.length(), 2))
  }
  make_baseline(
    series,
    NaiveBaseline,
    series.values_data[series.length() - 1],
    0.0,
    [],
    "naive",
  )
}

///|
/// Fits a baseline that extends the average first-to-last change.
pub fn fit_drift(
  series : TimeSeries,
) -> Result[FittedBaseline, TimeSeriesError] {
  if series.length() < 2 {
    return Err(InsufficientData(series.length(), 2))
  }
  let drift = (series.values_data[series.length() - 1] - series.values_data[0]) /
    (series.length() - 1).to_double()
  make_baseline(
    series,
    DriftBaseline,
    series.values_data[series.length() - 1],
    drift,
    [],
    "drift",
  )
}

///|
/// Fits a baseline that repeats the last complete seasonal cycle.
pub fn fit_seasonal_naive(
  series : TimeSeries,
  period : Int,
) -> Result[FittedBaseline, TimeSeriesError] {
  if period <= 0 {
    return Err(InvalidPeriod(period))
  }
  if series.length() <= period {
    return Err(InsufficientData(series.length(), period + 1))
  }
  let cycle : Array[Double] = []
  for index = series.length() - period
      index < series.length()
      index = index + 1 {
    cycle.push(series.values_data[index])
  }
  make_baseline(
    series,
    SeasonalNaiveBaseline,
    cycle[period - 1],
    0.0,
    cycle,
    "seasonal_naive",
  )
}

///|
pub fn FittedBaseline::model_name(self : FittedBaseline) -> String {
  self.baseline_name
}

///|
/// Forecasts without refitting or reading future observations.
pub fn FittedBaseline::forecast(
  self : FittedBaseline,
  steps : Int,
) -> Result[Forecast, TimeSeriesError] {
  if steps <= 0 {
    return Err(InvalidSteps(steps))
  }
  let timestamps : Array[Int64] = []
  let values : Array[Double] = []
  for offset = 1; offset <= steps; offset = offset + 1 {
    timestamps.push(self.last_timestamp + self.interval * offset.to_int64())
    let value = match self.baseline_kind {
      MeanBaseline | NaiveBaseline => self.level
      DriftBaseline => self.level + self.drift * offset.to_double()
      SeasonalNaiveBaseline =>
        self.seasonal_cycle[(offset - 1) % self.seasonal_cycle.length()]
    }
    values.push(value)
  }
  Ok({
    forecast_timestamps: timestamps,
    forecast_values: values,
    forecast_model_name: self.baseline_name,
  })
}
