///|
pub(all) enum SelectionMetric {
  SelectMae
  SelectRmse
} derive(Eq, Debug)

///|
pub(all) struct CandidateFailure {
  candidate_index : Int
  spec : ModelSpec
  error : TimeSeriesError
} derive(Eq, Debug)

///|
pub struct CandidateScore {
  candidate_index : Int
  candidate_spec : ModelSpec
  candidate_score : Double
  candidate_backtest : BacktestResult
} derive(Eq, Debug)

///|
pub fn CandidateScore::index(self : CandidateScore) -> Int {
  self.candidate_index
}

///|
pub fn CandidateScore::spec(self : CandidateScore) -> ModelSpec {
  self.candidate_spec
}

///|
pub fn CandidateScore::score(self : CandidateScore) -> Double {
  self.candidate_score
}

///|
pub fn CandidateScore::backtest(self : CandidateScore) -> BacktestResult {
  self.candidate_backtest
}

///|
pub(all) struct SelectionResult {
  best_index : Int
  best_spec : ModelSpec
  best_score : Double
  metric : SelectionMetric
  successful_candidates : Array[CandidateScore]
  failed_candidates : Array[CandidateFailure]
} derive(Eq, Debug)

///|
pub fn SelectionResult::success_count(self : SelectionResult) -> Int {
  self.successful_candidates.length()
}

///|
pub fn SelectionResult::failure_count(self : SelectionResult) -> Int {
  self.failed_candidates.length()
}

///|
pub fn SelectionResult::candidate(
  self : SelectionResult,
  index : Int,
) -> Result[CandidateScore, TimeSeriesError] {
  if index < 0 || index >= self.successful_candidates.length() {
    return Err(
      InvalidSlice(index, index + 1, self.successful_candidates.length()),
    )
  }
  Ok(self.successful_candidates[index])
}

///|
pub fn SelectionResult::failure(
  self : SelectionResult,
  index : Int,
) -> Result[CandidateFailure, TimeSeriesError] {
  if index < 0 || index >= self.failed_candidates.length() {
    return Err(InvalidSlice(index, index + 1, self.failed_candidates.length()))
  }
  Ok(self.failed_candidates[index])
}

///|
pub fn SelectionResult::fold_boundaries_for(
  self : SelectionResult,
  original_candidate_index : Int,
) -> Result[Array[BacktestSplit], TimeSeriesError] {
  for candidate in self.successful_candidates {
    if candidate.candidate_index == original_candidate_index {
      return Ok(candidate.candidate_backtest.fold_boundaries())
    }
  }
  Err(
    InvalidSlice(
      original_candidate_index,
      original_candidate_index + 1,
      self.successful_candidates.length(),
    ),
  )
}
