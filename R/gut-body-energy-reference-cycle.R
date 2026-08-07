#' Run a repeated-day gut and body-energy reference cycle
#'
#' Repeat one 24-hour ingestion schedule until the gut trajectory converges,
#' then run two measured days from a declared body-energy state. Burn-in
#' advances only the gut; measured days use [run_gut_body_energy_day()]
#' unchanged and carry both closing states forward.
#'
#' @param initial_gut_state A plain gut-energy state record created by
#'   [new_gut_energy_state()].
#' @param measurement_body_state A plain body-energy state record created by
#'   [new_body_energy_state()].
#' @param gut_parameters A plain gut-energy parameter record created by
#'   [new_gut_energy_parameters()].
#' @param body_parameters A plain body-energy parameter record created by
#'   [new_body_energy_parameters()].
#' @param schedule A 24-row prescribed ingestion schedule created by
#'   [new_ingested_available_energy_schedule()].
#' @param routine_activity_schedule A 24-row schedule created by
#'   [new_routine_activity_expenditure_schedule()]. It is applied only during
#'   the two measured body days.
#' @param gut_convergence_relative_tolerance A bare finite numeric scalar
#'   strictly between zero and one.
#' @param max_burn_in_days A bare integer scalar of at least two.
#'
#' @return A plain list containing the burn-in `convergence` table, the
#'   48-row measured `hourly` ledger, and the two-row measured `daily` summary.
#' @export
run_gut_body_energy_reference_cycle <- function(
  initial_gut_state,
  measurement_body_state,
  gut_parameters,
  body_parameters,
  schedule,
  routine_activity_schedule,
  gut_convergence_relative_tolerance,
  max_burn_in_days
) {
  .validate_gut_energy_state(initial_gut_state)
  .validate_body_energy_state(measurement_body_state)
  .validate_gut_energy_parameters(gut_parameters)
  .validate_body_energy_parameters(body_parameters)
  .validate_ingested_available_energy_schedule(schedule)
  .validate_routine_activity_expenditure_schedule(
    routine_activity_schedule
  )
  gut_convergence_relative_tolerance <-
    .validate_gut_convergence_relative_tolerance(
      gut_convergence_relative_tolerance
    )
  max_burn_in_days <- .validate_max_burn_in_days(max_burn_in_days)

  initial_gut_energy_kj <- as.double(unclass(
    initial_gut_state$gut_available_energy_kj
  ))
  measurement_body_energy_kj <- as.double(unclass(
    measurement_body_state$body_energy_reserve_kj
  ))
  gut_release_fraction_h <- as.double(unclass(
    gut_parameters$gut_release_fraction_h
  ))
  maintenance_expenditure_kj_h <- as.double(unclass(
    body_parameters$maintenance_expenditure_kj_h
  ))
  hour_of_day <- as.integer(unclass(schedule$hour_of_day))
  ingested_energy_kj_h <- as.double(unclass(
    schedule$prescribed_ingested_available_energy_kj_h
  ))
  routine_activity_kj_h <- as.double(unclass(
    routine_activity_schedule$
      prescribed_routine_activity_expenditure_kj_h
  ))

  burn_in <- .run_reference_cycle_gut_burn_in(
    initial_gut_energy_kj,
    gut_release_fraction_h,
    ingested_energy_kj_h,
    gut_convergence_relative_tolerance,
    max_burn_in_days
  )
  measured <- .run_reference_cycle_measurement(
    burn_in$state$gut_available_energy_kj,
    measurement_body_energy_kj,
    gut_release_fraction_h,
    maintenance_expenditure_kj_h,
    hour_of_day,
    ingested_energy_kj_h,
    routine_activity_kj_h
  )

  list(
    convergence = burn_in$convergence,
    hourly = measured$hourly,
    daily = measured$daily
  )
}

.validate_gut_convergence_relative_tolerance <- function(value) {
  if (
    !.is_bare_numeric_vector(value) ||
      length(value) != 1L ||
      !is.finite(value) ||
      value <= 0 ||
      value >= 1
  ) {
    stop(
      paste0(
        "`gut_convergence_relative_tolerance` must be one bare finite ",
        "numeric value strictly between 0 and 1."
      ),
      call. = FALSE
    )
  }

  as.double(unclass(value))
}

