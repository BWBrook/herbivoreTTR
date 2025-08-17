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
