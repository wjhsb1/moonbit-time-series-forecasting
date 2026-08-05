///|
test "inner alignment retains only shared timestamps" {
  let left = time_series([0L, 1L, 3L], [10.0, 20.0, 30.0], "left").unwrap()
  let right = time_series([1L, 2L, 3L], [2.0, 4.0, 5.0], "right").unwrap()
  let pair = align_series(left, right, InnerAlignment).unwrap()
  assert_eq(pair.timestamps(), [1L, 3L])
  assert_eq(pair.left_values(), [20.0, 30.0])
  assert_eq(pair.right_values(), [2.0, 5.0])
  assert_eq(pair.length(), 2)
}

///|
test "exact alignment rejects timestamp differences" {
  let left = time_series([0L, 1L], [1.0, 2.0], "left").unwrap()
  let right = time_series([0L, 2L], [1.0, 2.0], "right").unwrap()
  assert_eq(
    align_series(left, right, ExactAlignment),
    Err(SeriesAlignmentMismatch(1)),
  )
}

///|
test "aligned arithmetic and weighting produce named series" {
  let left = time_series([0L, 1L], [2.0, 4.0], "left").unwrap()
  let right = time_series([0L, 1L], [1.0, 2.0], "right").unwrap()
  assert_eq(
    combine_series(left, right, ExactAlignment, AddSeries).unwrap().values(),
    [3.0, 6.0],
  )
  assert_eq(
    combine_series(left, right, ExactAlignment, SubtractSeries)
    .unwrap()
    .values(),
    [1.0, 2.0],
  )
  assert_eq(
    combine_series(left, right, ExactAlignment, MultiplySeries)
    .unwrap()
    .values(),
    [2.0, 8.0],
  )
  assert_eq(
    combine_series(left, right, ExactAlignment, DivideSeries).unwrap().values(),
    [2.0, 2.0],
  )
  assert_eq(
    weighted_series(left, right, ExactAlignment, 3.0, 1.0).unwrap().values(),
    [1.75, 3.5],
  )
}

///|
test "aligned arithmetic rejects empty overlap zero division and weights" {
  let left = time_series([0L, 1L], [1.0, 2.0], "left").unwrap()
  let disjoint = time_series([2L, 3L], [1.0, 2.0], "right").unwrap()
  assert_eq(
    align_series(left, disjoint, InnerAlignment),
    Err(NoTimestampOverlap),
  )
  let zero = time_series([0L, 1L], [1.0, 0.0], "zero").unwrap()
  assert_eq(
    combine_series(left, zero, ExactAlignment, DivideSeries),
    Err(DivisionByZero(1)),
  )
  assert_eq(
    weighted_series(left, zero, ExactAlignment, -1.0, 1.0),
    Err(InvalidWeight(0, -1.0)),
  )
}

///|
test "cross correlation identifies a one-step delayed pattern" {
  let left = time_series([0L, 1L, 2L, 3L], [1.0, 0.0, -1.0, 0.0], "left").unwrap()
  let right = time_series([0L, 1L, 2L, 3L], [0.0, 1.0, 0.0, -1.0], "right").unwrap()
  assert_true(
    (cross_correlation(left, right, 1).unwrap() - 1.0).abs() < 1.0e-12,
  )
  let best = best_cross_correlation(left, right, 2).unwrap()
  assert_eq(best.lag, 1)
  assert_true((best.correlation - 1.0).abs() < 1.0e-12)
}
