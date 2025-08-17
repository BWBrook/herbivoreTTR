#' Trapezoid envelope 1 (skeleton)
#'
#' Simple trapezoidal envelope with a single rise-fall region.
#'
#' @param x Numeric input.
#' @param a,b Numeric thresholds.
#' @return numeric scalar (stub returns NA_real_).
#' @note Helper; no direct write-targets.
trap1 <- function(x, a, b) {
  den <- b - a
  # Avoid division by zero or negative widths
  den <- ifelse(den <= 0, Inf, den)
  val <- (x - a) / den
  # Clamp to [0, 1]
  pmax(pmin(val, 1), 0)
}
