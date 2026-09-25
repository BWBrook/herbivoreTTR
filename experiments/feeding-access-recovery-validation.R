# Targeted validation for the plant-matched return expectation (064).
# Sourcing this file defines checks only; it writes no files and runs no
# trajectories.
source("experiments/feeding-access-policy.R")

.recovery_expect_error <- function(expr) {
  inherits(tryCatch(force(expr), error = function(e) e), "error")
}

.recovery_repeated_forage <- function(biomass, age_h, growth_rate_h = .002,
  senescence_rate_h = .001, production_saturation_biomass_kg_dm_ha = 2000) {
  stopifnot(age_h >= 0, age_h == as.integer(age_h))
  state <- biomass
  if (age_h > 0) for (i in seq_len(age_h)) {
    state <- herbivoreTTR::step_responsive_forage(state,
      production_saturation_biomass_kg_dm_ha, growth_rate_h,
      senescence_rate_h, duration_h = 1)$state
  }
  state
}

validate_feeding_access_recovery <- function() {
  q_values <- c(.3, .6, 1.5, 3, 5)
  # The public forecast is indexed by integer opening day; use whole elapsed
  # days here so each age is represented exactly by that interface.
  ages_h <- c(0L, 24L, 48L, 240L)
  memory <- new_feeding_memory(1L)

  # The expectation agrees with the existing one-hour transition repeated for
  # the exact number of ungrazed hours, at every fixed search coefficient.
  for (q in q_values) for (age_h in ages_h) {
    expected <- feeding_expected_return(memory, 1L + age_h / 24,
      search_area_m2_h = q)
    repeated <- .recovery_repeated_forage(200 + 200 / q, age_h)
    reference <- min(250, q * max(repeated - 200, 0))
    if (age_h == 0L) reference <- 200
    stopifnot(isTRUE(all.equal(expected, reference, tolerance = 2e-12)))
  }

  # Opening-day indexing: the day after an observation has zero age, and the
  # following day has exactly one elapsed day.
  dated <- memory
  dated$last_return_kj_h <- 210
  dated$best_return_kj_h <- 250
  dated$last_observed_day <- 10
  stopifnot(identical(feeding_expected_return(dated, 11L, .6), 210))
  stopifnot(feeding_expected_return(dated, 12L, .6) > 210)

  # With a high cap, q=.3 approaches the baseline plant equilibrium return
  # (240 kJ/h) from below.
  rising <- memory
  rising$best_return_kj_h <- 10000
  low <- feeding_expected_return(rising, 1L, .3)
  high <- feeding_expected_return(rising, 1001L, .3)
  stopifnot(low == 200, high > low, high <= 240 + 1e-10)
  # A return-equivalent prior above the 1000 kg DM/ha plant equilibrium must
  # decline, while remaining inside the declared [residual, K] domain.
  declining <- rising
  declining$last_return_kj_h <- 3000
  declining$best_return_kj_h <- 10000
  stopifnot(feeding_expected_return(declining, 101L, 3) <
    feeding_expected_return(declining, 2L, 3))

  # Zero and negative linear coefficients use their proper exact limits.
  # A zero linear coefficient still has quadratic biomass loss.
  stopifnot(
    feeding_expected_return(rising, 1001L, 3, .002, .001) > 200,
    feeding_expected_return(rising, 1001L, 3, .001, .001) < 200,
    feeding_expected_return(rising, 1001L, 3, .0005, .001) < 200
  )
  for (r in c(.001, .0005)) {
    actual <- feeding_expected_return(memory, 11L, .6, r, .001)
    reference <- .6 * max(.recovery_repeated_forage(200 + 200 / .6,
      240L, r, .001) - 200, 0)
    stopifnot(isTRUE(all.equal(actual, reference, tolerance = 2e-12)))
  }
  decline250 <- rising
  decline250$last_return_kj_h <- 250
  stopifnot(feeding_expected_return(decline250, 1001L, .3) <
    feeding_expected_return(decline250, 2L, .3),
    abs(feeding_expected_return(decline250, 1001L, .3) - 240) < 1e-8)

  capped <- memory
  capped$best_return_kj_h <- 207
  stopifnot(all(feeding_expected_return(capped, 1001L, 5) <= 207))

  # Invalid search coefficients and priors outside the declared plant domain
  # are rejected; no hidden clamping is permitted.
  stopifnot(.recovery_expect_error(feeding_expected_return(memory, 1L, 0)))
  stopifnot(.recovery_expect_error(feeding_expected_return(memory, 1L, -1)))
  outside <- memory
  outside$last_return_kj_h <- 12000
  outside$best_return_kj_h <- 12000
  stopifnot(.recovery_expect_error(feeding_expected_return(outside, 1L, 3)))
  stopifnot(.recovery_expect_error(feeding_expected_return(memory, 1L, .6,
    production_saturation_biomass_kg_dm_ha = 100)))
  stopifnot(identical(
    feeding_two_day_expected_return(memory, 5L),
    feeding_two_day_expected_return(memory, 5L, search_area_m2_h = 3,
      growth_rate_h = .01)))

  before <- memory
  invisible(feeding_expected_return(memory, 17L, .6))
  stopifnot(identical(memory, before))
  invisible(TRUE)
}

if (sys.nframe() == 0L) {
  validate_feeding_access_recovery()
  cat("Feeding-access recovery expectation validation passed.\n")
}
