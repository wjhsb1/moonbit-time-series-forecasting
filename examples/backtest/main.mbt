///|
fn main {
  let series = @ts.time_series(
    [0L, 1L, 2L, 3L, 4L, 5L, 6L, 7L, 8L, 9L],
    [2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0],
    "linear_demand",
  ).unwrap()
  let config = @ts.ExpandingConfig(5, 1, 1)
  let candidates : Array[@ts.ModelSpec] = [
    @ts.MeanSpec,
    @ts.NaiveSpec,
    @ts.DriftSpec,
    @ts.SesSpec(0.5),
    @ts.HoltSpec(0.5, 0.5),
  ]
  let selection = @ts.select_model(series, candidates, config, @ts.SelectRmse).unwrap()
  println(@ts.selection_to_json(selection))
  let ensemble = @ts.selection_ensemble(series, selection, 3, 2).unwrap()
  println(@ts.forecast_to_text(ensemble))
}
