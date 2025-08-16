# Handles the actual process of consuming biomass from the selected plant, updates both 
# plant and herbivore state
herbivore_eat <- function(herbivore, plants) {

  plant <- plants %>% dplyr::filter(plant_id == herbivore$selected_plant_id)

  prop_defence <- plant$bdef / plant$ms
  # intake_rate in kg/min: handling_time is min per g; convert to kg with /1000
  intake_rate_kg <- (1 / herbivore$handling_time) / 1000 * (1 - prop_defence)

  # Calculate maximum possible intake given constraints
  # Available gut capacity in kg (gut is tracked in grams)
  capacity_kg <- pmax(herbivore$gut_capacity - herbivore$gut_content, 0) / 1000
  bite_limit_kg <- herbivore$bite_size / 1000
  available_plant_kg <- pmax(plant$ms - CONSTANTS$MIN_SHOOT, 0)
  potential_intake_kg <- min(intake_rate_kg, bite_limit_kg, capacity_kg, available_plant_kg)

  if (potential_intake_kg <= 0) return(list(herbivore=herbivore, plants=plants))

  # Allocate intake to leaf/stem/def
  total_parts <- plant$ms
  leaf_intake_kg <- potential_intake_kg * (plant$ms / total_parts)
  stem_intake <- 0  # placeholder; modify if stems are separately defined
  def_intake_kg  <- potential_intake_kg * (plant$bdef / total_parts)

  # Update digestion vectors (first hour position)
  # Push intakes to gut in grams
  herbivore$digestion$bleaf[1]   <- herbivore$digestion$bleaf[1] + leaf_intake_kg * 1000
  herbivore$digestion$bstem[1]   <- herbivore$digestion$bstem[1] + stem_intake * 1000
  herbivore$digestion$bdef[1]    <- herbivore$digestion$bdef[1]  + def_intake_kg * 1000

  # Update plant biomass after consumption
  plants <- plants %>% 
    dplyr::mutate(
      ms = ifelse(plant_id == herbivore$selected_plant_id, pmax(ms - potential_intake_kg, 0), ms),
      bdef = ifelse(plant_id == herbivore$selected_plant_id, pmax(bdef - def_intake_kg, 0), bdef)
    )

  # Update herbivore gut content
  # Update daily intake tracker and gut content
  herbivore$intake_total_day <- herbivore$intake_total_day + potential_intake_kg * 1000
  herbivore <- update_gut_content(herbivore)

  return(list(herbivore=herbivore, plants=plants))
}
