///|
test "cumulative transforms retain timestamps" {
  let series = time_series([0L, 1L, 2L], [1.0, 2.0, 3.0], "x").unwrap()
  assert_eq(series.cumulative_sum().unwrap().values(), [1.0, 3.0, 6.0])
  assert_eq(series.cumulative_mean().unwrap().values(), [1.0, 1.5, 2.0])
  assert_eq(series.cumulative_sum().unwrap().timestamps(), [0L, 1L, 2L])
}

///|
test "percentage change and rebasing are aligned" {
  let series = time_series([0L, 1L, 2L], [10.0, 15.0, 30.0], "x").unwrap()
  assert_eq(series.percentage_change(1).unwrap().values(), [0.5, 1.0])
  assert_eq(series.percentage_change(1).unwrap().timestamps(), [1L, 2L])
  assert_eq(series.rebase(100.0).unwrap().values(), [100.0, 150.0, 300.0])
}

///|
test "clipping and winsorization preserve finite values" {
  let series = time_series([0L, 1L, 2L, 3L], [0.0, 10.0, 20.0, 100.0], "x").unwrap()
  assert_eq(series.clip(5.0, 30.0).unwrap().values(), [5.0, 10.0, 20.0, 30.0])
  assert_eq(series.winsorize(0.25, 0.75).unwrap().values(), [
    7.5, 10.0, 20.0, 40.0,
  ])
}

///|
test "block aggregation uses each block final timestamp" {
  let series = time_series([0L, 1L, 2L, 3L, 4L], [1.0, 2.0, 3.0, 4.0, 5.0], "x").unwrap()
  let mean = series.aggregate_blocks(2, BlockMean, true).unwrap()
  assert_eq(mean.values(), [1.5, 3.5, 5.0])
  assert_eq(mean.timestamps(), [1L, 3L, 4L])
  assert_eq(series.aggregate_blocks(2, BlockSum, false).unwrap().values(), [
    3.0, 7.0,
  ])
}

///|
test "chronological split returns copied aligned partitions" {
  let series = time_series([0L, 1L, 2L, 3L], [1.0, 2.0, 3.0, 4.0], "x").unwrap()
  let (training, testing) = chronological_split(series, 3).unwrap()
  assert_eq(training.values(), [1.0, 2.0, 3.0])
  assert_eq(testing.values(), [4.0])
  assert_eq(chronological_split(series, 0), Err(InvalidSlice(0, 0, 4)))
}

///|
test "sequence transformations reject undefined domains" {
  let zero = time_series([0L, 1L], [0.0, 1.0], "x").unwrap()
  assert_eq(zero.percentage_change(1), Err(UndefinedPercentageMetric(0)))
  assert_eq(zero.rebase(100.0), Err(UndefinedScaledMetric))
  assert_eq(zero.clip(2.0, 1.0), Err(InvalidRange(2.0, 1.0)))
  assert_eq(zero.aggregate_blocks(0, BlockMean, true), Err(InvalidWindow(0)))
}