.validate_max_burn_in_days <- function(value) {
  if (
    !.is_whole_number(value) ||
      length(value) != 1L ||
      as.double(unclass(value)) < 2 ||
      as.double(unclass(value)) > .Machine$integer.max
  ) {
    stop(
      paste0(
        "`max_burn_in_days` must be one finite whole numeric value ",
        "from 2 to `.Machine$integer.max`."
      ),
      call. = FALSE
    )
  }

  as.integer(unclass(value))
}

.run_reference_cycle_gut_burn_in <- function(
  initial_gut_energy_kj,
  gut_release_fraction_h,
  ingested_energy_kj_h,
  relative_tolerance,
  max_burn_in_days
) {
  burn_in_days <- integer()
  initial_energy_kj <- numeric()
  final_energy_kj <- numeric()
  boundary_changes_kj <- numeric()
  maximum_differences_kj <- numeric()
  realized_tolerances_kj <- numeric()
  convergence_flags <- logical()
  current_gut_energy_kj <- initial_gut_energy_kj
  previous_day <- NULL
  converged_day <- NA_integer_

  for (burn_in_day in seq_len(max_burn_in_days)) {
    current_day <- .run_reference_cycle_gut_day(
      current_gut_energy_kj,
      gut_release_fraction_h,
      ingested_energy_kj_h
    )
    boundaries_kj <- current_day$boundaries_kj
    cycle_boundary_change_kj <-
      boundaries_kj[[25L]] - boundaries_kj[[1L]]
    if (!is.finite(cycle_boundary_change_kj)) {
      stop(
        "The realized gut cycle-boundary change must be finite.",
        call. = FALSE
      )
    }

    maximum_difference_kj <- NA_real_
    realized_tolerance_kj <- NA_real_
    converged <- FALSE

    if (burn_in_day >= 2L) {
      comparison <- .compare_reference_cycle_gut_days(
        current_day,
        previous_day,
        relative_tolerance,
        cycle_boundary_change_kj
      )
      maximum_difference_kj <-
        comparison$maximum_difference_kj
      realized_tolerance_kj <-
        comparison$realized_tolerance_kj
      converged <- comparison$converged
    }

    burn_in_days[[burn_in_day]] <- burn_in_day
    initial_energy_kj[[burn_in_day]] <- boundaries_kj[[1L]]
    final_energy_kj[[burn_in_day]] <- boundaries_kj[[25L]]
    boundary_changes_kj[[burn_in_day]] <- cycle_boundary_change_kj
    maximum_differences_kj[[burn_in_day]] <- maximum_difference_kj
    realized_tolerances_kj[[burn_in_day]] <- realized_tolerance_kj
    convergence_flags[[burn_in_day]] <- converged
    current_gut_energy_kj <-
      current_day$state$gut_available_energy_kj
    if (isTRUE(converged)) {
      converged_day <- burn_in_day
      break
    }
    previous_day <- current_day
  }

  if (is.na(converged_day)) {
    stop(
      "Gut burn-in did not converge within `max_burn_in_days`.",
      call. = FALSE
    )
  }

  convergence <- data.frame(
    burn_in_day = burn_in_days,
    gut_available_energy_initial_kj = initial_energy_kj,
    gut_available_energy_final_kj = final_energy_kj,
    cycle_boundary_change_kj = boundary_changes_kj,
    max_abs_previous_day_trajectory_difference_kj =
      maximum_differences_kj,
    realized_convergence_tolerance_kj = realized_tolerances_kj,
    converged = convergence_flags
  )

  list(
    state = list(gut_available_energy_kj = current_gut_energy_kj),
    convergence = convergence
  )
}

