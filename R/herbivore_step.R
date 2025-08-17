#' One behavioural step (move/eat)
#'
#' Performs one minute of behaviour: selects target, moves toward it, and
#' eats when within `CONSTANTS$EAT_RADIUS`, updating both herbivore and plant
#' state. Scalar parameters are read from the `herbivore` object and
#' `CONSTANTS`.
#'
#' @param herbivore List of herbivore state.
#' @param plants data.frame of plant state.
#' @return List with `herbivore` and `plants` entries (both updated).
#' @examples
#' # res <- herbivore_step(herbivore, plants)
#' # str(res)
#' @export
herbivore_step <- function(herbivore, plants) {
  
  plot_width <- sqrt(CONSTANTS$PLOT_SIZE)
  plot_height <- sqrt(CONSTANTS$PLOT_SIZE)
  desired_dp_dc_ratio <- CONSTANTS$DP_TO_DC_TARGET
  bite_size <- herbivore$bite_size
  gut_capacity <- herbivore$gut_capacity
  handling_time <- herbivore$handling_time
  
  # State: MOVING
  if (is.na(herbivore$selected_plant_id) || herbivore$behaviour == "MOVING") {
    # ~10% chance to discard current target while moving
    if (herbivore$behaviour == "MOVING" && !is.na(herbivore$selected_plant_id) && runif(1) < 0.1) {
      herbivore$selected_plant_id <- NA_integer_
    }
    plants_in_range <- get_plants_within_range(herbivore, plants)
    
    if (nrow(plants_in_range) == 0) {
      # No plants nearby, move randomly
      herbivore$xcor <- runif(1, 0, plot_width)
      herbivore$ycor <- runif(1, 0, plot_height)
      herbivore$selected_plant_id <- NA_integer_
      herbivore$behaviour <- "MOVING"
    } else {
      tastiness_scores <- calc_plant_tastiness(plants_in_range, herbivore, desired_dp_dc_ratio)
      selected_id <- pick_a_plant(plants_in_range, tastiness_scores)
      
      if (!is.na(selected_id)) {
        herbivore$selected_plant_id <- selected_id
        selected_plant <- plants[plants$plant_id == selected_id, ]
        
        distance_to_plant <- calc_toroidal_distance(
          herbivore$xcor, herbivore$ycor,
          selected_plant$xcor, selected_plant$ycor,
          plot_width, plot_height
        )
        
        if (distance_to_plant <= CONSTANTS$EAT_RADIUS) {
          herbivore$behaviour <- "EATING"
        } else {
          # Move towards plant (limited by max distance per minute)
          max_distance <- herbivore$fv_max * 60 # 1 min timestep
          step_distance <- min(max_distance, distance_to_plant)
          
          dx <- selected_plant$xcor - herbivore$xcor
          dy <- selected_plant$ycor - herbivore$ycor
          
          angle <- atan2(dy, dx)
          herbivore$xcor <- (herbivore$xcor + step_distance * cos(angle)) %% plot_width
          herbivore$ycor <- (herbivore$ycor + step_distance * sin(angle)) %% plot_height
          
          herbivore$behaviour <- "MOVING"
        }
      } else {
        herbivore$selected_plant_id <- NA_integer_
        herbivore$behaviour <- "MOVING"
      }
    }
  }
  
  # State: EATING
  if (herbivore$behaviour == "EATING" && !is.na(herbivore$selected_plant_id)) {
    selected_plant <- plants[plants$plant_id == herbivore$selected_plant_id, ]
    distance_to_plant <- calc_toroidal_distance(
      herbivore$xcor, herbivore$ycor,
      selected_plant$xcor, selected_plant$ycor,
      plot_width, plot_height
    )
    
    if (distance_to_plant <= CONSTANTS$EAT_RADIUS && selected_plant$ms > 0) {
      # Delegate intake to herbivore_eat(), which handles kg↔g conversions and gut vectors
      eat_res <- herbivore_eat(herbivore, plants)
      herbivore <- eat_res$herbivore
      plants <- eat_res$plants
      
      # Capacity check (gut in g, capacity in g)
      if (herbivore$gut_content + CONSTANTS$TOLERANCE >= gut_capacity) {
        herbivore$behaviour <- "REST"
      } else {
        herbivore$behaviour <- "EATING"
      }
    } else {
      herbivore$behaviour <- "MOVING"
    }
  }
  
  return(list(herbivore = herbivore, plants = plants))
}
