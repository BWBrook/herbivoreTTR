# Handles the actual process of consuming biomass from the selected plant, updates both 
# plant and herbivore state
herbivore_eat <- function(herbivore, plants) {

  plant <- plants %>% filter(plant_id == herbivore$selected_plant_id)

  prop_defence <- plant$b_def / plant$ms
  intake_rate <- (1 / herbivore$handling_time) / 1000 * (1 - prop_defence)

  # Calculate maximum possible intake given constraints
  potential_intake <- min(intake_rate, 
                          herbivore$gut_capacity - herbivore$gut_content,
                          plant$ms - CONSTANTS$MIN_SHOOT)

  if (potential_intake <= 0) return(list(herbivore=herbivore, plants=plants))

  # Allocate intake to leaf/stem/def
  total_parts <- plant$ms
  leaf_intake <- potential_intake * (plant$ms / total_parts)
  stem_intake <- 0  # placeholder; modify if stems are separately defined
  def_intake  <- potential_intake * (plant$b_def / total_parts)

  # Update digestion vectors (first hour position)
  herbivore$digestion$bleaf[1]   <- herbivore$digestion$bleaf[1] + leaf_intake
  herbivore$digestion$bstem[1]   <- herbivore$digestion$bstem[1] + stem_intake
  herbivore$digestion$bdef[1]    <- herbivore$digestion$bdef[1]  + def_intake

  # Update plant biomass after consumption
  plants <- plants %>% 
    mutate(
      ms = ifelse(plant_id == herbivore$selected_plant_id, ms - potential_intake, ms),
      b_def = ifelse(plant_id == herbivore$selected_plant_id, b_def - def_intake, b_def)
    )

  # Update herbivore gut content
  herbivore <- update_gut_content(herbivore)

  return(list(herbivore=herbivore, plants=plants))
}
