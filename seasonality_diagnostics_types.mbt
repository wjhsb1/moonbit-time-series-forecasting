///|
pub(all) struct PeriodDiagnostic {
  period : Int
  observations : Int
  autocorrelation : Double
  seasonal_strength : Double
  trend_strength : Double
} derive(Eq, Debug)
