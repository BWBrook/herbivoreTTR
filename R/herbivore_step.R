# Perform a single herbivore behavioural step (movement & eating)
# Standardised to accept only (herbivore, plants);
# scalar parameters are read from herbivore fields or CONSTANTS.
herbivore_step <- function(herbivore, plants) {
  
  plot_width <- sqrt(CONSTANTS$PLOT_SIZE)
  plot_height <- sqrt(CONSTANTS$PLOT_SIZE)
  desired_dp_dc_ratio <- CONSTANTS$DP_TO_DC_TARGET
  bite_size <- herbivore$bite_size
  gut_capacity <- herbivore$gut_capacity
  handling_time <- herbivore$handling_time
  
  # State: MOVING
  if (is.na(herbivore$selected_plant_id) || herbivore$behaviour == "MOVING") {
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
      
      # Amount the herbivore can eat this minute
      intake_possible <- min(
        (1 / handling_time) / 1000,      # kg DM/min
        bite_size / 1000,                # g to kg conversion
        gut_capacity - herbivore$gut_content, 
        selected_plant$ms
      )
      
      # Update plant biomass
      plants$ms[plants$plant_id == herbivore$selected_plant_id] <- selected_plant$ms - intake_possible
      
      # Update herbivore gut content
      herbivore$gut_content <- herbivore$gut_content + intake_possible
      
      if (herbivore$gut_content >= gut_capacity) {
        herbivore$behaviour <- "REST"
      }
      
    } else {
      herbivore$behaviour <- "MOVING"
    }
  }
  
  return(list(herbivore = herbivore, plants = plants))
}
