#' Soil-water forcer envelope (skeleton)
#'
#' Computes a forcing scalar for soil water availability based on water content.
#' Units: inputs in [kg or m^3 consistent with model], output is unitless scalar.
#'
#' @param sw Numeric: current soil water.
#' @param sw_w Numeric: wilting soil water threshold.
#' @param sw_star Numeric: optimal soil water threshold.
#' @return numeric scalar (stub returns NA_real_).
#' @note Write-target: used upstream by uptake/growth; does not write plant columns directly.
calc_SWforcer <- function(sw, sw_w, sw_star) {
  # Vectorized via trap1; clamps to [0, 1]
  trap1(sw, sw_w, sw_star)
}

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

#' Monod relation (skeleton)
#'
#' Monod function for saturating uptake/response: R / (k + R).
#'
#' @param R Numeric resource or concentration (non-negative).
#' @param k Numeric half-saturation constant (non-negative).
#' @return numeric scalar (stub returns NA_real_).
#' @note Guard denominators to avoid division by zero in implementation.
monod <- function(R, k) {
  R <- pmax(R, 0)
  k <- pmax(k, 0)
  denom <- R + k
  res <- ifelse(denom == 0, 0, R / denom)
  # Numeric safety and bounds
  res[!is.finite(res)] <- 0
  pmax(pmin(res, 1), 0)
}
