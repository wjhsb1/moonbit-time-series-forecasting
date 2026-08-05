///|
/// Stores validated, strictly ordered observations.
pub struct TimeSeries {
  timestamps_data : Array[Int64]
  values_data : Array[Double]
  series_name : String
} derive(Eq, Debug)
