# Chooses a new plant to move towards, based on weighted probability calculations involving 
# plant size, distance, nutrition, and defenses
select_new_plant <- function(herbivore, plants) {

  world_dim <- sqrt(CONSTANT$PLOT_SIZE)
  
  # Compute distances to all plants considering toroidal wrapping
  distances <- plants %>%
    rowwise() %>%
    mutate(
      dx = min(abs(xcor - herbivore$xcor), world_dim - abs(xcor - herbivore$xcor)),
      dy = min(abs(ycor - herbivore$ycor), world_dim - abs(ycor - herbivore$ycor)),
      distance = sqrt(dx^2 + dy^2)
    ) %>%
    ungroup() %>%
    filter(ms > CONSTANT$MIN_SHOOT, distance <= CONSTANT$DETECTION_DISTANCE)
  
  if (nrow(distances) == 0) {
    herbivore$selected_plant_id <- NA
    return(herbivore)
  }

  # Calculate tastiness scores
  distances <- distances %>%
    mutate(
      ratio_diff = abs(CONSTANT$dp_to_dc_target - (ns / CONSTANT$N_TO_PROTEIN) / (cs * CONSTANT$PROP_DIGEST_SC)),
      tastiness = 1 / (ratio_diff + b_def + distance)
    )
  
  # Normalize scores to probabilities
  probabilities <- distances$tastiness / sum(distances$tastiness)

  selected_index <- sample(1:nrow(distances), size = 1, prob = probabilities)
  herbivore$selected_plant_id <- distances$plant_id[selected_index]

  return(herbivore)
}
