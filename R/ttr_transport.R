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

#' Nitrogen transport rate (skeleton)
#'
#' @inheritParams calc_tauC
#' @note Write-target: plant$tauN
calc_tauN <- function(plant_row) {
  Ms <- plant_row$ms; Mr <- plant_row$mr
  Ns <- plant_row$ns; Nr <- plant_row$nr
  RsN <- plant_row$rsN; RrN <- plant_row$rrN
  if (is.null(Ms) || is.null(Mr) || is.null(Ns) || is.null(Nr) || is.null(RsN) || is.null(RrN)) return(NA_real_)
  if (Ms <= 0 || Mr <= 0) return(0)
  denom <- RsN + RrN
  if (!is.finite(denom) || denom <= 0) return(0)
  (Nr / Mr - Ns / Ms) / denom
}

#' Carbon to defence transport rate (skeleton)
#'
#' @inheritParams calc_tauC
#' @note Write-target: plant$tauCd
calc_tauCd <- function(plant_row) {
  Ms <- plant_row$ms; Md <- plant_row$md
  Cs <- plant_row$cs; Cd <- plant_row$cd
  RsC <- plant_row$rsC; RdC <- plant_row$rdC
  if (is.null(Ms) || is.null(Md) || is.null(Cs) || is.null(Cd) || is.null(RsC) || is.null(RdC)) return(NA_real_)
  if (Ms <= 0 || Md <= 0) return(0)
  denom <- RsC + RdC
  if (!is.finite(denom) || denom <= 0) return(0)
  (Cs / Ms - Cd / Md) / denom
}

#' Nitrogen to defence transport rate (skeleton)
#'
#' @inheritParams calc_tauC
#' @note Write-target: plant$tauNd
calc_tauNd <- function(plant_row) {
  Mr <- plant_row$mr; Md <- plant_row$md
  Nr <- plant_row$nr; Nd <- plant_row$nd
  RdN <- plant_row$rdN; RrN <- plant_row$rrN
  if (is.null(Mr) || is.null(Md) || is.null(Nr) || is.null(Nd) || is.null(RdN) || is.null(RrN)) return(NA_real_)
  if (Mr <= 0 || Md <= 0) return(0)
  denom <- RdN + RrN
  if (!is.finite(denom) || denom <= 0) return(0)
  (Nr / Mr - Nd / Md) / denom
}
