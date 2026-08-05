///|
test "expanding splits never include future observations" {
  let splits = expanding_splits(12, 6, 2, 2).unwrap()
  assert_eq(splits.length(), 3)
  for split in splits {
    assert_true(split.train_end <= split.test_start)
    assert_eq(split.test_end - split.test_start, 2)
    assert_eq(split.train_start, 0)
  }
}

///|
test "sliding splits retain training width" {
  let splits = sliding_splits(12, 5, 2, 2).unwrap()
  assert_eq(splits.length(), 3)
  for split in splits {
    assert_eq(split.train_end - split.train_start, 5)
    assert_eq(split.train_end, split.test_start)
  }
}

///|
test "backtest fits only chronological training slices" {
  let series = time_series(
    [0L, 1L, 2L, 3L, 4L, 5L, 6L, 7L],
    [1.0, 2.0, 3.0, 4.0, 100.0, 100.0, 100.0, 100.0],
    "shift",
  ).unwrap()
  let result = backtest(series, NaiveSpec, ExpandingConfig(4, 2, 2)).unwrap()
  assert_eq(result.fold_count(), 2)
  let first = result.fold(0).unwrap()
  assert_eq(first.train_end, 4)
  assert_eq(first.test_start, 4)
  assert_eq(first.predicted(), [4.0, 4.0])
  assert_eq(first.actual(), [100.0, 100.0])
  assert_eq(first.forecast_timestamps(), [4L, 5L])
}

///|
test "backtest supports baseline smoothing and seasonal specifications" {
  let series = time_series(
    [0L, 1L, 2L, 3L, 4L, 5L, 6L, 7L],
    [2.0, 4.0, 2.0, 4.0, 2.0, 4.0, 2.0, 4.0],
    "season",
  ).unwrap()
  let specs : Array[ModelSpec] = [
    MeanSpec,
    NaiveSpec,
    DriftSpec,
    SeasonalNaiveSpec(2),
    SesSpec(0.5),
    HoltSpec(0.5, 0.5),
    DampedHoltSpec(0.5, 0.5, 0.9),
    HoltWintersSpec(2, 0.5, 0.5, 0.5, Additive),
  ]
  for spec in specs {
    let result = backtest(series, spec, ExpandingConfig(4, 2, 2)).unwrap()
    assert_eq(result.observation_count(), 4)
    assert_true(result.mae() >= 0.0)
    assert_true(result.rmse() >= 0.0)
  }
}

///|
test "backtest rejects invalid split configurations" {
  assert_eq(expanding_splits(10, 0, 2, 1), Err(InvalidBacktestConfig))
  assert_eq(sliding_splits(10, 5, 0, 1), Err(InvalidBacktestConfig))
  assert_eq(expanding_splits(5, 4, 2, 1), Err(InvalidBacktestConfig))
}
