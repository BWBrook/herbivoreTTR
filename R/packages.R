## Package bootstrap and centralised library attaches
##
## This file defines a small helper to ensure that all packages are
## installed via pak and then loaded consistently.  Keeping package
## installation here helps ensure reproducibility because you can track
## package versions via `renv` and avoid installing ad hoc inside your
## pipeline.

if (!"pak" %in% rownames(installed.packages())) install.packages("pak")
pkgs <- c(
  "targets","tarchetypes","renv","arrow","duckdb","vroom","dplyr",
  "readr","purrr","tidyr","sf","terra","yaml","config","qs",
  "lgr","progressr","checkmate","janitor",
  "testthat","lintr","styler","quarto","precommit"
)
pak::pak(pkgs, ask = FALSE)

## Define a function `lib()` to attach packages.  Use this instead of
## repeated library() calls scattered across your scripts.  Keep
## side‑effects minimal: attaching packages in functions avoids
## polluting the global environment when the file is sourced.

lib <- function() {
  op <- options(stringsAsFactors = FALSE)
  on.exit(options(op), add = TRUE)
  suppressPackageStartupMessages({
    library(targets); library(tarchetypes); library(dplyr); library(readr)
    library(purrr); library(tidyr); library(sf); library(terra)
    library(arrow); library(duckdb); library(config); library(qs)
    library(lgr); library(progressr)
  })
  invisible(TRUE)
}