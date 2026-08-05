///|
/// A finite forecast aligned to future timestamps.
pub struct Forecast {
  forecast_timestamps : Array[Int64]
  forecast_values : Array[Double]
  forecast_model_name : String
} derive(Eq, Debug)

///|
/// Builds a validated forecast value for reporting or model integration.
pub fn forecast_data(
  timestamps : Array[Int64],
  values : Array[Double],
  model_name : String,
) -> Result[Forecast, TimeSeriesError] {
  let validated = match time_series(timestamps, values, model_name) {
    Err(error) => return Err(error)
    Ok(series) => series
  }
  Ok({
    forecast_timestamps: validated.timestamps_data,
    forecast_values: validated.values_data,
    forecast_model_name: model_name,
  })
}

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
