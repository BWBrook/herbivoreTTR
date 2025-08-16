# Determines the movement of the herbivore toward a chosen plant or a random point if no 
# suitable plant is found within reach. This implements toroidal (wrap-around) logic to keep 
# movement continuous within the world.
herbivore_move <- function(herbivore, plants, time_step_minutes = 1) {
  
  max_distance <- herbivore$fv_max * 60 * time_step_minutes
  
  if (!is.na(herbivore$selected_plant_id)) {
    target_plant <- plants %>% dplyr::filter(plant_id == herbivore$selected_plant_id)

    dx <- target_plant$xcor - herbivore$xcor
    dy <- target_plant$ycor - herbivore$ycor
    
    # Apply toroidal world-wrap
    world_dim <- sqrt(CONSTANTS$PLOT_SIZE)
    dx <- ifelse(abs(dx) > world_dim / 2, -sign(dx) * (world_dim - abs(dx)), dx)
    dy <- ifelse(abs(dy) > world_dim / 2, -sign(dy) * (world_dim - abs(dy)), dy)

    distance <- sqrt(dx^2 + dy^2)

    if (distance <= max_distance) {
      herbivore$xcor <- target_plant$xcor
      herbivore$ycor <- target_plant$ycor
      moved_distance <- distance
    } else {
      # Move towards the plant proportionally
      ratio <- max_distance / distance
      herbivore$xcor <- (herbivore$xcor + dx * ratio) %% world_dim
      herbivore$ycor <- (herbivore$ycor + dy * ratio) %% world_dim
      moved_distance <- max_distance
    }
  } else {
    # Random movement if no plant selected
    angle <- runif(1, 0, 2 * pi)
    herbivore$xcor <- (herbivore$xcor + cos(angle) * max_distance) %% sqrt(CONSTANTS$PLOT_SIZE)
    herbivore$ycor <- (herbivore$ycor + sin(angle) * max_distance) %% sqrt(CONSTANTS$PLOT_SIZE)
    moved_distance <- max_distance
  }

  herbivore$distance_moved <- herbivore$distance_moved + moved_distance

  return(herbivore)
}
