///|
fn selection_score(result : BacktestResult, metric : SelectionMetric) -> Double {
  match metric {
    SelectMae => result.mae()
    SelectRmse => result.rmse()
  }
}

///|
/// Selects the lowest-error candidate. Exact ties retain input order.
pub fn select_model(
  series : TimeSeries,
  candidates : Array[ModelSpec],
  config : BacktestConfig,
  metric : SelectionMetric,
) -> Result[SelectionResult, TimeSeriesError] {
  if candidates.is_empty() {
    return Err(NoValidCandidate)
  }
  let successes : Array[CandidateScore] = []
  let failures : Array[CandidateFailure] = []
  let mut best_index = -1
  let mut best_spec = candidates[0]
  let mut best_score = @double.infinity
  for index, spec in candidates {
    match backtest(series, spec, config) {
      Err(error) => failures.push({ candidate_index: index, spec, error })
      Ok(result) => {
        let score = selection_score(result, metric)
        successes.push({
          candidate_index: index,
          candidate_spec: spec,
          candidate_score: score,
          candidate_backtest: result,
        })
        if best_index < 0 || score < best_score {
          best_index = index
          best_spec = spec
          best_score = score
        }
      }
    }
  }
  if best_index < 0 {
    return Err(NoValidCandidate)
  }
  Ok({
    best_index,
    best_spec,
    best_score,
    metric,
    successful_candidates: successes,
    failed_candidates: failures,
  })
}

///|
pub fn ses_grid(alphas : Array[Double]) -> Array[ModelSpec] {
  alphas.map(fn(alpha) { SesSpec(alpha) })
}

///|
pub fn holt_grid(
  alphas : Array[Double],
  betas : Array[Double],
) -> Array[ModelSpec] {
  let specs : Array[ModelSpec] = []
  for alpha in alphas {
    for beta in betas {
      specs.push(HoltSpec(alpha, beta))
    }
  }
  specs
}

///|
pub fn damped_holt_grid(
  alphas : Array[Double],
  betas : Array[Double],
  dampings : Array[Double],
) -> Array[ModelSpec] {
  let specs : Array[ModelSpec] = []
  for alpha in alphas {
    for beta in betas {
      for damping in dampings {
        specs.push(DampedHoltSpec(alpha, beta, damping))
      }
    }
  }
  specs
}

///|
pub fn holt_winters_grid(
  period : Int,
  alphas : Array[Double],
  betas : Array[Double],
  gammas : Array[Double],
  mode : Seasonality,
) -> Array[ModelSpec] {
  let specs : Array[ModelSpec] = []
  for alpha in alphas {
    for beta in betas {
      for gamma in gammas {
        specs.push(HoltWintersSpec(period, alpha, beta, gamma, mode))
      }
    }
  }
  specs
}

///|
pub fn default_smoothing_values() -> Array[Double] {
  [0.2, 0.4, 0.6, 0.8, 1.0]
}
