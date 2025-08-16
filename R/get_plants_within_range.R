# Identify plants within detection range
get_plants_within_range <- function(herbivore, plants) {
  plot_width <- sqrt(CONSTANTS$PLOT_SIZE)
  plot_height <- sqrt(CONSTANTS$PLOT_SIZE)
  
  distances <- calc_toroidal_distance(
    herbivore$xcor, herbivore$ycor,
    plants$xcor, plants$ycor,
    plot_width, plot_height
  )
  
  keep <- distances <= CONSTANTS$DETECTION_DISTANCE & plants$ms > 0
  within_range <- plants[keep, ]
  within_range$distance <- distances[keep]
  
  return(within_range)
}
