# Evaluates whether the herbivore continues to eat its current plant, moves towards a new plant, 
# or selects a new plant based on nutrient and density criteria
make_foraging_decision <- function(herbivore, plants) {
  
  current_plant <- plants %>% filter(plant_id == herbivore$selected_plant_id)

  # Check if current plant is still edible (above minimal shoot biomass)
  can_continue_eating <- current_plant$ms > CONSTANTS$MIN_SHOOT

  if (herbivore$gut_content + CONSTANTS$TOLERANCE <= herbivore$gut_capacity && can_continue_eating) {
    
    ratio_diff <- abs(CONSTANTS$DP_TO_DC_TARGET - 
                      (current_plant$ns / CONSTANTS$N_TO_PROTEIN) / 
                      (current_plant$cs * CONSTANTS$PROP_DIGEST_SC))
                      
    probability_continue <- exp(-ratio_diff * CONSTANTS$PLANT_DENSITY / 1000)
    
    # Random chance weighted by nutritional suitability and plant density
    if (runif(1) < probability_continue) {
      herbivore$behaviour <- "EATING"
    } else {
      herbivore$behaviour <- "MOVING"
    }
    
  } else {
    herbivore$behaviour <- "MOVING"
  }

  return(herbivore)
}
