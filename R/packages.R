## Package bootstrap helpers (no side-effects on source)
##
## This file declares helper functions for interactive workflows.
## It MUST NOT install or attach packages at top-level to keep the
## package load deterministic and offline-friendly.

#' Ensure required packages are installed (interactive use)
#' @param pkgs Character vector of package names.
#' @return Invisibly TRUE. No-op if pkgs is NULL/empty.
ensure_packages_installed <- function(pkgs = NULL) {
  if (is.null(pkgs) || length(pkgs) == 0) return(invisible(TRUE))
  if (!requireNamespace("pak", quietly = TRUE)) {
    install.packages("pak")
  }
  pak::pak(pkgs, ask = FALSE)
  invisible(TRUE)
}

#' Attach common analysis packages (interactive use)
#' @return Invisibly TRUE.
lib <- function() {
  op <- options(stringsAsFactors = FALSE)
  on.exit(options(op), add = TRUE)
  suppressPackageStartupMessages({
    if (requireNamespace("targets", quietly = TRUE)) library(targets)
    if (requireNamespace("tarchetypes", quietly = TRUE)) library(tarchetypes)
    if (requireNamespace("dplyr", quietly = TRUE)) library(dplyr)
    if (requireNamespace("readr", quietly = TRUE)) library(readr)
    if (requireNamespace("purrr", quietly = TRUE)) library(purrr)
    if (requireNamespace("tidyr", quietly = TRUE)) library(tidyr)
    if (requireNamespace("sf", quietly = TRUE)) library(sf)
    if (requireNamespace("terra", quietly = TRUE)) library(terra)
    if (requireNamespace("arrow", quietly = TRUE)) library(arrow)
    if (requireNamespace("duckdb", quietly = TRUE)) library(duckdb)
    if (requireNamespace("config", quietly = TRUE)) library(config)
    if (requireNamespace("qs", quietly = TRUE)) library(qs)
    if (requireNamespace("lgr", quietly = TRUE)) library(lgr)
    if (requireNamespace("progressr", quietly = TRUE)) library(progressr)
  })
  invisible(TRUE)
}
