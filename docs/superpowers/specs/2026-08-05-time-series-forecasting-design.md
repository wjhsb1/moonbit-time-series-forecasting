# MoonBit Time Series Forecasting Toolkit Design

## Identity And Goal

- Participant: Wu Jinghao (伍敬豪)
- GitHub account: `wjhsb1`
- Planned module: `wjhsb1/time-series-forecasting`
- Planned repository: `wjhsb1/moonbit-time-series-forecasting`
- License: Apache-2.0

The project provides deterministic offline forecasting, seasonal decomposition,
rolling-origin backtesting, model comparison, and forecast diagnostics for
finite univariate numeric time series. The target is 4,500-5,500 substantive
production MoonBit lines, 70-100 tests, five or six executable examples, and a
reproducible Mooncakes release.

The legacy prototype at `CascadeProjects/time_series` is requirements reference
only. It uses obsolete manifests, has no Git history, cannot be checked by the
current toolchain, and contains unsupported ARIMA, STL, coverage, and production
claims. Its source and history will not be copied into the new repository.

## Ecosystem Boundary

`cn-wn/moonsignalkit` is related MoonBit ecosystem work. It focuses on streaming
telemetry, rolling windows, online moments, EWMA, timestamp monitoring, CSV, and
CUSUM. This project focuses on fitted offline forecast models, seasonal
decomposition, chronological backtesting, deterministic model selection, and
forecast reports. It will not expose rolling quantiles, online telemetry state,
timestamp monitoring, CUSUM, or CSV I/O as headline capabilities.

Version 0.1.0 will not claim complete ARIMA or AutoARIMA, STL/LOESS, confidence
intervals, multivariate models, missing-value imputation, irregular sampling,
production performance, or parallel training.

## Package Architecture

One publishable MoonBit package is split by responsibility:

- `errors.mbt`: typed public errors and stable error messages.
- `series_types.mbt`: observations, validated series, splits, and result types.
- `series.mbt`: construction, defensive copying, timestamp/value validation,
  accessors, slicing, and regular-interval checks.
- `transform.mbt`: lag, difference, seasonal difference, cumulative restoration,
  and linear detrending.
- `baseline_types.mbt` and `baseline.mbt`: mean, naive, seasonal-naive, and drift
  fitted models with multi-step forecasts.
- `smoothing_types.mbt` and `smoothing.mbt`: simple exponential smoothing, Holt
  linear trend, and damped Holt models.
- `holt_winters_types.mbt` and `holt_winters.mbt`: additive and multiplicative
  Holt-Winters models with validated periods and smoothing parameters.
- `decomposition_types.mbt` and `decomposition.mbt`: classical additive and
  multiplicative decomposition with aligned trend, seasonal, and residual data.
- `metrics_types.mbt` and `metrics.mbt`: MAE, MSE, RMSE, bias, MAPE, SMAPE,
  MASE, directional accuracy, and combined metric reports.
- `backtest_types.mbt` and `backtest.mbt`: expanding-window and sliding-window
  rolling-origin splits, fold predictions, and aggregate metric reports.
- `selection_types.mbt` and `selection.mbt`: deterministic candidate grids and
  selection by caller-chosen metric with stable tie-breaking.
- `diagnostics_types.mbt` and `diagnostics.mbt`: residual summaries,
  autocorrelation at explicit lags, and Ljung-Box-style portmanteau statistics
  without claiming a calibrated p-value.
- `report.mbt`: stable text and JSON exports for forecasts, decompositions,
  backtests, and selections.

Examples are separate executable packages for baseline forecasting, smoothing,
seasonal forecasting, decomposition, and backtesting/model selection.

## Public Data Contract

`time_series(timestamps, values, name)` returns a validated immutable value.
Inputs must be nonempty, lengths must match, values must be finite, and
timestamps must be strictly increasing. Models requiring regular sampling also
verify a constant positive interval. Constructors copy arrays so caller mutation
cannot alter validated data.

Every fitted model owns the state derived during fitting. `forecast(steps)` uses
that state and never refits silently. Forecast timestamps advance from the last
observation by the validated sampling interval. Multi-step recursive models feed
their generated states or predictions into later horizons.

All public failures return `Result[..., TimeSeriesError]`. Invalid input never
returns an empty series, an unchanged model, NaN, or a plausible-looking default.
Errors cover empty data, mismatched lengths, nonfinite values, unordered or
irregular timestamps, invalid periods/windows/steps, insufficient observations,
invalid smoothing parameters, multiplicative-domain violations, zero-valued
metric denominators, and impossible backtest configurations.

## Forecasting Algorithms

Baseline models provide transparent references:

- mean forecast repeats the training mean;
- naive forecast repeats the final observation;
- seasonal naive repeats observations from the final complete seasonal cycle;
- drift forecast extends the slope between first and last observations.

Simple exponential smoothing uses a fixed caller-supplied alpha or a deterministic
grid-selected alpha. Holt models expose level and trend smoothing parameters;
damped Holt also validates a damping factor in `(0, 1]`. Holt-Winters supports
additive and multiplicative seasonality and requires at least two complete
periods. Initialization and update equations are documented and tested against
hand-computed fixtures.

Classical decomposition returns arrays aligned to the source timestamps. Edge
trend values without a complete centered window are represented by an explicit
availability mask rather than invented values. Multiplicative decomposition
rejects nonpositive observations.

## Backtesting And Selection

Backtesting is chronological and cannot shuffle. An expanding-window split grows
the training prefix; a sliding-window split retains a fixed training width. Each
fold records train/test bounds, actual values, predictions, and metrics. The code
asserts that every forecast timestamp is later than every training timestamp.

Candidate selection evaluates caller-supplied model specifications on identical
folds. Lower error wins; ties are resolved by candidate order. Failed candidates
are returned with typed error evidence rather than silently omitted. No model is
described as statistically superior without the recorded metric and folds.

## Testing And Evidence

Implementation follows red-green-refactor. Every behavior begins with a failing
test, then the minimal implementation, then the full relevant test set. Tests use
hand-computed values, invariants, deterministic synthetic trend/seasonal series,
invalid inputs, and no-future-leakage assertions. Length-only and tautological
assertions are not acceptable evidence.

Release verification is:

```text
moon clean
moon fmt --check
moon info
moon check --deny-warn
moon build
moon test
moon run examples/baseline
moon run examples/smoothing
moon run examples/seasonal
moon run examples/decomposition
moon run examples/backtest
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/source-audit.ps1
moon publish --dry-run
```

GitHub Actions runs the same checks. The source audit reports physical and
substantive production/test lines and rejects placeholder markers in MoonBit
source. After publication, a fresh external project installs the exact Mooncakes
version and calls public fitting, forecasting, and backtesting APIs.

## Commit And Documentation Policy

The repository will contain at least ten substantive development commits, with
an expected 12-18 commits. Commits correspond to independently reviewable
capabilities such as validation, baselines, smoothing, seasonal models, metrics,
backtesting, selection, diagnostics, reporting, examples, and release evidence.
Commit timestamps are not manipulated and history is not rewritten to fabricate
development. README, badge, and CI churn does not count as feature development.

README and the one-page application describe only verified public behavior.
Claims include exact test/example counts only after final verification. Related
work and mathematical references are documented. Future candidates are labelled
as future work and are not phrased as completed capabilities.

## Acceptance Definition

The project is ready for application and acceptance when the public repository
is reachable; the current `main` CI is green; the implementation is primarily
MoonBit; production substantive source is within the target range; public APIs,
examples, README, development report, application, and tests agree; Apache-2.0
files are present; the package is published to Mooncakes; and a clean external
consumer verifies installation and use.
