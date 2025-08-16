#' Carbon uptake (skeleton)
#'
#' Computes carbon uptake into the plant shoot compartment.
#'
#' @param plant_row Single-row data.frame or named list for a plant.
#' @param CLeaf Numeric: available carbon in leaves [kg C].
#' @param K_C_forced Numeric: environmental forcing scalar for C uptake (unitless).
#' @param K_M Numeric: Michaelis-Menten/Monod constant (unit depends on formulation).
#' @param PI_C Numeric: photosynthetic input or driver (unit depends on formulation).
#' @return numeric scalar (stub returns NA_real_).
#' @note Write-target: plant$uc
calc_UC <- function(plant_row, CLeaf, K_C_forced, K_M, PI_C) {
  NA_real_
}

#' Nitrogen uptake (skeleton)
#'
#' Computes nitrogen uptake into the root compartment.
#'
#' @param plant_row Single-row data.frame or named list for a plant.
#' @param N0 Numeric: available nitrogen in soil [kg N].
#' @param K_M Numeric: Michaelis-Menten/Monod constant (unit depends on formulation).
#' @param PI_N Numeric: driver for N uptake (unit depends on formulation).
#' @return numeric scalar (stub returns NA_real_).
#' @note Write-target: plant$un
calc_UN <- function(plant_row, N0, K_M, PI_N) {
  NA_real_
}

#' Sigmoid scaling function (skeleton)
#'
#' Generic sigmoid function; placeholder for growth allocation scaling.
#'
#' @param x,k,b Numeric parameters.
#' @return numeric scalar (stub returns NA_real_).
sf <- function(x, k, b) {
  NA_real_
}

#' Shoot growth (skeleton)
#'
#' Computes growth increment for shoots.
#'
#' @param plant_row Single-row data.frame or named list for a plant.
#' @param G_SHOOT_forced Numeric: forcing scalar for shoot growth (unitless).
#' @return numeric scalar (stub returns NA_real_).
#' @note Write-target: plant$gs
calc_Gs <- function(plant_row, G_SHOOT_forced) {
  NA_real_
}

#' Root growth (skeleton)
#'
#' @inheritParams calc_Gs
#' @note Write-target: plant$gr
calc_Gr <- function(plant_row, G_ROOT_forced) {
  NA_real_
}

#' Defence growth (skeleton)
#'
#' @inheritParams calc_Gs
#' @note Write-target: plant$gd
calc_Gd <- function(plant_row, G_DEF_forced) {
  NA_real_
}

#' dCs/dt (skeleton)
#'
#' Rate of change of shoot carbon.
#'
#' @param plant_row Single-row data.frame or named list for a plant.
#' @param FRACTION_C Numeric fraction parameter for allocation.
#' @return numeric scalar (stub returns NA_real_).
#' @note Output used by orchestrator to update `cs`.
calc_dCs_dt <- function(plant_row, FRACTION_C) {
  NA_real_
}

#' dCr/dt (skeleton)
#'
#' @inheritParams calc_dCs_dt
#' @note Output used by orchestrator to update `cr`.
calc_dCr_dt <- function(plant_row, FRACTION_C) {
  NA_real_
}

#' dCd/dt (skeleton)
#'
#' @inheritParams calc_dCs_dt
#' @note Output used by orchestrator to update `cd` (defence C), if present.
calc_dCd_dt <- function(plant_row, FRACTION_C) {
  NA_real_
}

#' dNs/dt (skeleton)
#'
#' @param plant_row Single-row data.frame or named list for a plant.
#' @param FRACTION_N Numeric fraction parameter for allocation.
#' @return numeric scalar (stub returns NA_real_).
#' @note Output used by orchestrator to update `ns`.
calc_dNs_dt <- function(plant_row, FRACTION_N) {
  NA_real_
}

#' dNr/dt (skeleton)
#'
#' @inheritParams calc_dNs_dt
#' @note Output used by orchestrator to update `nr`.
calc_dNr_dt <- function(plant_row, FRACTION_N) {
  NA_real_
}

#' dNd/dt (skeleton)
#'
#' @inheritParams calc_dNs_dt
#' @note Output used by orchestrator to update `nd` (defence N), if present.
calc_dNd_dt <- function(plant_row, FRACTION_N) {
  NA_real_
}

