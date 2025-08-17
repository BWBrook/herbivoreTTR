#' Trapezoid envelope 2 (skeleton)
#'
#' Piecewise trapezoid defined by four breakpoints.
#'
#' @param x Numeric input.
#' @param a,b,c,d Numeric thresholds (ordered a <= b <= c <= d).
#' @return numeric scalar (stub returns NA_real_).
#' @note Helper; no direct write-targets.
trap2 <- function(x, a, b, c, d) {
  den1 <- b - a
  den2 <- d - c
  den1 <- ifelse(den1 <= 0, Inf, den1)
  den2 <- ifelse(den2 <= 0, Inf, den2)
  up <- (x - a) / den1
  down <- (d - x) / den2
  # Clamp each component, then overall clamp to [0, 1]
  val <- pmin(pmax(up, 0), 1)
  val <- pmin(val, pmax(down, 0))
  pmax(pmin(val, 1), 0)
}
