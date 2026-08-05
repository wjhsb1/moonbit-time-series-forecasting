///|
test "error messages include rejected values" {
  assert_true(error_message(LengthMismatch(2, 3)).contains("2"))
  assert_true(error_message(LengthMismatch(2, 3)).contains("3"))
  assert_true(
    error_message(InvalidSmoothingParameter("alpha", 0.0)).contains("alpha"),
  )
  assert_true(error_message(InvalidLag(4, 3)).contains("4"))
}

///|
test "every category has a stable nonempty explanation" {
  let errors : Array[TimeSeriesError] = [
    EmptySeries,
    IrregularInterval(2),
    InvalidBacktestConfig,
    NoValidCandidate,
    NoTimestampOverlap,
    UndefinedScaledMetric,
  ]
  for error in errors {
    assert_true(error_message(error).length() > 8)
    assert_true(error.code().length() > 4)
  }
}
