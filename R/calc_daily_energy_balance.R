# Computes the net energy balance by subtracting energy expenditures (maintenance, locomotion) 
# from energy intake
calc_daily_energy_balance <- function(herbivore) {
  
  maintenance_cost <- CONSTANTS$ENERGY_MAINTENANCE_A * (herbivore$mass ^ CONSTANTS$ENERGY_MAINTENANCE_B)
  locomotion_cost <- (herbivore$distance_moved / 1000) * 
                     (CONSTANTS$ICL_A * (herbivore$mass ^ CONSTANTS$ICL_B)) / 100
  
  total_energy_cost <- maintenance_cost + locomotion_cost
  
  total_energy_intake <- herbivore$intake_PE_day + herbivore$intake_NPE_day
  
  herbivore$energy_balance <- herbivore$energy_balance +
                              total_energy_intake -
                              total_energy_cost
  return(herbivore)
}
