///|
/// A deterministic set of commonly used point-forecast metrics.
pub(all) struct MetricReport {
  mae : Double
  mse : Double
  rmse : Double
  bias : Double
  mape : Double
  smape : Double
  mase : Double
  directional_accuracy : Double
} derive(Eq, Debug)
