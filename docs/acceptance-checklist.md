# Acceptance Checklist

Evidence is marked complete only after direct verification.

- [x] MoonBit is the primary implementation language.
- [x] Apache-2.0 `LICENSE` and `NOTICE` are present.
- [x] Root package has at least 4,000 substantive production MoonBit lines.
- [x] At least 80 MoonBit test declarations exist; current count is 102.
- [x] `moon fmt --check` passes locally.
- [x] `moon info` passes locally.
- [x] `moon check --deny-warn` passes locally.
- [x] `moon build` passes locally.
- [x] `moon test` passes locally with 102/102 tests.
- [x] Five public-API example packages run locally.
- [x] Source audit passes and rejects placeholder markers.
- [x] README documents installation, usage, examples, boundaries, and verification.
- [x] Development report and mathematical references are present.
- [ ] Public GitHub repository is accessible at the declared URL.
- [ ] GitHub Actions succeeds on the exact final `main` commit.
- [ ] `moon publish --dry-run` succeeds for version 0.1.0.
- [ ] `wjhsb1/time-series-forecasting@0.1.0` is published on Mooncakes.
- [ ] A clean external module installs exact version 0.1.0 and runs successfully.
- [ ] Immutable `v0.1.0` tag points to the verified release commit.
