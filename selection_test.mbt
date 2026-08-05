///|
test "selection evaluates identical folds and preserves tie order" {
  let series = time_series(
    [0L, 1L, 2L, 3L, 4L, 5L],
    [3.0, 3.0, 3.0, 3.0, 3.0, 3.0],
    "constant",
  ).unwrap()
  let result = select_model(
    series,
    [MeanSpec, NaiveSpec],
    ExpandingConfig(4, 1, 1),
    SelectRmse,
  ).unwrap()
  assert_eq(result.best_index, 0)
  assert_eq(result.success_count(), 2)
  assert_eq(result.fold_boundaries_for(0), result.fold_boundaries_for(1))
}

///|
test "selection retains typed candidate failures" {
  let series = time_series(
    [0L, 1L, 2L, 3L, 4L, 5L],
    [1.0, 2.0, 3.0, 4.0, 5.0, 6.0],
    "line",
  ).unwrap()
  let result = select_model(
    series,
    [SesSpec(0.0), NaiveSpec],
    ExpandingConfig(3, 1, 1),
    SelectMae,
  ).unwrap()
  assert_eq(result.best_index, 1)
  assert_eq(result.failure_count(), 1)
  assert_eq(
    result.failure(0).unwrap().error,
    InvalidSmoothingParameter("alpha", 0.0),
  )
}

///|
test "selection errors when every candidate fails" {
  let series = time_series([0L, 1L, 2L, 3L], [1.0, 2.0, 3.0, 4.0], "x").unwrap()
  assert_eq(
    select_model(series, [SesSpec(0.0)], ExpandingConfig(2, 1, 1), SelectRmse),
    Err(NoValidCandidate),
  )
}

///|
test "parameter grids have stable nested-loop order" {
  assert_eq(ses_grid([0.2, 0.8]), [SesSpec(0.2), SesSpec(0.8)])
  assert_eq(holt_grid([0.2, 0.8], [0.3, 0.7]), [
    HoltSpec(0.2, 0.3),
    HoltSpec(0.2, 0.7),
    HoltSpec(0.8, 0.3),
    HoltSpec(0.8, 0.7),
  ])
}
