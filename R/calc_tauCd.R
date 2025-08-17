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
