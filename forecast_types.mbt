///|
/// A finite forecast aligned to future timestamps.
pub struct Forecast {
  forecast_timestamps : Array[Int64]
  forecast_values : Array[Double]
  forecast_model_name : String
} derive(Eq, Debug)

///|
pub fn Forecast::length(self : Forecast) -> Int {
  self.forecast_values.length()
}

///|
pub fn Forecast::timestamps(self : Forecast) -> Array[Int64] {
  self.forecast_timestamps.copy()
}

///|
pub fn Forecast::values(self : Forecast) -> Array[Double] {
  self.forecast_values.copy()
}

///|
pub fn Forecast::model_name(self : Forecast) -> String {
  self.forecast_model_name
}
