#' Advance responsive forage biomass over a finite interval
#'
#' Advance one or more independent forage stocks under autonomous density-
#' dependent gross production and proportional senescence. The production
#' rate is `growth_rate_h * growth_multiplier` and the production-saturation
#' biomass is the positive density scale. The transition is the exact
#' analytical solution
#' of `dB/dt = aB - bB^2`, where `a = growth_rate_h * growth_multiplier -
#' senescence_rate_h` and `b = growth_rate_h * growth_multiplier / K`.
#' This transition contains no grazing or other stock removal.
#'
#' @param biomass_kg_dm_ha Finite, non-negative standing biomass values, one
#'   per independent forage stock, in kilograms dry matter per hectare.
#' @param production_saturation_biomass_kg_dm_ha Finite, strictly positive
#'   production-saturation biomass values, one per stock, in kilograms dry
#'   matter per hectare. Each value
#'   must be at least its corresponding opening biomass.
#' @param growth_rate_h One finite numeric value in `[0, 1]` giving the hourly
#'   intrinsic growth rate.
#' @param senescence_rate_h One finite numeric value in `[0, 1]` giving the
#'   hourly proportional senescence rate.
#' @param growth_multiplier One finite numeric value in `[0, 1]`, or one such
#'   value per stock, scaling intrinsic growth.
#' @param duration_h One finite numeric value in `(0, 1]` giving the transition
#'   duration in hours.
#'
#' @return A plain list containing numeric-vector `state` (closing biomass)
#'   and `fluxes`, with numeric vectors `growth_kg_dm_ha`,
#'   `senescence_kg_dm_ha`, and `balance_residual_kg_dm_ha`.
#' @export
step_responsive_forage <- function(
  biomass_kg_dm_ha,
  production_saturation_biomass_kg_dm_ha,
  growth_rate_h,
  senescence_rate_h,
  growth_multiplier = 1,
  duration_h = 1
) {
  .validate_responsive_forage_inputs(
    biomass_kg_dm_ha,
    production_saturation_biomass_kg_dm_ha,
    growth_rate_h,
    senescence_rate_h,
    growth_multiplier,
    duration_h
  )

  biomass_kg_dm_ha <- as.double(biomass_kg_dm_ha)
  production_saturation_biomass_kg_dm_ha <- as.double(
    production_saturation_biomass_kg_dm_ha
  )
  growth_rate_h <- as.double(growth_rate_h)
  senescence_rate_h <- as.double(senescence_rate_h)
  growth_multiplier <- as.double(growth_multiplier)
  if (length(growth_multiplier) == 1L) {
    growth_multiplier <- rep.int(
      growth_multiplier,
      length(biomass_kg_dm_ha)
    )
  }
  duration_h <- as.double(duration_h)

  effective_growth_rate_h <- growth_rate_h * growth_multiplier
  a_h <- effective_growth_rate_h - senescence_rate_h
  b_h <- effective_growth_rate_h / production_saturation_biomass_kg_dm_ha
  x <- a_h * duration_h

  E_h <- numeric(length(biomass_kg_dm_ha))
  zero_a <- a_h == 0
  E_h[zero_a] <- duration_h
  E_h[!zero_a] <- expm1(x[!zero_a]) / a_h[!zero_a]

  arithmetic <- c(effective_growth_rate_h, a_h, b_h, x, E_h)
  if (any(!is.finite(arithmetic))) {
    stop(
      "The responsive-forage transition arithmetic must remain finite.",
      call. = FALSE
    )
  }

  B <- biomass_kg_dm_ha
  b_positive <- b_h > 0
  B_new <- numeric(length(B))

  # The algebraically equivalent scaled form below avoids overflow when
  # B * exp(x) overflows even though the logistic solution itself is finite.
  if (any(b_positive)) {
    positive_index <- which(b_positive)
    z <- b_h[positive_index] * B[positive_index] * E_h[positive_index]
    D <- 1 + z
    numerator <- B[positive_index] * exp(x[positive_index])
    if (any(!is.finite(z)) || any(!is.finite(D))) {
      stop(
        "The responsive-forage transition arithmetic must remain finite.",
        call. = FALSE
      )
    }

    representable <- is.finite(numerator)
    if (any(representable)) {
      B_new[positive_index[representable]] <-
        numerator[representable] / D[representable]
    }
    if (any(!representable)) {
      fallback_index <- positive_index[!representable]
      exp_minus_x <- exp(-x[fallback_index])
      scaled_E_h <- -expm1(-x[fallback_index]) / a_h[fallback_index]
      scaled_D <- exp_minus_x +
        b_h[fallback_index] * B[fallback_index] * scaled_E_h
      if (any(!is.finite(exp_minus_x)) ||
        any(!is.finite(scaled_E_h)) ||
        any(!is.finite(scaled_D))) {
        stop(
          "The responsive-forage transition arithmetic must remain finite.",
          call. = FALSE
        )
      }
      B_new[fallback_index] <- B[fallback_index] / scaled_D
    }
  }

  if (any(!b_positive)) {
    zero_index <- which(!b_positive)
    B_new[zero_index] <- B[zero_index] * exp(x[zero_index])
  }

  integral_B <- numeric(length(B))
  if (any(b_positive)) {
    positive_index <- which(b_positive)
    z <- b_h[positive_index] * B[positive_index] * E_h[positive_index]
    # This branch preserves the limiting value B * E when z underflows to 0.
    integral_B[positive_index] <- ifelse(
      z == 0,
      B[positive_index] * E_h[positive_index],
      log1p(z) / b_h[positive_index]
    )
  }
  if (any(!b_positive)) {
    zero_index <- which(!b_positive)
    integral_B[zero_index] <- B[zero_index] * E_h[zero_index]
  }

  senescence_kg_dm_ha <- senescence_rate_h * integral_B
  growth_kg_dm_ha <- B_new - B + senescence_kg_dm_ha
  # With no production input, growth is exactly zero; assigning the limiting
  # value avoids retaining cancellation noise from B_new - B + senescence.
  growth_kg_dm_ha[effective_growth_rate_h == 0] <- 0
  arithmetic <- c(B_new, integral_B, senescence_kg_dm_ha, growth_kg_dm_ha)
  if (any(!is.finite(arithmetic))) {
    stop(
      "The responsive-forage transition arithmetic must remain finite.",
      call. = FALSE
    )
  }

  # Roundoff can put a stock or an intrinsically non-negative flux a few ulps
  # below zero at an absorbing boundary or exact carrying capacity.
  stock_tolerance <- 100 * .Machine$double.eps *
    pmax(1, production_saturation_biomass_kg_dm_ha)
  if (any(B_new < -stock_tolerance)) {
    stop(
      "The responsive-forage transition produced a negative closing stock.",
      call. = FALSE
    )
  }
  B_new[B_new < 0] <- 0

  flux_scale <- pmax(
    1,
    abs(B_new),
    abs(B),
    abs(senescence_kg_dm_ha),
    abs(growth_kg_dm_ha)
  )
  flux_tolerance <- 100 * .Machine$double.eps * flux_scale
  if (any(senescence_kg_dm_ha < -flux_tolerance) ||
    any(growth_kg_dm_ha < -flux_tolerance)) {
    stop(
      "The responsive-forage transition produced an invalid negative flux.",
      call. = FALSE
    )
  }
  senescence_kg_dm_ha[senescence_kg_dm_ha < 0] <- 0
  growth_kg_dm_ha[growth_kg_dm_ha < 0] <- 0

  balance_residual_kg_dm_ha <-
    (B_new - B) - (growth_kg_dm_ha - senescence_kg_dm_ha)
  balance_tolerance <- 100 * .Machine$double.eps * pmax(
    1,
    abs(B_new),
    abs(B),
    abs(growth_kg_dm_ha),
    abs(senescence_kg_dm_ha)
  )
  if (any(abs(balance_residual_kg_dm_ha) > balance_tolerance)) {
    stop(
      "The responsive-forage biomass balance does not close.",
      call. = FALSE
    )
  }

  list(
    state = B_new,
    fluxes = list(
      growth_kg_dm_ha = growth_kg_dm_ha,
      senescence_kg_dm_ha = senescence_kg_dm_ha,
      balance_residual_kg_dm_ha = balance_residual_kg_dm_ha
    )
  )
}

