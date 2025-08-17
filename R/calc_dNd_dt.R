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
