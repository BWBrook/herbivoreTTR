#' Carbon transport rate (skeleton)
#'
#' Calculates tauC: net carbon transport rate between compartments.
#'
#' @param plant_row A single-row data.frame or named list representing one plant.
#'   Consumes columns: `cs`, `ms`, `cr`, `mr` (optionally `cd`, `md`), and resistances
#'   `rsC`, `rrC`, `rdC`.
#' @return numeric scalar (stub returns NA_real_).
#' @note Write-target: plant$tauC
calc_tauC <- function(plant_row) {
  NA_real_
}

#' Nitrogen transport rate (skeleton)
#'
#' @inheritParams calc_tauC
#' @note Write-target: plant$tauN
calc_tauN <- function(plant_row) {
  NA_real_
}

#' Carbon to defence transport rate (skeleton)
#'
#' @inheritParams calc_tauC
#' @note Write-target: plant$tauCd
calc_tauCd <- function(plant_row) {
  NA_real_
}

#' Nitrogen to defence transport rate (skeleton)
#'
#' @inheritParams calc_tauC
#' @note Write-target: plant$tauNd
calc_tauNd <- function(plant_row) {
  NA_real_
}

