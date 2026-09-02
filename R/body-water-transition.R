#' Advance the body-water stock by one hour
#'
#' Add food-derived water, realize only the drinking needed to approach the
#' declared normal stock, subtract ordinary and prescribed incremental
#' evaporative loss, and eliminate any remaining excess above normal. The
#' transition preserves a directly inspectable water balance and reports
#' whether the closing stock is below the critical interpretation boundary.
#'
#' @param state A body-water state created by [new_body_water_state()].
#' @param parameters Body-water parameters created by
#'   [new_body_water_parameters()].
#' @param input_row Exactly one row from [new_body_water_schedule()].
#'
#' @return A plain list containing the closing `state` and hourly `fluxes`.
#' @export
step_body_water <- function(state, parameters, input_row) {
  .validate_body_water_state(state)
  .validate_body_water_parameters(parameters)
  .validate_body_water_input_row(input_row)

  body_water_start_kg <- as.double(state$body_water_kg)
  normal_body_water_kg <- as.double(parameters$normal_body_water_kg)
  critical_body_water_kg <- as.double(parameters$critical_body_water_kg)
  ordinary_water_loss_kg <- as.double(
    parameters$ordinary_water_loss_kg_h
  )
  food_derived_water_kg <- as.double(
    input_row$prescribed_food_derived_water_kg_h
  )
  available_drinking_water_kg <- as.double(
    input_row$available_drinking_water_kg_h
  )
  incremental_evaporative_water_loss_kg <- as.double(
    input_row$prescribed_incremental_evaporative_water_loss_kg_h
  )
  tolerance_kg <- .body_water_tolerance(
    body_water_start_kg,
    normal_body_water_kg,
    critical_body_water_kg,
    ordinary_water_loss_kg,
    incremental_evaporative_water_loss_kg,
    food_derived_water_kg,
    available_drinking_water_kg
  )
  if (body_water_start_kg > normal_body_water_kg + tolerance_kg) {
    stop("The opening body-water stock exceeds its normal level.", call. = FALSE)
  }

  water_after_food_and_losses_kg <-
    body_water_start_kg +
      food_derived_water_kg -
      ordinary_water_loss_kg -
      incremental_evaporative_water_loss_kg
  drinking_capacity_kg <- max(
    normal_body_water_kg - water_after_food_and_losses_kg,
    0
  )
  realized_drinking_water_kg <- min(
    available_drinking_water_kg,
    drinking_capacity_kg
  )
  uncapped_body_water_end_kg <-
    water_after_food_and_losses_kg + realized_drinking_water_kg
  excess_water_elimination_kg <- max(
    uncapped_body_water_end_kg - normal_body_water_kg,
    0
  )
  body_water_end_kg <-
    uncapped_body_water_end_kg - excess_water_elimination_kg

  if (!is.finite(body_water_end_kg)) {
    stop("The proposed closing body-water stock must be finite.", call. = FALSE)
  }
  if (body_water_end_kg < -tolerance_kg) {
    stop("The proposed closing body-water stock is negative.", call. = FALSE)
  }
  if (body_water_end_kg < 0) {
    body_water_end_kg <- 0
  }

  body_water_change_kg <- body_water_end_kg - body_water_start_kg
  net_body_water_rate_kg_h <-
    food_derived_water_kg +
      realized_drinking_water_kg -
      ordinary_water_loss_kg -
      incremental_evaporative_water_loss_kg -
      excess_water_elimination_kg
  body_water_balance_residual_kg <-
    body_water_change_kg - net_body_water_rate_kg_h
  if (abs(body_water_balance_residual_kg) > tolerance_kg) {
    stop("The hourly body-water balance does not close.", call. = FALSE)
  }

  list(
    state = list(body_water_kg = body_water_end_kg),
    fluxes = list(
      food_derived_water_kg = food_derived_water_kg,
      available_drinking_water_kg = available_drinking_water_kg,
      realized_drinking_water_kg = realized_drinking_water_kg,
      ordinary_water_loss_kg = ordinary_water_loss_kg,
      incremental_evaporative_water_loss_kg =
        incremental_evaporative_water_loss_kg,
      excess_water_elimination_kg = excess_water_elimination_kg,
      net_body_water_rate_kg_h = net_body_water_rate_kg_h,
      body_water_change_kg = body_water_change_kg,
      body_water_balance_residual_kg = body_water_balance_residual_kg,
      body_water_below_critical =
        body_water_end_kg < critical_body_water_kg - tolerance_kg
    )
  )
}

.body_water_tolerance <- function(...) {
  values <- c(...)
  scale <- max(1, abs(values))
  tolerance <- 100 * .Machine$double.eps * scale
  if (!is.finite(tolerance)) {
    stop("The body-water accounting tolerance must be finite.", call. = FALSE)
  }

  tolerance
}