.run_reference_cycle_gut_day <- function(
  initial_gut_energy_kj,
  gut_release_fraction_h,
  ingested_energy_kj_h
) {
  boundaries_kj <- numeric(25L)
  ingested_kj <- numeric(24L)
  assimilated_kj <- numeric(24L)
  current_gut_energy_kj <- initial_gut_energy_kj
  boundaries_kj[[1L]] <- current_gut_energy_kj

  for (row_index in seq_len(24L)) {
    transition <- .step_gut_energy_core(
      current_gut_energy_kj,
      gut_release_fraction_h,
      ingested_energy_kj_h[[row_index]]
    )
    ingested_kj[[row_index]] <-
      transition$fluxes$prescribed_ingested_available_energy_kj
    assimilated_kj[[row_index]] <-
      transition$fluxes$assimilated_energy_kj
    current_gut_energy_kj <-
      transition$state$gut_available_energy_kj
    boundaries_kj[[row_index + 1L]] <-
      current_gut_energy_kj
  }

  list(
    state = list(gut_available_energy_kj = current_gut_energy_kj),
    boundaries_kj = boundaries_kj,
    ingested_kj = ingested_kj,
    assimilated_kj = assimilated_kj
  )
}

.compare_reference_cycle_gut_days <- function(
  current_day,
  previous_day,
  relative_tolerance,
  cycle_boundary_change_kj
) {
  maximum_difference_kj <- max(abs(
    current_day$boundaries_kj - previous_day$boundaries_kj
  ))
  if (!is.finite(maximum_difference_kj)) {
    stop(
      "The realized gut trajectory difference must be finite.",
      call. = FALSE
    )
  }

  realized_scale_kj <- max(
    1,
    abs(current_day$boundaries_kj),
    abs(previous_day$boundaries_kj),
    sum(abs(current_day$ingested_kj)),
    sum(abs(current_day$assimilated_kj)),
    sum(abs(previous_day$assimilated_kj))
  )
  if (!is.finite(realized_scale_kj)) {
    stop(
      "The realized gut convergence scale must be finite.",
      call. = FALSE
    )
  }

  realized_tolerance_kj <- relative_tolerance * realized_scale_kj
  if (
    !is.finite(realized_tolerance_kj) ||
      realized_tolerance_kj <= 0
  ) {
    stop(
      paste0(
        "The realized gut convergence tolerance must be finite and ",
        "strictly positive."
      ),
      call. = FALSE
    )
  }

  list(
    maximum_difference_kj = maximum_difference_kj,
    realized_tolerance_kj = realized_tolerance_kj,
    converged =
      maximum_difference_kj <= realized_tolerance_kj &&
        abs(cycle_boundary_change_kj) <= realized_tolerance_kj
  )
}

.run_reference_cycle_measurement <- function(
  initial_gut_energy_kj,
  measurement_body_energy_kj,
  gut_release_fraction_h,
  maintenance_expenditure_kj_h,
  hour_of_day,
  ingested_energy_kj_h,
  routine_activity_kj_h
) {
  day_1 <- .run_gut_body_energy_day_prevalidated(
    initial_gut_energy_kj,
    measurement_body_energy_kj,
    gut_release_fraction_h,
    maintenance_expenditure_kj_h,
    hour_of_day,
    ingested_energy_kj_h,
    routine_activity_kj_h
  )
  day_2 <- .run_gut_body_energy_day_prevalidated(
    day_1$daily$gut_available_energy_final_kj[[1L]],
    day_1$daily$body_energy_reserve_final_kj[[1L]],
    gut_release_fraction_h,
    maintenance_expenditure_kj_h,
    hour_of_day,
    ingested_energy_kj_h,
    routine_activity_kj_h
  )

  hourly <- rbind(
    data.frame(measurement_day = rep(1L, 24L), day_1$hourly),
    data.frame(measurement_day = rep(2L, 24L), day_2$hourly)
  )
  daily <- rbind(
    data.frame(measurement_day = 1L, day_1$daily),
    data.frame(measurement_day = 2L, day_2$daily)
  )
  row.names(hourly) <- seq_len(nrow(hourly))
  row.names(daily) <- seq_len(nrow(daily))

  list(hourly = hourly, daily = daily)
}
