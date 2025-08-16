# Checks if water needs were met through forage and metabolic water; if not, adds 
# travel cost to water sources
check_daily_water_balance <- function(herbivore) {
  
  water_deficit <- herbivore$daily_water_requirement - 
                   (herbivore$metabolic_water_day + herbivore$intake_water_forage)
  
  if (water_deficit > 0) {
    herbivore$intake_water_drinking <- water_deficit
    herbivore$distance_moved <- herbivore$distance_moved + CONSTANTS$DIST_TO_WATER
  } else {
    herbivore$intake_water_drinking <- 0
  }
  
  herbivore$water_balance <- herbivore$water_balance +
                             herbivore$metabolic_water_day +
                             herbivore$intake_water_forage +
                             herbivore$intake_water_drinking -
                             herbivore$daily_water_requirement
  
  return(herbivore)
}
