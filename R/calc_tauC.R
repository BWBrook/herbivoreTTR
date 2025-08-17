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
  Ms <- plant_row$ms; Mr <- plant_row$mr
  Cs <- plant_row$cs; Cr <- plant_row$cr
  RsC <- plant_row$rsC; RrC <- plant_row$rrC
  if (is.null(Ms) || is.null(Mr) || is.null(Cs) || is.null(Cr) || is.null(RsC) || is.null(RrC)) return(NA_real_)
  if (Ms <= 0 || Mr <= 0) return(0)
  denom <- RsC + RrC
  if (!is.finite(denom) || denom <= 0) return(0)
  (Cs / Ms - Cr / Mr) / denom
}
