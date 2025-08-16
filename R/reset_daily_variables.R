# Resets the daily variables tied directly to the herbivore state (energy, water balance, daily intake, etc.) 
# for the herbivore at the start of each simulated day
reset_daily_variables <- function(herbivore) {
  herbivore$intake_defence_day <- 0
  herbivore$intake_digest_carbs_day <- 0
  herbivore$intake_digest_protein_day <- 0
  herbivore$intake_NPE_day <- 0
  herbivore$intake_PE_day <- 0
  herbivore$intake_total_day <- 0
  herbivore$intake_water_drinking <- 0
  herbivore$intake_water_forage <- 0
  herbivore$metabolic_water_day <- 0
  herbivore$distance_moved <- 0
  herbivore$gut_content <-  max(0, 
                                sum(c(herbivore$digestion$bleaf, 
                                  herbivore$digestion$bstem, 
                                  herbivore$digestion$bdef))
                                )
  
  # Reset behaviour to MOVING at day's start
  herbivore$behaviour <- "MOVING"
  
  return(herbivore)
}
