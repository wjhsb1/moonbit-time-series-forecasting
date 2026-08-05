///|
fn json_escape(value : String) -> String {
  let mut result = ""
  for character in value {
    let escaped = match character {
      '\\' => "\\\\"
      '\"' => "\\\""
      '\b' => "\\b"
      '\n' => "\\n"
      '\r' => "\\r"
      '\t' => "\\t"
      _ =>
        if character.to_int() < 0x20 {
          let digits = [
            "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d",
            "e", "f",
          ]
          let code = character.to_int()
          "\\u00" + digits[code / 16] + digits[code % 16]
        } else {
          character.to_string()
        }
    }
    result = result + escaped
  }
  result
}

///|
fn double_array_json(values : Array[Double]) -> String {
  let mut result = "["
  for index, value in values {
    if index > 0 {
      result = result + ","
    }
    result = result + "\{value}"
  }
  result + "]"
}

///|
fn int64_array_json(values : Array[Int64]) -> String {
  let mut result = "["
  for index, value in values {
    if index > 0 {
      result = result + ","
    }
    result = result + "\{value}"
  }
  result + "]"
}

///|
fn bool_array_json(values : Array[Bool]) -> String {
  let mut result = "["
  for index, value in values {
    if index > 0 {
      result = result + ","
    }
    result = result + (if value { "true" } else { "false" })
  }
  result + "]"
}

///|
pub fn forecast_to_json(forecast : Forecast) -> String {
  "{\"model\":\"\{json_escape(forecast.forecast_model_name)}\",\"timestamps\":\{int64_array_json(forecast.forecast_timestamps)},\"values\":\{double_array_json(forecast.forecast_values)}}"
}

///|
pub fn forecast_to_text(forecast : Forecast) -> String {
  let mut result = "model: \{forecast.forecast_model_name}\ntimestamp,value\n"
  for index = 0; index < forecast.length(); index = index + 1 {
    result = result +
      "\{forecast.forecast_timestamps[index]},\{forecast.forecast_values[index]}\n"
  }
  result
}

///|
pub fn decomposition_to_json(result : Decomposition) -> String {
  let mode = match result.decomposition_mode {
    Additive => "additive"
    Multiplicative => "multiplicative"
  }
  "{\"mode\":\"\{mode}\",\"period\":\{result.decomposition_period},\"observed\":\{double_array_json(result.decomposition_observed)},\"trend\":\{double_array_json(result.decomposition_trend)},\"seasonal\":\{double_array_json(result.decomposition_seasonal)},\"residual\":\{double_array_json(result.decomposition_residual)},\"available\":\{bool_array_json(result.decomposition_available)},\"seasonal_factors\":\{double_array_json(result.decomposition_factors)}}"
}

///|
fn backtest_fold_to_json(fold : BacktestFold) -> String {
  "{\"train_start\":\{fold.train_start},\"train_end\":\{fold.train_end},\"test_start\":\{fold.test_start},\"test_end\":\{fold.test_end},\"timestamps\":\{int64_array_json(fold.fold_forecast_timestamps)},\"actual\":\{double_array_json(fold.fold_actual)},\"predicted\":\{double_array_json(fold.fold_predicted)},\"mae\":\{fold.fold_mae},\"rmse\":\{fold.fold_rmse}}"
}

///|
pub fn backtest_to_json(result : BacktestResult) -> String {
  let mut folds = "["
  for index, fold in result.backtest_folds {
    if index > 0 {
      folds = folds + ","
    }
    folds = folds + backtest_fold_to_json(fold)
  }
  folds = folds + "]"
  "{\"model\":\"\{json_escape(result.backtest_model_name)}\",\"mae\":\{result.backtest_mae},\"rmse\":\{result.backtest_rmse},\"folds\":\{folds}}"
}

///|
pub fn selection_to_json(result : SelectionResult) -> String {
  let metric = match result.metric {
    SelectMae => "mae"
    SelectRmse => "rmse"
  }
  let mut candidates = "["
  for index, candidate in result.successful_candidates {
    if index > 0 {
      candidates = candidates + ","
    }
    candidates = candidates +
      "{\"index\":\{candidate.candidate_index},\"model\":\"\{candidate.candidate_spec.name()}\",\"score\":\{candidate.candidate_score}}"
  }
  candidates = candidates + "]"
  let mut failures = "["
  for index, failure in result.failed_candidates {
    if index > 0 {
      failures = failures + ","
    }
    failures = failures +
      "{\"index\":\{failure.candidate_index},\"model\":\"\{failure.spec.name()}\"}"
  }
  failures = failures + "]"
  "{\"metric\":\"\{metric}\",\"best_index\":\{result.best_index},\"best_model\":\"\{result.best_spec.name()}\",\"best_score\":\{result.best_score},\"candidates\":\{candidates},\"failures\":\{failures}}"
}

///|
pub fn residual_summary_to_json(summary : ResidualSummary) -> String {
  "{\"count\":\{summary.count},\"mean\":\{summary.mean},\"variance\":\{summary.variance},\"standard_deviation\":\{summary.standard_deviation},\"mean_absolute\":\{summary.mean_absolute},\"root_mean_square\":\{summary.root_mean_square},\"minimum\":\{summary.minimum},\"maximum\":\{summary.maximum}}"
}

///|
pub fn portmanteau_to_json(result : PortmanteauResult) -> String {
  "{\"observations\":\{result.observations},\"lags\":\{result.lags},\"statistic\":\{result.statistic},\"autocorrelations\":\{double_array_json(result.autocorrelations)}}"
}
