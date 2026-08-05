///|
/// Classical moving-average decomposition with explicit unavailable edges.
pub struct Decomposition {
  decomposition_mode : Seasonality
  decomposition_observed : Array[Double]
  decomposition_trend : Array[Double]
  decomposition_seasonal : Array[Double]
  decomposition_residual : Array[Double]
  decomposition_available : Array[Bool]
  decomposition_factors : Array[Double]
  decomposition_period : Int
} derive(Eq, Debug)

///|
pub fn Decomposition::length(self : Decomposition) -> Int {
  self.decomposition_observed.length()
}

///|
pub fn Decomposition::observed(self : Decomposition) -> Array[Double] {
  self.decomposition_observed.copy()
}

///|
pub fn Decomposition::trend(self : Decomposition) -> Array[Double] {
  self.decomposition_trend.copy()
}

///|
pub fn Decomposition::seasonal(self : Decomposition) -> Array[Double] {
  self.decomposition_seasonal.copy()
}

///|
pub fn Decomposition::residual(self : Decomposition) -> Array[Double] {
  self.decomposition_residual.copy()
}

///|
pub fn Decomposition::available(self : Decomposition) -> Array[Bool] {
  self.decomposition_available.copy()
}

///|
pub fn Decomposition::seasonal_factors(self : Decomposition) -> Array[Double] {
  self.decomposition_factors.copy()
}

///|
pub fn Decomposition::period(self : Decomposition) -> Int {
  self.decomposition_period
}
