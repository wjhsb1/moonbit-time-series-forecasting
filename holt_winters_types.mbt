///|
pub(all) enum Seasonality {
  Additive
  Multiplicative
} derive(Eq, Debug)

///|
/// Immutable fitted state for classical Holt-Winters forecasting.
pub struct FittedHoltWinters {
  seasonal_mode : Seasonality
  seasonal_period : Int
  seasonal_level : Double
  seasonal_trend : Double
  seasonal_factors : Array[Double]
  seasonal_interval : Int64
  seasonal_last_timestamp : Int64
  seasonal_training_length : Int
  seasonal_fitted_data : Array[Double]
  seasonal_residual_data : Array[Double]
  seasonal_model_name : String
} derive(Eq, Debug)
