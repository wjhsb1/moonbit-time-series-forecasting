///|
enum SmoothingKind {
  SimpleSmoothing
  HoltSmoothing
  DampedHoltSmoothing
} derive(Eq, Debug)

///|
/// Immutable state produced by exponential-smoothing fitting.
pub struct FittedSmoothing {
  smoothing_kind : SmoothingKind
  final_level : Double
  final_trend : Double
  damping_factor : Double
  smoothing_interval : Int64
  smoothing_last_timestamp : Int64
  fitted_data : Array[Double]
  residual_data : Array[Double]
  smoothing_name : String
} derive(Eq, Debug)
