///|
test "series retains validated observations and name" {
  let series = time_series([100L, 110L, 120L], [1.0, 2.0, 4.0], "load").unwrap()
  assert_eq(series.length(), 3)
  assert_eq(series.name(), "load")
  assert_eq(series.timestamps(), [100L, 110L, 120L])
  assert_eq(series.values(), [1.0, 2.0, 4.0])
}

///|
test "series rejects empty and mismatched input" {
  assert_eq(time_series([], [], "empty"), Err(EmptySeries))
  assert_eq(time_series([0L, 1L], [1.0], "bad"), Err(LengthMismatch(2, 1)))
}

///|
test "series rejects nonfinite values" {
  assert_eq(
    time_series([0L], [@double.infinity], "bad"),
    Err(NonFiniteValue(0)),
  )
  assert_eq(
    time_series([0L], [@double.neg_infinity], "bad"),
    Err(NonFiniteValue(0)),
  )
}

///|
test "series requires strictly increasing timestamps" {
  assert_eq(
    time_series([10L, 10L], [1.0, 2.0], "bad"),
    Err(NonIncreasingTimestamp(1)),
  )
  assert_eq(
    time_series([10L, 9L], [1.0, 2.0], "bad"),
    Err(NonIncreasingTimestamp(1)),
  )
}

///|
test "series copies constructor and accessor arrays" {
  let timestamps = [0L, 10L]
  let values = [1.0, 2.0]
  let series = time_series(timestamps, values, "copy").unwrap()
  timestamps[0] = 99L
  values[0] = 99.0
  let returned_values = series.values()
  returned_values[1] = 77.0
  assert_eq(series.timestamps(), [0L, 10L])
  assert_eq(series.values(), [1.0, 2.0])
}

///|
test "series validates regular sampling interval" {
  let regular = time_series([0L, 5L, 10L], [1.0, 2.0, 3.0], "regular").unwrap()
  assert_eq(regular.regular_interval(), Ok(5L))
  let irregular = time_series([0L, 5L, 11L], [1.0, 2.0, 3.0], "irregular").unwrap()
  assert_eq(irregular.regular_interval(), Err(IrregularInterval(2)))
}

///|
test "series slices with aligned copied observations" {
  let series = time_series([0L, 5L, 10L, 15L], [1.0, 2.0, 3.0, 4.0], "x").unwrap()
  let sliced = series.slice(1, 3).unwrap()
  assert_eq(sliced.timestamps(), [5L, 10L])
  assert_eq(sliced.values(), [2.0, 3.0])
  assert_eq(series.head(2).unwrap().values(), [1.0, 2.0])
  assert_eq(series.tail(2).unwrap().values(), [3.0, 4.0])
  assert_eq(series.slice(3, 3), Err(InvalidSlice(3, 3, 4)))
}
