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
