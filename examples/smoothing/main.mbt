///|
fn main {
  let series = @ts.time_series(
    [0L, 1L, 2L, 3L, 4L, 5L],
    [10.0, 12.0, 13.0, 16.0, 18.0, 19.0],
    "trend",
  ).unwrap()
  let ses = @ts.fit_ses(series, 0.4).unwrap()
  let holt = @ts.fit_holt(series, 0.5, 0.3).unwrap()
  let damped = @ts.fit_damped_holt(series, 0.5, 0.3, 0.9).unwrap()
  println(@ts.forecast_to_json(ses.forecast(3).unwrap()))
  println(@ts.forecast_to_json(holt.forecast(3).unwrap()))
  println(@ts.forecast_to_json(damped.forecast(3).unwrap()))
  println(
    @ts.residual_summary_to_json(
      @ts.residual_summary(holt.residuals()).unwrap(),
    ),
  )
}
