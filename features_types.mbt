///|
pub(all) enum FeatureSpec {
  CurrentValue
  LagValue(Int)
  DifferenceValue(Int)
  RollingMeanValue(Int)
  RollingMinValue(Int)
  RollingMaxValue(Int)
  RollingStdValue(Int)
} derive(Eq, Debug)

///|
/// Supervised rows whose features end at an origin before each future target.
pub struct ForecastFeatureDataset {
  feature_rows : Array[Array[Double]]
  feature_targets : Array[Double]
  feature_origin_timestamps : Array[Int64]
  feature_target_timestamps : Array[Int64]
  feature_specifications : Array[FeatureSpec]
  feature_horizon : Int
} derive(Eq, Debug)

///|
pub fn ForecastFeatureDataset::row_count(self : ForecastFeatureDataset) -> Int {
  self.feature_rows.length()
}

///|
pub fn ForecastFeatureDataset::feature_count(
  self : ForecastFeatureDataset,
) -> Int {
  self.feature_specifications.length()
}

///|
pub fn ForecastFeatureDataset::horizon(self : ForecastFeatureDataset) -> Int {
  self.feature_horizon
}

///|
pub fn ForecastFeatureDataset::row(
  self : ForecastFeatureDataset,
  index : Int,
) -> Result[Array[Double], TimeSeriesError] {
  if index < 0 || index >= self.feature_rows.length() {
    return Err(InvalidSlice(index, index + 1, self.feature_rows.length()))
  }
  Ok(self.feature_rows[index].copy())
}

///|
pub fn ForecastFeatureDataset::rows(
  self : ForecastFeatureDataset,
) -> Array[Array[Double]] {
  self.feature_rows.map(fn(row) { row.copy() })
}

///|
pub fn ForecastFeatureDataset::targets(
  self : ForecastFeatureDataset,
) -> Array[Double] {
  self.feature_targets.copy()
}

///|
pub fn ForecastFeatureDataset::origin_timestamps(
  self : ForecastFeatureDataset,
) -> Array[Int64] {
  self.feature_origin_timestamps.copy()
}

///|
pub fn ForecastFeatureDataset::target_timestamps(
  self : ForecastFeatureDataset,
) -> Array[Int64] {
  self.feature_target_timestamps.copy()
}

///|
pub fn ForecastFeatureDataset::specs(
  self : ForecastFeatureDataset,
) -> Array[FeatureSpec] {
  self.feature_specifications.copy()
}
