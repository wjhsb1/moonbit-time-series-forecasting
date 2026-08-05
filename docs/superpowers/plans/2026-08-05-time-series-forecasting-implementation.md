# MoonBit Time Series Forecasting Toolkit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a verified MoonBit library for deterministic univariate forecasting, seasonal decomposition, chronological backtesting, model selection, and diagnostics.

**Architecture:** One publishable package owns validated immutable series and separately typed fitted models. Forecast models never refit during prediction; backtests train only on chronological prefixes; all public invalid states return typed errors. Examples, CI, source audit, Mooncakes publication, and an independent consumer provide acceptance evidence.

**Tech Stack:** MoonBit current stable toolchain, MoonBit core library, GitHub Actions, PowerShell source audit, Mooncakes registry, Apache-2.0.

---

## File Structure

Production and test files live at repository root because one MoonBit directory is one package. Type files define contracts; behavior files contain algorithms. Executable public examples live under `examples/<name>`.

## Task 1: Bootstrap Current MoonBit Package

**Files:** Create `moon.mod`, `moon.pkg`, `.gitignore`, `LICENSE`, `NOTICE`, `README.md`.

- [ ] **Step 1: Add the current module manifest**

```moonbit
name = "wjhsb1/time-series-forecasting"
version = "0.1.0"
readme = "README.md"
repository = "https://github.com/wjhsb1/moonbit-time-series-forecasting"
license = "Apache-2.0"
keywords = ["time-series", "forecasting", "backtesting", "statistics"]
preferred_target = "wasm-gc"
description = "Deterministic time series forecasting and backtesting for MoonBit"
```

- [ ] **Step 2: Add an empty `moon.pkg`, standard Apache-2.0 text, NOTICE for Wu Jinghao, and a scope-only README**
- [ ] **Step 3: Run `moon check --deny-warn`; expect exit 0 with no warnings**
- [ ] **Step 4: Commit**

```bash
git add moon.mod moon.pkg .gitignore LICENSE NOTICE README.md
git commit -m "build: initialize time series forecasting package"
```

## Task 2: Validated Series And Typed Errors

**Files:** Create `errors.mbt`, `series_types.mbt`, `series.mbt`, `series_test.mbt`.

- [ ] **Step 1: Write failing validation and defensive-copy tests**

```moonbit
test "series rejects nonfinite and unordered observations" {
  assert_eq(time_series([0L], [1.0 / 0.0], "bad"), Err(NonFiniteValue(0)))
  assert_eq(time_series([10L, 10L], [1.0, 2.0], "bad"), Err(NonIncreasingTimestamp(1)))
}

test "series copies caller arrays" {
  let values = [1.0, 2.0]
  let series = time_series([0L, 10L], values, "x").unwrap()
  values[0] = 99.0
  assert_eq(series.values(), [1.0, 2.0])
}
```

- [ ] **Step 2: Run `moon test -p wjhsb1/time-series-forecasting`; expect missing APIs**
- [ ] **Step 3: Implement `TimeSeriesError`, immutable `TimeSeries`, constructor, copied accessors, interval, slice, head, and tail**

```moonbit
pub(all) enum TimeSeriesError {
  EmptySeries
  LengthMismatch(Int, Int)
  NonFiniteValue(Int)
  NonIncreasingTimestamp(Int)
  IrregularInterval(Int)
  InvalidSteps(Int)
  InvalidPeriod(Int)
  InvalidWindow(Int)
  InsufficientData(Int, Int)
  InvalidSmoothingParameter(String, Double)
  NonPositiveMultiplicativeValue(Int)
  MetricLengthMismatch(Int, Int)
  UndefinedPercentageMetric(Int)
  InvalidBacktestConfig
} derive(Eq, Debug)
```

- [ ] **Step 4: Run tests; expect all series tests to pass**
- [ ] **Step 5: Commit `feat: validate immutable time series data`**

## Task 3: Deterministic Transformations

**Files:** Create `transform_types.mbt`, `transform.mbt`, `transform_test.mbt`.

- [ ] **Step 1: Write failing aligned difference tests**

```moonbit
test "differences preserve aligned timestamps" {
  let series = time_series([0L, 1L, 2L, 3L], [1.0, 3.0, 6.0, 10.0], "x").unwrap()
  assert_eq(series.difference(1).unwrap().values(), [2.0, 3.0, 4.0])
  assert_eq(series.difference(1).unwrap().timestamps(), [1L, 2L, 3L])
  assert_eq(series.seasonal_difference(2).unwrap().values(), [5.0, 7.0])
}
```

