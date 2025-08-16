#!/usr/bin/env Rscript
# Example script for single-minute debugging (kept out of package load path).
# Usage: Rscript inst/scripts/main.R

suppressPackageStartupMessages({
  if (requireNamespace("dplyr", quietly = TRUE)) library(dplyr)
})

# Initialize conditions, plants, and herbivore
sim_init <- init_simulation(temp_mode = "stochastic")
conditions <- sim_init$conditions
plants     <- sim_init$plants
herbivore  <- sim_init$herbivore

# Run the daily simulation for a single minute
simulation_result <- run_daily_herbivore_simulation(
  herbivore = herbivore,
  plants = plants,
  conditions = conditions,
  minute_limit = 1
)

print(simulation_result$herbivore)
print(simulation_result$plants)