.validate_responsive_forage_inputs <- function(
  biomass_kg_dm_ha,
  production_saturation_biomass_kg_dm_ha,
  growth_rate_h,
  senescence_rate_h,
  growth_multiplier,
  duration_h
) {
  if (
    !.is_numeric_vector(biomass_kg_dm_ha) ||
      length(biomass_kg_dm_ha) < 1L ||
      any(!is.finite(as.double(biomass_kg_dm_ha))) ||
      any(as.double(biomass_kg_dm_ha) < 0)
  ) {
    stop(
      "`biomass_kg_dm_ha` must be a non-empty finite, non-negative numeric vector.",
      call. = FALSE
    )
  }
  if (
    !.is_numeric_vector(production_saturation_biomass_kg_dm_ha) ||
      length(production_saturation_biomass_kg_dm_ha) != length(biomass_kg_dm_ha) ||
      any(!is.finite(as.double(production_saturation_biomass_kg_dm_ha))) ||
      any(as.double(production_saturation_biomass_kg_dm_ha) <= 0) ||
      any(
        as.double(biomass_kg_dm_ha) >
          as.double(production_saturation_biomass_kg_dm_ha)
      )
  ) {
    stop(
      paste0(
        "`production_saturation_biomass_kg_dm_ha` must contain one finite, ",
        "strictly positive numeric value per biomass value, with production ",
        "saturation biomass at least as large as opening biomass."
      ),
      call. = FALSE
    )
  }
  .validate_responsive_forage_scalar(
    growth_rate_h,
    "growth_rate_h",
    inclusive_lower = TRUE
  )
  .validate_responsive_forage_scalar(
    senescence_rate_h,
    "senescence_rate_h",
    inclusive_lower = TRUE
  )
  if (
    !.is_numeric_vector(growth_multiplier) ||
      !(length(growth_multiplier) %in% c(1L, length(biomass_kg_dm_ha))) ||
      any(!is.finite(as.double(growth_multiplier))) ||
      any(as.double(growth_multiplier) < 0) ||
      any(as.double(growth_multiplier) > 1)
  ) {
    stop(
      paste0(
        "`growth_multiplier` must be one finite value, or one finite value ",
        "per biomass value, in [0, 1]."
      ),
      call. = FALSE
    )
  }
  if (
    !.is_numeric_vector(duration_h) ||
      length(duration_h) != 1L ||
      !is.finite(as.double(duration_h)) ||
      as.double(duration_h) <= 0 ||
      as.double(duration_h) > 1
  ) {
    stop(
      "`duration_h` must be one finite numeric value in (0, 1].",
      call. = FALSE
    )
  }

  invisible(NULL)
}

.validate_responsive_forage_scalar <- function(
  value,
  field_name,
  inclusive_lower = FALSE
) {
  if (
    !.is_numeric_vector(value) ||
      length(value) != 1L ||
      !is.finite(as.double(value))
  ) {
    stop(
      sprintf(
        "`%s` must be one finite numeric value in [0, 1].",
        field_name
      ),
      call. = FALSE
    )
  }
  canonical_value <- as.double(value)
  lower_ok <- if (inclusive_lower) canonical_value >= 0 else canonical_value > 0
  if (!lower_ok || canonical_value > 1) {
    stop(
      sprintf(
        "`%s` must be one finite numeric value in [0, 1].",
        field_name
      ),
      call. = FALSE
    )
  }

  invisible(NULL)
}
