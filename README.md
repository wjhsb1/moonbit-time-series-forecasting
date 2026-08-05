# MoonBit Time Series Forecasting Toolkit

`wjhsb1/time-series-forecasting` is a deterministic MoonBit toolkit for finite,
univariate, regularly sampled time series. It covers baseline and exponential
smoothing forecasts, classical seasonal decomposition, chronological backtests,
model selection, residual diagnostics, offline feature engineering, and stable
text/JSON reports.

The package is implemented in MoonBit and licensed under Apache-2.0.

## Install

```bash
moon add wjhsb1/time-series-forecasting@0.1.0
```

Import the package in `moon.pkg`:

```moonbit
import {
  "wjhsb1/time-series-forecasting" @ts,
}
```

## Minimal Example

```moonbit
fn main {
  let series = @ts.time_series(
    [0L, 10L, 20L, 30L, 40L],
    [12.0, 14.0, 15.0, 18.0, 20.0],
    "monthly_demand",
  ).unwrap()
  let model = @ts.fit_holt(series, 0.5, 0.3).unwrap()
  let forecast = model.forecast(3).unwrap()
  println(@ts.forecast_to_text(forecast))
}
```

Run the repository examples:

```bash
moon run examples/baseline
moon run examples/smoothing
moon run examples/seasonal
moon run examples/decomposition
moon run examples/backtest
```

## Implemented Capabilities

### Validated data

- Nonempty, finite observations with strictly increasing timestamps.
- Defensive copies for constructor input and public array accessors.
- Regular-interval validation and aligned slice, head, tail, and chronological split.
- Typed `TimeSeriesError` values with stable codes and readable messages.

### Forecasting

- Mean, naive, seasonal-naive, and drift baselines.
- Simple exponential smoothing, Holt linear trend, and damped Holt trend.
- Additive and multiplicative Holt-Winters seasonality.
- Fitted values and residuals for smoothing models.
- Future timestamps derived from the validated training interval.
- Mean, median, explicit-weight, and backtest-weighted forecast combinations.

### Transformation and analysis

- Lag, difference, seasonal difference, first-difference restoration, linear trend,
  and linear detrending.
- Cumulative sum/mean, percentage change, rebasing, clipping, winsorization, and
  block aggregation.
- Trailing sum, mean, min, max, median, quantile, standard deviation, weighted
  moving average, and exponential moving average.
- Standard, min-max, and robust scalers with inverse transforms.
- Descriptive statistics, interpolated quantiles, median absolute deviation,
  skewness, kurtosis, covariance, and Pearson correlation.
- Exact or inner timestamp alignment, arithmetic combination, weighted combination,
  cross-correlation, and best-lag search.

### Seasonality and evaluation

- Classical additive and multiplicative moving-average decomposition.
- Explicit edge availability masks; unavailable trend edges are never presented as
  estimated components.
- Seasonal profiles, seasonal adjustment, period autocorrelation, seasonal/trend
  strength, and deterministic candidate-period ranking.
- MAE, MSE, RMSE, bias, MAPE, SMAPE, MASE, directional accuracy, median/max error,
  WAPE, RMSLE, quantile loss, relative errors, R-squared, and RMSE forecast skill.

### Backtesting and diagnostics

- Expanding-window and sliding-window chronological splits.
- Fold evidence containing train/test boundaries, target timestamps, actual values,
  predictions, MAE, and RMSE.
- Model specifications for all included baseline and smoothing models.
- Deterministic model selection on shared folds; exact ties retain input order.
- Candidate failures remain typed and inspectable.
- Residual summary, autocovariance, autocorrelation sequence, portmanteau statistic
  without p-value claims, Durbin-Watson statistic, and sign-run count.
- Leakage-safe supervised feature matrices for lag, difference, rolling, and current
  values with configurable future horizon.
- Stable JSON/text export for forecasts and analysis results.

## Backtest Example

```moonbit
let config = @ts.ExpandingConfig(6, 2, 2)
let candidates : Array[@ts.ModelSpec] = [
  @ts.MeanSpec,
  @ts.NaiveSpec,
  @ts.DriftSpec,
  @ts.SesSpec(0.5),
  @ts.HoltSpec(0.5, 0.5),
]
let result = @ts.select_model(
  series,
  candidates,
  config,
  @ts.SelectRmse,
).unwrap()
println(@ts.selection_to_json(result))
```

Every fold fits only observations in `[train_start, train_end)` and predicts the
following `[test_start, test_end)` range. The implementation checks that forecast
timestamps exactly match test timestamps.

## Input Contracts

- Forecast models require at least two observations and regular sampling.
- Holt-Winters and classical decomposition require at least two complete periods.
- Multiplicative operations require strictly positive observations.
- Smoothing parameters are finite and in `(0, 1]`.
- MAPE rejects zero actual values; MASE and relative metrics reject zero scales.
- Backtest windows must produce at least one complete chronological fold.
- Forecast combinations require exactly aligned timestamps.

Invalid public operations return `Result[..., TimeSeriesError]`; they do not return
empty forecasts or silently replace invalid values.

## Verification

```bash
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

The source audit measures root-package production and test code separately, rejects
placeholder markers in MoonBit sources, requires at least 4,000 substantive
production lines, at least 80 test declarations, and five executable examples.

## Current Release Scope

Version `0.1.0` implements deterministic point forecasting for finite univariate
series. ARIMA/AutoARIMA, STL/LOESS, prediction intervals, multivariate models,
missing-value imputation, irregular-time resampling, and parallel fitting are not
part of this release. They remain possible later work and are not claimed by this
README or the application materials.

This package is distinct from
[`cn-wn/moonsignalkit`](https://mooncakes.io/docs/cn-wn/moonsignalkit), which focuses
on streaming telemetry, online rolling state, timestamp monitoring, CSV workflows,
and CUSUM. This project focuses on offline forecasting, classical decomposition,
chronological evaluation, selection, and forecast diagnostics.

## Project Documents

- [Development report](docs/development-report.md)
- [Mathematical references](docs/references.md)
- [Acceptance checklist](docs/acceptance-checklist.md)
- [Changelog](CHANGELOG.md)

## License

Apache License 2.0. See [LICENSE](LICENSE) and [NOTICE](NOTICE).
