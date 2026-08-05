///|
pub(all) struct DescriptiveStatistics {
  count : Int
  sum : Double
  minimum : Double
  maximum : Double
  range : Double
  mean : Double
  median : Double
  first_quartile : Double
  third_quartile : Double
  interquartile_range : Double
  population_variance : Double
  sample_variance : Double
  population_standard_deviation : Double
  sample_standard_deviation : Double
  median_absolute_deviation : Double
  skewness : Double
  excess_kurtosis : Double
} derive(Eq, Debug)
