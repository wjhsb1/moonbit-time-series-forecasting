///|
pub(all) struct ResidualSummary {
  count : Int
  mean : Double
  variance : Double
  standard_deviation : Double
  mean_absolute : Double
  root_mean_square : Double
  minimum : Double
  maximum : Double
} derive(Eq, Debug)

///|
/// Portmanteau statistic without a p-value or significance claim.
pub(all) struct PortmanteauResult {
  observations : Int
  lags : Int
  statistic : Double
  autocorrelations : Array[Double]
} derive(Eq, Debug)
