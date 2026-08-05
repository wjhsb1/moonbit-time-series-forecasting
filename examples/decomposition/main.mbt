///|
fn main {
  let series = @ts.time_series(
    [0L, 1L, 2L, 3L, 4L, 5L, 6L, 7L],
    [9.0, 11.0, 10.0, 12.0, 11.0, 13.0, 12.0, 14.0],
    "seasonal_trend",
  ).unwrap()
  let decomposition = @ts.decompose_additive(series, 2).unwrap()
  println(@ts.decomposition_to_json(decomposition))
  let adjusted = @ts.seasonally_adjust(series, 2, @ts.Additive).unwrap()
  println(@ts.time_series_to_json(adjusted))
}
