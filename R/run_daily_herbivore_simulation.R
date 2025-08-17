#' Run one simulated herbivore day
#'
#' Coordinates daily behaviour (decision, movement, feeding) and interactions
#' with plants. Also advances the plant TTR state at the start of the day via
#' `transport_resistance()` and updates daily energy and water balances.
#'
#' @param herbivore Herbivore state list.
#' @param plants data.frame of plant state.
#' @param conditions data.frame of environmental drivers with columns
#'   `temp_mean`, `sw`, `N`.
#' @param day_of_simulation Positive integer day index.
#' @param minute_limit Number of minutes to simulate (default 1440).
#' @return List with updated `herbivore`, `plants`, `daily_record` (optional
#'   minute-by-minute snapshots), and `daily_summary`.
#' @examples
#' sim <- init_simulation()
#' res <- run_daily_herbivore_simulation(sim$herbivore, sim$plants, sim$conditions)
#' names(res)
#' @export
run_daily_herbivore_simulation <- function(herbivore, plants, conditions, 
                                           day_of_simulation = 1, 
                                           minute_limit = 1440) {
                                            
  day_index <- ((day_of_simulation - 1) %% nrow(conditions)) + 1
  today_temp <- conditions$temp_mean[day_index]

  # Update plants via TTR orchestrator for this day before herbivory
  plants <- transport_resistance(plants, conditions, day_index)
  
  # 1) Reset daily variables for herbivore
  herbivore <- reset_daily_variables(herbivore)

  # 2) Pre-compute foraging traits (bite size, gut capacity, etc.)
  herbivore <- calc_foraging_traits(herbivore)

  # 3) Optionally store daily water requirement if you want
  herbivore$daily_water_requirement <- calc_water_requirement(herbivore$mass)

  # 4) Prepare a container for minute-by-minute records (if desired)
  daily_record <- vector("list", minute_limit)

  # Determine if herbivory is active (post spin-up and not disabled)
  spin_up_days <- CONSTANTS$SPIN_UP_LENGTH * nrow(conditions)
  herbivory_active <- isTRUE(CONSTANTS$HERBIVORY != 0) && (day_of_simulation > spin_up_days)

  # 5) Loop through each minute (only if herbivory is active)
  if (herbivory_active) for (minute in seq_len(minute_limit)) {

    # (a) Hourly digestion and energy incorporation
    if (minute %% 60 == 0) {
      herbivore <- hourly_digestion_step(herbivore)
    }

    # (b) Update gut content
    herbivore <- update_gut_content(herbivore)

    # (c) Decide if the herbivore is still in its foraging window
    if (minute < herbivore$time_spent_foraging * 60) {
      # Use herbivore_step() to handle movement or eating:
      step_result <- herbivore_step(herbivore, plants)
      herbivore  <- step_result$herbivore
      plants     <- step_result$plants
    }

    # (d) Optionally record data for debugging
    daily_record[[minute]] <- list(
      minute            = minute,
      xcor              = herbivore$xcor,
      ycor              = herbivore$ycor,
      gut_content       = herbivore$gut_content,
      selected_plant_id = herbivore$selected_plant_id,
      behaviour         = herbivore$behaviour,
      energy_balance    = herbivore$energy_balance,
      water_balance     = herbivore$water_balance
    )
  } # end herbivory loop

  # 6) At the end of day: check water, finalize energy
  # Set water turnover to depend on temperature
  temperature_factor <- 1 + CONSTANTS$TEMP_WATER_SCALING * (today_temp - 20)  # simple example
  herbivore$daily_water_requirement <- calc_water_requirement(herbivore$mass) * temperature_factor
  
  herbivore <- check_daily_water_balance(herbivore)
  herbivore <- calc_daily_energy_balance(herbivore)

  # 7) Summarize daily outcomes
  daily_summary <- list(
    day_of_simulation     = day_of_simulation,
    today_temp            = today_temp,
    total_distance_moved  = herbivore$distance_moved,
    total_biomass_eaten   = herbivore$intake_total_day,
    energy_balance        = herbivore$energy_balance,
    water_balance         = herbivore$water_balance
  )

  return(list(
    herbivore     = herbivore,
    plants        = plants,
    daily_record  = daily_record,
    daily_summary = daily_summary
  ))
}
