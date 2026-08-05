///|
/// Describes rejected time-series inputs and invalid forecasting operations.
pub(all) enum TimeSeriesError {
  EmptySeries
  LengthMismatch(Int, Int)
  NonFiniteValue(Int)
  NonIncreasingTimestamp(Int)
  IrregularInterval(Int)
  InvalidSlice(Int, Int, Int)
  InvalidSteps(Int)
  InvalidPeriod(Int)
  InvalidWindow(Int)
  InsufficientData(Int, Int)
  InvalidSmoothingParameter(String, Double)
  NonPositiveMultiplicativeValue(Int)
  MetricLengthMismatch(Int, Int)
  UndefinedPercentageMetric(Int)
  UndefinedScaledMetric
  InvalidBacktestConfig
} derive(Eq, Debug)
