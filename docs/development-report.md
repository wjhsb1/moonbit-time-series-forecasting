# Development Report

## Project

MoonBit Time Series Forecasting Toolkit provides deterministic offline forecasting,
seasonal decomposition, chronological evaluation, model selection, diagnostics, and
supporting transformations for finite univariate series.

## Design

`TimeSeries` validates observations once and keeps copied timestamp/value arrays.
Fitting functions return immutable model state. Forecast methods use that state and
never refit. Backtests construct chronological training slices and verify forecast
timestamps against each test slice. Public invalid operations return typed errors.

The implementation is divided by responsibility:

- `series*`, `transform*`, `rolling*`, `scaling*`, and `statistics*` handle data.
- `baseline*`, `smoothing*`, and `holt_winters*` fit point-forecast models.
- `decomposition*` and `seasonality_diagnostics*` analyze classical seasonality.
- `metrics*` and `extended_metrics*` evaluate point forecasts.
- `backtest*`, `selection*`, and `ensemble*` evaluate and combine models.
- `diagnostics*`, `report*`, and `analysis_report*` expose evidence and reports.
- `features*` creates chronological supervised rows without future target leakage.
- `alignment*` performs explicit timestamp joins and paired analysis.

## Development Method

Features were implemented in small behavior-focused batches. Tests were introduced
before each implementation and exercised expected values, invalid inputs, alignment,
copy isolation, chronological boundaries, and output stability. Commits correspond
to actual functional increments rather than repeated metadata edits.

## Local Evidence

Measured by `scripts/source-audit.ps1` after formatting:

- Root production MoonBit: 4,619 physical lines, 4,026 substantive lines.
- Root test MoonBit: 1,212 physical lines, 1,030 substantive lines.
- MoonBit test declarations: 102.
- Executable example packages: 5.
- Placeholder scan: no `TODO`, `MVP`, `stub`, or `fake` markers in MoonBit sources.

The local release chain passes formatting, interface generation, strict checking,
build, all tests, all five examples, and source audit. Remote CI, registry publication,
and clean external-consumer evidence are tracked separately in the acceptance
checklist and are marked complete only after they are observed.

## Algorithm Boundaries

The package implements point forecasts, not probabilistic intervals. Seasonal
decomposition is the classical centered moving-average method, not STL. The
portmanteau function returns only the statistic and autocorrelations; it makes no
p-value or significance claim. Period ranking is deterministic evidence based on
autocorrelation and classical component strength, not automatic causal discovery.

Version 0.1.0 does not claim ARIMA, AutoARIMA, STL/LOESS, multivariate forecasting,
missing-value imputation, irregular-time resampling, production throughput targets,
or parallel model fitting.

## Originality

The MoonBit implementation was written for this repository. Mathematical formulas
follow standard published forecasting and statistics references listed in
`docs/references.md`; no third-party source code was copied or translated. The
project uses the Apache-2.0 license.