- [ ] **Step 2: Run tests; expect missing transformation methods**
- [ ] **Step 3: Implement lag, difference, seasonal difference, first-difference restoration, linear trend, and linear detrending with typed invalid-period/data errors**
- [ ] **Step 4: Run all tests; expect pass**
- [ ] **Step 5: Commit `feat: transform and detrend time series`**

## Task 4: Baseline Forecast Models

**Files:** Create `forecast_types.mbt`, `baseline_types.mbt`, `baseline.mbt`, `baseline_test.mbt`.

- [ ] **Step 1: Write failing hand-computed forecasts**

```moonbit
test "baseline models produce exact multi-step forecasts" {
  let series = time_series([0L, 10L, 20L, 30L], [2.0, 4.0, 6.0, 8.0], "x").unwrap()
  assert_eq(fit_mean(series).unwrap().forecast(3).unwrap().values, [5.0, 5.0, 5.0])
  assert_eq(fit_naive(series).unwrap().forecast(3).unwrap().values, [8.0, 8.0, 8.0])
  assert_eq(fit_drift(series).unwrap().forecast(2).unwrap().values, [10.0, 12.0])
}

test "seasonal naive repeats the final cycle" {
  let series = time_series([0L, 1L, 2L, 3L, 4L, 5L], [1.0, 2.0, 3.0, 1.0, 2.0, 3.0], "x").unwrap()
  assert_eq(fit_seasonal_naive(series, 3).unwrap().forecast(5).unwrap().values, [1.0, 2.0, 3.0, 1.0, 2.0])
}
```

- [ ] **Step 2: Run tests; expect missing fitted model APIs**
- [ ] **Step 3: Implement `Forecast` plus mean, naive, seasonal-naive, and drift fitted types; forecast timestamps advance by the validated interval**
- [ ] **Step 4: Run tests; expect pass**
- [ ] **Step 5: Commit `feat: forecast with deterministic baseline models`**

## Task 5: Exponential Smoothing And Holt Models

**Files:** Create `smoothing_types.mbt`, `smoothing.mbt`, `smoothing_test.mbt`.

- [ ] **Step 1: Write failing state-equation and parameter tests**

```moonbit
test "simple exponential smoothing matches hand calculation" {
  let series = time_series([0L, 1L, 2L], [10.0, 14.0, 13.0], "x").unwrap()
  let model = fit_ses(series, 0.5).unwrap()
  assert_eq(model.level(), 12.5)
  assert_eq(model.forecast(2).unwrap().values, [12.5, 12.5])
}

test "smoothing rejects alpha zero" {
  let series = time_series([0L, 1L], [1.0, 2.0], "x").unwrap()
  assert_eq(fit_ses(series, 0.0), Err(InvalidSmoothingParameter("alpha", 0.0)))
}
```

- [ ] **Step 2: Run tests; expect missing smoothing APIs**
- [ ] **Step 3: Implement SES, Holt linear trend, and damped Holt using `level=y0`, `trend=y1-y0`; validate alpha/beta/damping in `(0,1]`; retain fitted values and residuals**
- [ ] **Step 4: Run all tests; expect pass**
- [ ] **Step 5: Commit `feat: fit exponential smoothing trend models`**

## Task 6: Holt-Winters Seasonal Models

**Files:** Create `holt_winters_types.mbt`, `holt_winters.mbt`, `holt_winters_test.mbt`.

- [ ] **Step 1: Write failing seasonal and multiplicative-domain tests**

```moonbit
test "Holt-Winters preserves a stable two-value season" {
  let series = time_series([0L,1L,2L,3L,4L,5L,6L,7L], [10.0,12.0,10.0,12.0,10.0,12.0,10.0,12.0], "s").unwrap()
  let values = fit_holt_winters(series, 2, 0.5, 0.2, 0.5, Additive).unwrap().forecast(4).unwrap().values
  assert_eq(values.length(), 4)
  assert_true(values[0] < values[1] && values[2] < values[3])
}

test "multiplicative Holt-Winters rejects zero" {
  let series = time_series([0L,1L,2L,3L], [1.0,2.0,0.0,2.0], "x").unwrap()
  assert_eq(fit_holt_winters(series, 2, 0.5, 0.5, 0.5, Multiplicative), Err(NonPositiveMultiplicativeValue(2)))
}
```

