# Temporary main.R script for single-minute debugging
setwd("C:/git/herbivore-ttr")

# Load necessary scripts into global environment
library(magrittr)
source("src/constants.R")
source("src/conditions.R")
source("src/herbivore.R")
source("src/herbivore_behaviour.R")
source("src/herbivore_calculations.R")
source("src/plants.R")
source("src/utils.R")

# Step 1: Initialize conditions, plants, and herbivore
sim_init <- init_simulation(temp_mode = "stochastic")
conditions <- sim_init$conditions
plants     <- sim_init$plants
herbivore  <- sim_init$herbivore

# Step 2: Run the daily simulation for a single minute (controlled test)
# Here we temporarily modify the run_daily_herbivore_simulation() function, or better,
# pass a parameter minute_limit = 1, to allow single-minute debugging
simulation_result <- run_daily_herbivore_simulation(
  herbivore = herbivore, 
  plants = plants, 
  conditions = conditions,
  minute_limit = 1 # Run only the first minute for debugging
)

# Step 3: Check outputs for immediate debugging
cat("\n--- Single-Minute Debugging Results ---\n")

cat("Herbivore status after one minute:\n")
print(simulation_result$herbivore)

cat("\nPlant statuses after one minute:\n")
print(simulation_result$plants)

cat("\nCheck gut content and selected plant ID:\n")
print(simulation_result$herbivore$gut_content)
print(simulation_result$herbivore$selected_plant_id)

# Additional debug outputs as needed
