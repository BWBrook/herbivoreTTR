## Global options and reproducibility settings
##
## This file is sourced at the top of `_targets.R` to define runtime
## defaults.  Use it to set the random number generator (RNG), seeds,
## logging levels, and other options that should apply across your
## pipeline.  Avoid side‑effects beyond options and seeding.

## Use a reproducible, parallel‑safe RNG and a fixed project seed
RNGkind("L'Ecuyer-CMRG")
set.seed(20250811L)  # project-wide seed; update as needed

## Set CRAN mirror and suppress scientific notation in output
options(
  repos = c(CRAN = "https://packagemanager.posit.co/cran/latest"),
  readr.show_col_types = FALSE,
  scipen = 999
)

## Setup logging with lgr and enable progressr globally
logger <- lgr::get_logger("diamond")
logger$set_threshold("info")
progressr::handlers(global = TRUE)