- [ ] **Step 2: Run tests; expect missing seasonal APIs**
- [ ] **Step 3: Implement additive and multiplicative initialization, updates, recursive forecasts, and minimum-two-period validation**
- [ ] **Step 4: Run all tests; expect pass**
- [ ] **Step 5: Commit `feat: forecast additive and multiplicative seasonality`**

## Task 7: Classical Seasonal Decomposition

**Files:** Create `decomposition_types.mbt`, `decomposition.mbt`, `decomposition_test.mbt`.

- [ ] **Step 1: Write a failing reconstruction test**

```moonbit
test "additive components reconstruct every available observation" {
  let series = time_series([0L,1L,2L,3L,4L,5L], [11.0,9.0,13.0,11.0,15.0,13.0], "x").unwrap()
  let result = decompose_additive(series, 2).unwrap()
  for i = 0; i < result.length(); i = i + 1 {
    if result.available[i] {
      assert_true((result.trend[i] + result.seasonal[i] + result.residual[i] - result.observed[i]).abs() < 1.0e-9)
    }
  }
}
```

- [ ] **Step 2: Run tests; expect missing decomposition APIs**
- [ ] **Step 3: Implement centered moving-average additive/multiplicative decomposition, explicit edge availability mask, additive seasonal sum-zero normalization, multiplicative mean-one normalization, and positive-domain checks**
- [ ] **Step 4: Run all tests; expect pass**
- [ ] **Step 5: Commit `feat: decompose classical seasonal series`**

## Task 8: Forecast Metrics

**Files:** Create `metrics_types.mbt`, `metrics.mbt`, `metrics_test.mbt`.

- [ ] **Step 1: Write failing exact metric tests**

```moonbit
test "forecast metrics match hand values" {
  assert_eq(mae([2.0,4.0], [1.0,6.0]).unwrap(), 1.5)
  assert_eq(mse([2.0,4.0], [1.0,6.0]).unwrap(), 2.5)
  assert_true((rmse([2.0,4.0], [1.0,6.0]).unwrap() - 2.5.sqrt()).abs() < 1.0e-12)
  assert_eq(bias([2.0,4.0], [1.0,6.0]).unwrap(), 0.5)
}

test "MAPE rejects zero actual values" {
  assert_eq(mape([0.0], [1.0]), Err(UndefinedPercentageMetric(0)))
}
```

- [ ] **Step 2: Run tests; expect missing metrics**
- [ ] **Step 3: Implement MAE, MSE, RMSE, bias, MAPE, SMAPE, MASE, directional accuracy, finite/length validation, and structured `MetricReport`**
- [ ] **Step 4: Run all tests; expect pass**
- [ ] **Step 5: Commit `feat: evaluate forecast accuracy`**

## Task 9: Chronological Backtesting

**Files:** Create `backtest_types.mbt`, `backtest.mbt`, `backtest_test.mbt`.

- [ ] **Step 1: Write failing no-leakage split tests**

```moonbit
test "expanding splits never include future observations" {
  let splits = expanding_splits(12, 6, 2, 2).unwrap()
  assert_eq(splits.length(), 3)
  for split in splits {
    assert_true(split.train_end <= split.test_start)
    assert_eq(split.test_end - split.test_start, 2)
  }
}

test "sliding splits retain training width" {
  for split in sliding_splits(12, 5, 2, 2).unwrap() {
    assert_eq(split.train_end - split.train_start, 5)
  }
}
```

- [ ] **Step 2: Run tests; expect missing split APIs**
- [ ] **Step 3: Implement expanding/sliding splits and `ModelSpec` backtests; fit only each training slice, match forecast/test timestamps, store fold evidence, and aggregate by observation count**
- [ ] **Step 4: Run all tests; expect pass**
- [ ] **Step 5: Commit `feat: backtest forecasts without future leakage`**

## Task 10: Deterministic Model Selection

**Files:** Create `selection_types.mbt`, `selection.mbt`, `selection_test.mbt`.

- [ ] **Step 1: Write failing common-fold and tie-break tests**

