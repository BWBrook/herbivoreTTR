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
