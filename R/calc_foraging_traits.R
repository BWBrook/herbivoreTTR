# Calculates bite size, gut capacity, handling time, and foraging velocity—traits related to the physiological 
# and morphological calculations for herbivores
calc_foraging_traits <- function(herbivore) {
  herbivore$gut_capacity   <- calc_gut_capacity(herbivore$mass) # maximum gut capacity [kg DM]
  herbivore$bite_size      <- calc_bite_size(herbivore$mass) # bite size [g DM/bite]
  herbivore$handling_time  <- calc_handling_time(herbivore$mass) # time to handle (crop and chew) a unit of food [min/g DM]
  herbivore$fv_max <- calc_foraging_velocity(herbivore$mass) # maximum foraging velocity [m/s]
  return(herbivore)
}
