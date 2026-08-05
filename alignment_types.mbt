///|
pub(all) enum AlignmentMode {
  ExactAlignment
  InnerAlignment
} derive(Eq, Debug)

///|
pub(all) enum SeriesOperation {
  AddSeries
  SubtractSeries
  MultiplySeries
  DivideSeries
} derive(Eq, Debug)

///|
pub struct AlignedSeriesPair {
  aligned_timestamps : Array[Int64]
  aligned_left_values : Array[Double]
  aligned_right_values : Array[Double]
  aligned_left_name : String
  aligned_right_name : String
} derive(Eq, Debug)

///|
pub fn AlignedSeriesPair::length(self : AlignedSeriesPair) -> Int {
  self.aligned_timestamps.length()
}

///|
pub fn AlignedSeriesPair::timestamps(self : AlignedSeriesPair) -> Array[Int64] {
  self.aligned_timestamps.copy()
}

///|
pub fn AlignedSeriesPair::left_values(
  self : AlignedSeriesPair,
) -> Array[Double] {
  self.aligned_left_values.copy()
}

///|
pub fn AlignedSeriesPair::right_values(
  self : AlignedSeriesPair,
) -> Array[Double] {
  self.aligned_right_values.copy()
}

///|
pub fn AlignedSeriesPair::left_series(self : AlignedSeriesPair) -> TimeSeries {
  {
    timestamps_data: self.aligned_timestamps.copy(),
    values_data: self.aligned_left_values.copy(),
    series_name: self.aligned_left_name,
  }
}

///|
pub fn AlignedSeriesPair::right_series(self : AlignedSeriesPair) -> TimeSeries {
  {
    timestamps_data: self.aligned_timestamps.copy(),
    values_data: self.aligned_right_values.copy(),
    series_name: self.aligned_right_name,
  }
}

///|
pub(all) struct CrossCorrelationResult {
  lag : Int
  correlation : Double
  paired_observations : Int
} derive(Eq, Debug)
