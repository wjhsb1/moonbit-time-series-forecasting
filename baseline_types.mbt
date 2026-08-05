///|
enum BaselineKind {
  MeanBaseline
  NaiveBaseline
  SeasonalNaiveBaseline
  DriftBaseline
} derive(Eq, Debug)

///|
/// A fitted baseline model. It stores only immutable forecasting state.
pub struct FittedBaseline {
  baseline_kind : BaselineKind
  interval : Int64
  last_timestamp : Int64
  level : Double
  drift : Double
  seasonal_cycle : Array[Double]
  baseline_name : String
} derive(Eq, Debug)
