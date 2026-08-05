///|
pub struct StandardScaler {
  standard_center : Double
  standard_scale : Double
} derive(Eq, Debug)

///|
pub struct MinMaxScaler {
  data_minimum : Double
  data_maximum : Double
  target_minimum : Double
  target_maximum : Double
} derive(Eq, Debug)

///|
pub struct RobustScaler {
  robust_center : Double
  robust_scale : Double
} derive(Eq, Debug)
