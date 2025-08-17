#' Decide whether to continue eating or move
#'
#' Simple rule-based decision to continue feeding on the current plant or
#' switch to movement, based on nutrient balance and density heuristics.
#'
#' @param herbivore Herbivore state list; expects `selected_plant_id`,
#'   `gut_content`, `gut_capacity`.
#' @param plants data.frame of plant state with at least `plant_id`, `ms`,
#'   `ns`, `cs`.
#' @return Updated `herbivore` list with `behaviour` set to "EATING" or
#'   "MOVING".
#' @keywords internal
make_foraging_decision <- function(herbivore, plants) {
  
  current_plant <- plants %>% dplyr::filter(plant_id == herbivore$selected_plant_id)

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
