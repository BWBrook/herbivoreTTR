# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
whenever release tags are published.

## [Unreleased]
### Added
- `docs/PIPELINE.md` describing the minimal {targets} DAG and execution profile.
- Pipeline helper functions that write parity CSVs with directory management for targets.
- `docs/test_battery.md` detailing the planned comprehensive test suite and logging spec.
- Structured test logger (`tests/testthat/helper-test_log.R`) and full test battery harness (`scripts/run_test_battery.R`).
- Extensive testthat coverage for initialisation, energy/water balance, behaviour, utilities, parity, and pipeline manifest checks.

### Changed
- `init_conditions()` and the CSV writers now emit typed `rlang::abort()` errors and use clearer nitrogen naming.
- `_targets.R` delegates file creation to the new helpers to keep the pipeline declarative.
- `.gitignore` and `.Rbuildignore` include data output, docs, and tooling directories required by the workflow.

### Fixed
- Strengthened CSV writer validations so header mismatches surface with structured errors.
