///|
/// Least-squares trend over observation positions 0 through n-1.
pub(all) struct LinearTrend {
  intercept : Double
  slope : Double
} derive(Eq, Debug)
