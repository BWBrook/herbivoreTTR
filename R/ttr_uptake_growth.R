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
  Ms <- plant_row$ms
  Cs <- plant_row$cs
  if (is.null(Ms) || is.null(Cs)) return(NA_real_)
  if (Ms == 0) return(0)
  # (K_C * Ms) / (1 + Ms / K_M) * sf(Cs/Ms, PI_C, 100)
  num <- K_C_forced * Ms
  denom <- 1 + Ms / K_M
  if (!is.finite(denom) || denom <= 0) return(0)
  frac <- Cs / Ms
  val <- (num / denom) * sf(frac, PI_C, 100)
  if (!is.finite(val)) 0 else val
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
  Mr <- plant_row$mr
  Nr <- plant_row$nr
  if (is.null(Mr) || is.null(Nr)) return(NA_real_)
  if (Mr == 0) return(0)
  # (N0 * Mr) / (1 + Mr / K_M) * sf(Nr/Mr, PI_N, 1000)
  num <- N0 * Mr
  denom <- 1 + Mr / K_M
  if (!is.finite(denom) || denom <= 0) return(0)
  frac <- Nr / Mr
  val <- (num / denom) * sf(frac, PI_N, 1000)
  if (!is.finite(val)) 0 else val
}

#' Sigmoid scaling function (skeleton)
#'
#' Generic sigmoid function; placeholder for growth allocation scaling.
#'
#' @param x,k,b Numeric parameters.
#' @return numeric scalar (stub returns NA_real_).
sf <- function(x, k, b) {
  # 1 / (1 + exp((x - k) * b))
  z <- (x - k) * b
  res <- 1 / (1 + exp(z))
  res[!is.finite(res)] <- 0
  pmax(pmin(res, 1), 0)
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
  Ms <- plant_row$ms; Cs <- plant_row$cs; Ns <- plant_row$ns
  if (is.null(Ms) || is.null(Cs) || is.null(Ns)) return(NA_real_)
  if (Ms == 0) return(0)
  val <- G_SHOOT_forced * (Cs * Ns) / Ms
  if (!is.finite(val)) 0 else val
}

#' Root growth (skeleton)
#'
#' @inheritParams calc_Gs
#' @note Write-target: plant$gr
calc_Gr <- function(plant_row, G_ROOT_forced) {
  Mr <- plant_row$mr; Cr <- plant_row$cr; Nr <- plant_row$nr
  if (is.null(Mr) || is.null(Cr) || is.null(Nr)) return(NA_real_)
  if (Mr == 0) return(0)
  val <- G_ROOT_forced * (Cr * Nr) / Mr
  if (!is.finite(val)) 0 else val
}

#' Defence growth (skeleton)
#'
#' @inheritParams calc_Gs
#' @note Write-target: plant$gd
calc_Gd <- function(plant_row, G_DEF_forced) {
  Md <- plant_row$md; Cd <- plant_row$cd; Nd <- plant_row$nd
  if (is.null(Md) || is.null(Cd) || is.null(Nd)) return(NA_real_)
  if (Md == 0) return(0)
  val <- G_DEF_forced * (Cd * Nd) / Md
  if (!is.finite(val)) 0 else val
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
  UC <- plant_row$uc; Gs <- plant_row$gs; tauC <- plant_row$tauC; tauCd <- plant_row$tauCd
  if (any(sapply(list(UC, Gs, tauC, tauCd), is.null))) return(NA_real_)
  val <- UC - FRACTION_C * Gs - tauC - tauCd
  if (!is.finite(val)) 0 else val
}

#' dCr/dt (skeleton)
#'
#' @inheritParams calc_dCs_dt
#' @note Output used by orchestrator to update `cr`.
calc_dCr_dt <- function(plant_row, FRACTION_C) {
  tauC <- plant_row$tauC; Gr <- plant_row$gr
  if (any(sapply(list(tauC, Gr), is.null))) return(NA_real_)
  val <- tauC - FRACTION_C * Gr
  if (!is.finite(val)) 0 else val
}

#' dCd/dt (skeleton)
#'
#' @inheritParams calc_dCs_dt
#' @note Output used by orchestrator to update `cd` (defence C), if present.
calc_dCd_dt <- function(plant_row, FRACTION_C) {
  tauCd <- plant_row$tauCd; Gd <- plant_row$gd
  if (any(sapply(list(tauCd, Gd), is.null))) return(NA_real_)
  val <- tauCd - FRACTION_C * Gd
  if (!is.finite(val)) 0 else val
}

#' dNs/dt (skeleton)
#'
#' @param plant_row Single-row data.frame or named list for a plant.
#' @param FRACTION_N Numeric fraction parameter for allocation.
#' @return numeric scalar (stub returns NA_real_).
#' @note Output used by orchestrator to update `ns`.
calc_dNs_dt <- function(plant_row, FRACTION_N) {
  tauN <- plant_row$tauN; Gs <- plant_row$gs
  if (any(sapply(list(tauN, Gs), is.null))) return(NA_real_)
  val <- tauN - FRACTION_N * Gs
  if (!is.finite(val)) 0 else val
}

#' dNr/dt (skeleton)
#'
#' @inheritParams calc_dNs_dt
#' @note Output used by orchestrator to update `nr`.
calc_dNr_dt <- function(plant_row, FRACTION_N) {
  UN <- plant_row$un; Gr <- plant_row$gr; tauN <- plant_row$tauN; tauNd <- plant_row$tauNd
  if (any(sapply(list(UN, Gr, tauN, tauNd), is.null))) return(NA_real_)
  val <- UN - FRACTION_N * Gr - tauN - tauNd
  if (!is.finite(val)) 0 else val
}

#' dNd/dt (skeleton)
#'
#' @inheritParams calc_dNs_dt
#' @note Output used by orchestrator to update `nd` (defence N), if present.
calc_dNd_dt <- function(plant_row, FRACTION_N) {
  tauNd <- plant_row$tauNd; Gd <- plant_row$gd
  if (any(sapply(list(tauNd, Gd), is.null))) return(NA_real_)
  val <- tauNd - FRACTION_N * Gd
  if (!is.finite(val)) 0 else val
}
