///|
fn main {
  let series = @ts.time_series(
    [0L, 1L, 2L, 3L, 4L, 5L, 6L, 7L],
    [8.0, 12.0, 8.0, 12.0, 8.0, 12.0, 8.0, 12.0],
    "alternating_demand",
  ).unwrap()
  let diagnostic = @ts.diagnose_period(series, 2).unwrap()
  println(@ts.period_diagnostic_to_json(diagnostic))
  let additive = @ts.fit_holt_winters(series, 2, 0.5, 0.3, 0.5, @ts.Additive).unwrap()
  println(@ts.forecast_to_text(additive.forecast(4).unwrap()))
}
