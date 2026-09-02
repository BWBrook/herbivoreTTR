#' Run one prescribed body-water day
#'
#' Carry one physical body-water stock through 24 one-hour inputs.
#'
#' @param initial_state A body-water state created by
#'   [new_body_water_state()].
#' @param parameters Body-water parameters created by
#'   [new_body_water_parameters()].
#' @param schedule A schedule created by [new_body_water_schedule()].
#'
#' @return A plain list containing hourly and daily ledgers plus the final
#'   state.
#' @export
run_body_water_day <- function(initial_state, parameters, schedule) {
  .validate_body_water_state(initial_state)
  .validate_body_water_parameters(parameters)
  .validate_body_water_schedule(schedule)
  if (
    as.double(initial_state$body_water_kg) >
      as.double(parameters$normal_body_water_kg)
  ) {
    stop("The initial body-water stock exceeds its normal level.", call. = FALSE)
  }

  hourly_rows <- vector("list", 24L)
  state <- initial_state
  for (row_index in seq_len(24L)) {
    opening_body_water_kg <- as.double(state$body_water_kg)
    step <- step_body_water(
      state,
      parameters,
      schedule[row_index, , drop = FALSE]
    )
    hourly_rows[[row_index]] <- data.frame(
      hour_of_day = schedule$hour_of_day[[row_index]],
      body_water_start_kg = opening_body_water_kg,
      food_derived_water_kg = step$fluxes$food_derived_water_kg,
      available_drinking_water_kg =
        step$fluxes$available_drinking_water_kg,
      realized_drinking_water_kg =
        step$fluxes$realized_drinking_water_kg,
      ordinary_water_loss_kg = step$fluxes$ordinary_water_loss_kg,
      excess_water_elimination_kg =
        step$fluxes$excess_water_elimination_kg,
      net_body_water_rate_kg_h = step$fluxes$net_body_water_rate_kg_h,
      body_water_change_kg = step$fluxes$body_water_change_kg,
      body_water_end_kg = step$state$body_water_kg,
      body_water_balance_residual_kg =
        step$fluxes$body_water_balance_residual_kg,
      body_water_below_critical =
        step$fluxes$body_water_below_critical
    )
    state <- step$state
  }
  hourly <- do.call(rbind, hourly_rows)
  row.names(hourly) <- NULL

  body_water_initial_kg <- hourly$body_water_start_kg[[1L]]
  body_water_final_kg <- hourly$body_water_end_kg[[24L]]
  total_food_derived_water_kg <- sum(hourly$food_derived_water_kg)
  total_available_drinking_water_kg <-
    sum(hourly$available_drinking_water_kg)
  total_realized_drinking_water_kg <-
    sum(hourly$realized_drinking_water_kg)
  total_ordinary_water_loss_kg <- sum(hourly$ordinary_water_loss_kg)
  total_excess_water_elimination_kg <-
    sum(hourly$excess_water_elimination_kg)
  expected_body_water_change_kg <-
    total_food_derived_water_kg +
      total_realized_drinking_water_kg -
      total_ordinary_water_loss_kg -
      total_excess_water_elimination_kg
  observed_body_water_change_kg <-
    body_water_final_kg - body_water_initial_kg
  body_water_balance_residual_kg <-
    observed_body_water_change_kg - expected_body_water_change_kg
  arithmetic <- c(
    body_water_initial_kg,
    body_water_final_kg,
    total_food_derived_water_kg,
    total_available_drinking_water_kg,
    total_realized_drinking_water_kg,
    total_ordinary_water_loss_kg,
    total_excess_water_elimination_kg,
    expected_body_water_change_kg,
    observed_body_water_change_kg,
    body_water_balance_residual_kg
  )
  if (any(!is.finite(arithmetic))) {
    stop("The daily body-water accounting must remain finite.", call. = FALSE)
  }
  tolerance_kg <- .body_water_tolerance(arithmetic)
  if (abs(body_water_balance_residual_kg) > tolerance_kg) {
    stop("The daily body-water balance does not close.", call. = FALSE)
  }

  daily <- data.frame(
    body_water_initial_kg = body_water_initial_kg,
    body_water_final_kg = body_water_final_kg,
    minimum_body_water_kg = min(hourly$body_water_end_kg),
    total_food_derived_water_kg = total_food_derived_water_kg,
    total_available_drinking_water_kg =
      total_available_drinking_water_kg,
    total_realized_drinking_water_kg = total_realized_drinking_water_kg,
    total_ordinary_water_loss_kg = total_ordinary_water_loss_kg,
    total_excess_water_elimination_kg =
      total_excess_water_elimination_kg,
    expected_body_water_change_kg = expected_body_water_change_kg,
    observed_body_water_change_kg = observed_body_water_change_kg,
    body_water_balance_residual_kg = body_water_balance_residual_kg,
    body_water_below_critical = any(hourly$body_water_below_critical)
  )

  list(hourly = hourly, daily = daily, final_state = state)
}
