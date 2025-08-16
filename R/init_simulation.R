# Initialises plant and herbivore traits and spatial arrangement
init_simulation <- function(
  temp_mode = "flat",
  veg_types = c(0, 1, 2),
  herbivore_mass = 5e5
) {
  conditions <- init_conditions(mode = temp_mode)
  plants     <- init_plants(veg_types = veg_types)
  herbivore  <- init_herbivore(mass = herbivore_mass)
  
  return(list(
    conditions = conditions,
    plants = plants,
    herbivore = herbivore
  ))
}