```moonbit
test "selection evaluates identical folds and preserves tie order" {
  let series = time_series([0L,1L,2L,3L,4L,5L], [3.0,3.0,3.0,3.0,3.0,3.0], "constant").unwrap()
  let result = select_model(series, [MeanSpec, NaiveSpec], ExpandingConfig(4,1,1), SelectRmse).unwrap()
  assert_eq(result.best_index, 0)
  assert_eq(result.fold_boundaries_for(0), result.fold_boundaries_for(1))
}
```

- [ ] **Step 2: Run tests; expect missing selection APIs**
- [ ] **Step 3: Implement deterministic alpha, alpha/beta, and alpha/beta/gamma grids; evaluate candidates on shared folds; lower error wins; ties use input order; retain typed candidate failures**
- [ ] **Step 4: Run all tests; expect pass**
- [ ] **Step 5: Commit `feat: select forecast models by backtest score`**

## Task 11: Diagnostics And Stable Reports

**Files:** Create `diagnostics_types.mbt`, `diagnostics.mbt`, `diagnostics_test.mbt`, `report.mbt`, `report_test.mbt`.

- [ ] **Step 1: Write failing diagnostic and JSON escaping tests**

```moonbit
test "residual diagnostics are deterministic" {
  assert_eq(residual_summary([1.0,-1.0,1.0,-1.0]).unwrap().mean, 0.0)
  assert_eq(autocorrelation([1.0,-1.0,1.0,-1.0], 1).unwrap(), -0.75)
}

test "JSON uses strict control escapes" {
  let json = forecast_to_json(Forecast::{ timestamps: [1L], values: [2.0], model_name: "季节\nmodel\u{0}" })
  assert_true(json.contains("季节\\nmodel\\u0000"))
  assert_false(json.contains("\\u{"))
}
```

- [ ] **Step 2: Run tests; expect missing diagnostic/report APIs**
- [ ] **Step 3: Implement residual summary, lag autocorrelation, portmanteau statistic without p-value claims, and stable text/strict JSON export for forecasts, decompositions, backtests, and selections**
- [ ] **Step 4: Run all tests; expect pass**
- [ ] **Step 5: Commit `feat: diagnose and export forecast results`**

## Task 12: Examples, CI, Audit, And Documentation

**Files:** Create five `examples/*` packages, `.github/workflows/ci.yml`, `scripts/source-audit.ps1`, `docs/development-report.md`, `docs/references.md`, `docs/acceptance-checklist.md`, `CHANGELOG.md`; modify `README.md`.

- [ ] **Step 1: Add baseline, smoothing, seasonal, decomposition, and backtest executables using only public APIs**
- [ ] **Step 2: Add CI steps for checkout, MoonBit install, version, format, info, strict check, build, test, all five examples, and PowerShell source audit**
- [ ] **Step 3: Add source audit that reports physical/substantive production/test lines and rejects `TODO`, `MVP`, `stub`, or `fake` in MoonBit source**
- [ ] **Step 4: Document exact installation, implemented capabilities, errors, examples, verification, boundaries, originality, mathematical references, and MoonSignalKit related-work distinction; omit unmeasured counts**
- [ ] **Step 5: Run the complete release chain**

```powershell
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

- [ ] **Step 6: Record exact measured counts, rerun the chain, then commit `release: prepare time series forecasting 0.1.0`**

## Task 13: Remote And Registry Evidence

**Files:** Modify `docs/acceptance-checklist.md`; create outside repository `伍敬豪-MoonBit-Time-Series-项目申报书参考稿.md` and `time-series-progress.md`.

- [ ] **Step 1: Create public `wjhsb1/moonbit-time-series-forecasting`, push every natural commit, and verify history visibility**
- [ ] **Step 2: Require exact-head GitHub Actions success for every check, test, example, and audit step**
- [ ] **Step 3: Run `moon whoami`; require `wjhsb1`; publish `wjhsb1/time-series-forecasting@0.1.0`; require `200 OK`**
- [ ] **Step 4: In a clean external module, install exact `0.1.0`, fit a smoothing model, forecast, backtest, and require strict check/build/run success**
- [ ] **Step 5: Create annotated `v0.1.0` at the verified published release commit and push it without later movement**
- [ ] **Step 6: Mark only proven acceptance evidence, commit `docs: record 0.1.0 release evidence`, push, and require final `main` CI success**
- [ ] **Step 7: Write a one-page external Markdown application reference with exact counts, implementation-matched claims, originality, and MoonSignalKit scope distinction; participant must personally review and rewrite because the official form prohibits AI-written applications**
