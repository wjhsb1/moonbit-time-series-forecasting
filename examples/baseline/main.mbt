///|
fn main {
  let series = @ts.time_series(
    [0L, 10L, 20L, 30L, 40L],
    [12.0, 14.0, 15.0, 18.0, 20.0],
    "monthly_demand",
  ).unwrap()
  let mean = @ts.fit_mean(series).unwrap().forecast(3).unwrap()
  let naive = @ts.fit_naive(series).unwrap().forecast(3).unwrap()
  let drift = @ts.fit_drift(series).unwrap().forecast(3).unwrap()
  println(@ts.forecast_to_text(mean))
  println(@ts.forecast_to_text(naive))
  println(@ts.forecast_to_text(drift))
}
