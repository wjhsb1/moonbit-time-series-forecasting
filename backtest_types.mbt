///|
pub(all) enum ModelSpec {
  MeanSpec
  NaiveSpec
  DriftSpec
  SeasonalNaiveSpec(Int)
  SesSpec(Double)
  HoltSpec(Double, Double)
  DampedHoltSpec(Double, Double, Double)
  HoltWintersSpec(Int, Double, Double, Double, Seasonality)
} derive(Eq, Debug)

///|
pub(all) enum BacktestConfig {
  ExpandingConfig(Int, Int, Int)
  SlidingConfig(Int, Int, Int)
} derive(Eq, Debug)

///|
pub(all) struct BacktestSplit {
  train_start : Int
  train_end : Int
  test_start : Int
  test_end : Int
} derive(Eq, Debug)

///|
pub struct BacktestFold {
  train_start : Int
  train_end : Int
  test_start : Int
  test_end : Int
  fold_forecast_timestamps : Array[Int64]
  fold_actual : Array[Double]
  fold_predicted : Array[Double]
  fold_mae : Double
  fold_rmse : Double
} derive(Eq, Debug)

///|
pub fn BacktestFold::actual(self : BacktestFold) -> Array[Double] {
  self.fold_actual.copy()
}

///|
pub fn BacktestFold::predicted(self : BacktestFold) -> Array[Double] {
  self.fold_predicted.copy()
}

///|
pub fn BacktestFold::forecast_timestamps(self : BacktestFold) -> Array[Int64] {
  self.fold_forecast_timestamps.copy()
}

///|
pub fn BacktestFold::mae(self : BacktestFold) -> Double {
  self.fold_mae
}

///|
pub fn BacktestFold::rmse(self : BacktestFold) -> Double {
  self.fold_rmse
}

///|
pub struct BacktestResult {
  backtest_model_name : String
  backtest_config : BacktestConfig
  backtest_folds : Array[BacktestFold]
  backtest_actual : Array[Double]
  backtest_predicted : Array[Double]
  backtest_mae : Double
  backtest_rmse : Double
} derive(Eq, Debug)

///|
pub fn BacktestResult::model_name(self : BacktestResult) -> String {
  self.backtest_model_name
}

///|
pub fn BacktestResult::fold_count(self : BacktestResult) -> Int {
  self.backtest_folds.length()
}

///|
pub fn BacktestResult::observation_count(self : BacktestResult) -> Int {
  self.backtest_actual.length()
}

///|
pub fn BacktestResult::mae(self : BacktestResult) -> Double {
  self.backtest_mae
}

///|
pub fn BacktestResult::rmse(self : BacktestResult) -> Double {
  self.backtest_rmse
}

///|
pub fn BacktestResult::actual(self : BacktestResult) -> Array[Double] {
  self.backtest_actual.copy()
}

///|
pub fn BacktestResult::predicted(self : BacktestResult) -> Array[Double] {
  self.backtest_predicted.copy()
}

///|
pub fn BacktestResult::fold(
  self : BacktestResult,
  index : Int,
) -> Result[BacktestFold, TimeSeriesError] {
  if index < 0 || index >= self.backtest_folds.length() {
    return Err(InvalidSlice(index, index + 1, self.backtest_folds.length()))
  }
  Ok(self.backtest_folds[index])
}

///|
pub fn BacktestResult::fold_boundaries(
  self : BacktestResult,
) -> Array[BacktestSplit] {
  self.backtest_folds.map(fn(fold) {
    {
      train_start: fold.train_start,
      train_end: fold.train_end,
      test_start: fold.test_start,
      test_end: fold.test_end,
    }
  })
}
