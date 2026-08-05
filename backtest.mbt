///|
fn validate_split_config(
  length : Int,
  training_size : Int,
  horizon : Int,
  step : Int,
) -> Result[Unit, TimeSeriesError] {
  if length <= 0 ||
    training_size < 2 ||
    horizon <= 0 ||
    step <= 0 ||
    training_size + horizon > length {
    return Err(InvalidBacktestConfig)
  }
  Ok(())
}

///|
/// Produces chronological folds whose training prefix expands over time.
pub fn expanding_splits(
  length : Int,
  initial_training : Int,
  horizon : Int,
  step : Int,
) -> Result[Array[BacktestSplit], TimeSeriesError] {
  match validate_split_config(length, initial_training, horizon, step) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let splits : Array[BacktestSplit] = []
  let mut train_end = initial_training
  while train_end + horizon <= length {
    splits.push({
      train_start: 0,
      train_end,
      test_start: train_end,
      test_end: train_end + horizon,
    })
    train_end = train_end + step
  }
  Ok(splits)
}

///|
/// Produces chronological folds with a fixed-width sliding training window.
pub fn sliding_splits(
  length : Int,
  training_window : Int,
  horizon : Int,
  step : Int,
) -> Result[Array[BacktestSplit], TimeSeriesError] {
  match validate_split_config(length, training_window, horizon, step) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let splits : Array[BacktestSplit] = []
  let mut train_start = 0
  while train_start + training_window + horizon <= length {
    let train_end = train_start + training_window
    splits.push({
      train_start,
      train_end,
      test_start: train_end,
      test_end: train_end + horizon,
    })
    train_start = train_start + step
  }
  Ok(splits)
}

///|
pub fn ModelSpec::name(self : ModelSpec) -> String {
  match self {
    MeanSpec => "mean"
    NaiveSpec => "naive"
    DriftSpec => "drift"
    SeasonalNaiveSpec(_) => "seasonal_naive"
    SesSpec(_) => "ses"
    HoltSpec(_, _) => "holt"
    DampedHoltSpec(_, _, _) => "damped_holt"
    HoltWintersSpec(_, _, _, _, Additive) => "holt_winters_additive"
    HoltWintersSpec(_, _, _, _, Multiplicative) => "holt_winters_multiplicative"
  }
}

///|
fn fit_and_forecast(
  series : TimeSeries,
  spec : ModelSpec,
  steps : Int,
) -> Result[Forecast, TimeSeriesError] {
  match spec {
    MeanSpec =>
      match fit_mean(series) {
        Ok(model) => model.forecast(steps)
        Err(error) => Err(error)
      }
    NaiveSpec =>
      match fit_naive(series) {
        Ok(model) => model.forecast(steps)
        Err(error) => Err(error)
      }
    DriftSpec =>
      match fit_drift(series) {
        Ok(model) => model.forecast(steps)
        Err(error) => Err(error)
      }
    SeasonalNaiveSpec(period) =>
      match fit_seasonal_naive(series, period) {
        Ok(model) => model.forecast(steps)
        Err(error) => Err(error)
      }
    SesSpec(alpha) =>
      match fit_ses(series, alpha) {
        Ok(model) => model.forecast(steps)
        Err(error) => Err(error)
      }
    HoltSpec(alpha, beta) =>
      match fit_holt(series, alpha, beta) {
        Ok(model) => model.forecast(steps)
        Err(error) => Err(error)
      }
    DampedHoltSpec(alpha, beta, damping) =>
      match fit_damped_holt(series, alpha, beta, damping) {
        Ok(model) => model.forecast(steps)
        Err(error) => Err(error)
      }
    HoltWintersSpec(period, alpha, beta, gamma, mode) =>
      match fit_holt_winters(series, period, alpha, beta, gamma, mode) {
        Ok(model) => model.forecast(steps)
        Err(error) => Err(error)
      }
  }
}

///|
fn splits_for_config(
  length : Int,
  config : BacktestConfig,
) -> Result[Array[BacktestSplit], TimeSeriesError] {
  match config {
    ExpandingConfig(initial, horizon, step) =>
      expanding_splits(length, initial, horizon, step)
    SlidingConfig(window, horizon, step) =>
      sliding_splits(length, window, horizon, step)
  }
}

///|
fn config_horizon(config : BacktestConfig) -> Int {
  match config {
    ExpandingConfig(_, horizon, _) | SlidingConfig(_, horizon, _) => horizon
  }
}

///|
/// Evaluates a model on chronological folds without using future observations.
pub fn backtest(
  series : TimeSeries,
  spec : ModelSpec,
  config : BacktestConfig,
) -> Result[BacktestResult, TimeSeriesError] {
  let splits = match splits_for_config(series.length(), config) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let horizon = config_horizon(config)
  let folds : Array[BacktestFold] = []
  let all_actual : Array[Double] = []
  let all_predicted : Array[Double] = []
  for split in splits {
    let training = match series.slice(split.train_start, split.train_end) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    let testing = match series.slice(split.test_start, split.test_end) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    let forecast = match fit_and_forecast(training, spec, horizon) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    let actual = testing.values()
    let predicted = forecast.values()
    let forecast_timestamps = forecast.timestamps()
    if forecast_timestamps != testing.timestamps() {
      return Err(InvalidBacktestConfig)
    }
    let fold_mae = match mae(actual, predicted) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    let fold_rmse = match rmse(actual, predicted) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    for value in actual {
      all_actual.push(value)
    }
    for value in predicted {
      all_predicted.push(value)
    }
    folds.push({
      train_start: split.train_start,
      train_end: split.train_end,
      test_start: split.test_start,
      test_end: split.test_end,
      fold_forecast_timestamps: forecast_timestamps,
      fold_actual: actual,
      fold_predicted: predicted,
      fold_mae,
      fold_rmse,
    })
  }
  let aggregate_mae = match mae(all_actual, all_predicted) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let aggregate_rmse = match rmse(all_actual, all_predicted) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  Ok({
    backtest_model_name: spec.name(),
    backtest_config: config,
    backtest_folds: folds,
    backtest_actual: all_actual,
    backtest_predicted: all_predicted,
    backtest_mae: aggregate_mae,
    backtest_rmse: aggregate_rmse,
  })
}
