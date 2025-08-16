# Core parameter calculations for herbivores based on allometric scaling

# Gut capacity based on herbivore mass
calc_gut_capacity <- function(mass) CONSTANTS$GUT_CAPACITY_A * mass^CONSTANTS$GUT_CAPACITY_B

# Bite size based on herbivore mass
calc_bite_size <- function(mass) CONSTANTS$BITE_SIZE_A * mass^CONSTANTS$BITE_SIZE_B

# Handling time (time per bite) based on herbivore mass
calc_handling_time <- function(mass) CONSTANTS$HANDLING_TIME_A * mass^CONSTANTS$HANDLING_TIME_B

# Foraging velocity based on herbivore mass
calc_foraging_velocity <- function(mass) CONSTANTS$FORAGE_VEL_A * mass^CONSTANTS$FORAGE_VEL_B

# Daily water requirement based on herbivore mass
calc_water_requirement <- function(mass) CONSTANTS$WATER_TURNOVER * mass
