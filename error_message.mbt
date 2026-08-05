///|
/// Returns a stable machine-readable category for an error.
pub fn TimeSeriesError::code(self : TimeSeriesError) -> String {
  match self {
    EmptySeries => "empty_series"
    LengthMismatch(_, _) => "length_mismatch"
    NonFiniteValue(_) => "nonfinite_value"
    NonIncreasingTimestamp(_) => "nonincreasing_timestamp"
    IrregularInterval(_) => "irregular_interval"
    InvalidSlice(_, _, _) => "invalid_slice"
    InvalidSteps(_) => "invalid_steps"
    InvalidPeriod(_) => "invalid_period"
    InvalidWindow(_) => "invalid_window"
    InsufficientData(_, _) => "insufficient_data"
    InvalidSmoothingParameter(_, _) => "invalid_smoothing_parameter"
    NonPositiveMultiplicativeValue(_) => "nonpositive_multiplicative_value"
    MetricLengthMismatch(_, _) => "metric_length_mismatch"
    UndefinedPercentageMetric(_) => "undefined_percentage_metric"
    UndefinedScaledMetric => "undefined_scaled_metric"
    InvalidBacktestConfig => "invalid_backtest_config"
    NoValidCandidate => "no_valid_candidate"
    InvalidLag(_, _) => "invalid_lag"
    InvalidProbability(_) => "invalid_probability"
    InvalidWeight(_, _) => "invalid_weight"
    InvalidRange(_, _) => "invalid_range"
    DuplicatePeriod(_) => "duplicate_period"
    ForecastAlignmentMismatch(_) => "forecast_alignment_mismatch"
    InvalidModelCount(_) => "invalid_model_count"
    NegativeMetricValue(_) => "negative_metric_value"
    SeriesAlignmentMismatch(_) => "series_alignment_mismatch"
    NoTimestampOverlap => "no_timestamp_overlap"
    DivisionByZero(_) => "division_by_zero"
  }
}

///|
/// Formats a concise explanation suitable for command-line output and logs.
pub fn error_message(error : TimeSeriesError) -> String {
  match error {
    EmptySeries => "the input series contains no observations"
    LengthMismatch(left, right) => "array lengths differ: \{left} and \{right}"
    NonFiniteValue(index) => "a nonfinite value occurs at index \{index}"
    NonIncreasingTimestamp(index) =>
      "timestamps stop increasing at index \{index}"
    IrregularInterval(index) =>
      "the sampling interval changes at index \{index}"
    InvalidSlice(start, end, length) =>
      "slice [\{start}, \{end}) is invalid for length \{length}"
    InvalidSteps(steps) => "forecast steps must be positive, received \{steps}"
    InvalidPeriod(period) =>
      "period must be positive and meaningful, received \{period}"
    InvalidWindow(window) => "window must be positive, received \{window}"
    InsufficientData(actual, required) =>
      "insufficient observations: have \{actual}, require \{required}"
    InvalidSmoothingParameter(name, value) =>
      "smoothing parameter \{name} is outside (0, 1]: \{value}"
    NonPositiveMultiplicativeValue(index) =>
      "multiplicative processing requires a positive value at index \{index}"
    MetricLengthMismatch(actual, predicted) =>
      "metric arrays differ in length: \{actual} and \{predicted}"
    UndefinedPercentageMetric(index) =>
      "percentage error is undefined for the zero value at index \{index}"
    UndefinedScaledMetric =>
      "the requested scaled statistic has a zero denominator"
    InvalidBacktestConfig =>
      "the backtest configuration cannot produce a complete chronological fold"
    NoValidCandidate => "all model candidates failed validation or fitting"
    InvalidLag(lag, length) =>
      "lag \{lag} is invalid for \{length} observations"
    InvalidProbability(value) =>
      "probability is outside the supported interval: \{value}"
    InvalidWeight(index, value) =>
      "weight at index \{index} is invalid: \{value}"
    InvalidRange(lower, upper) =>
      "range endpoints are invalid or unordered: \{lower}, \{upper}"
    DuplicatePeriod(period) =>
      "candidate period \{period} appears more than once"
    ForecastAlignmentMismatch(index) =>
      "forecast at index \{index} does not share the reference timestamps"
    InvalidModelCount(count) =>
      "model count must be positive, received \{count}"
    NegativeMetricValue(index) =>
      "the metric requires a nonnegative value at index \{index}"
    SeriesAlignmentMismatch(index) =>
      "series timestamps differ at index \{index}"
    NoTimestampOverlap => "the series have no timestamp in common"
    DivisionByZero(index) =>
      "series division encountered zero at aligned index \{index}"
  }
}
