# Core parameter calculations for herbivores based on allometric scaling

#' Gut capacity from body mass
#'
#' Computes gut capacity using an allometric relation A * mass^B.
#'
#' @param mass Numeric mass of the herbivore (g).
#' @return Numeric gut capacity (g dry matter).
#' @examples
#' calc_gut_capacity(5e5)
#' @export
calc_gut_capacity <- function(mass) {
  # return g DM (matches gut queues)
  mass_kg <- mass / 1000
  1000 * CONSTANTS$GUT_CAPACITY_A * (mass_kg ^ CONSTANTS$GUT_CAPACITY_B)
}

#' Bite size from body mass
#'
#' Allometric bite size scaling: A * mass^B.
#'
#' @param mass Numeric mass of the herbivore (g).
#' @return Numeric bite size (g dry matter per bite).
#' @examples
#' calc_bite_size(5e5)
#' @export
calc_bite_size <- function(mass) {
  # return g DM per bite
  mass_kg <- mass / 1000
  CONSTANTS$BITE_SIZE_A * (mass_kg ^ CONSTANTS$BITE_SIZE_B)
}

#' Handling time from body mass
#'
#' Allometric handling time scaling: A * mass^B.
#'
#' @param mass Numeric mass of the herbivore (g).
#' @return Numeric handling time (minutes per g dry matter).
#' @examples
#' calc_handling_time(5e5)
#' @export
calc_handling_time <- function(mass) {
  # min per g
  mass_kg <- mass / 1000
  CONSTANTS$HANDLING_TIME_A * (mass_kg ^ CONSTANTS$HANDLING_TIME_B)
}

#' Foraging velocity from body mass
#'
#' Allometric foraging speed scaling: A * mass^B.
#'
#' @param mass Numeric mass of the herbivore (g).
#' @return Numeric maximum foraging velocity (m/s).
#' @examples
#' calc_foraging_velocity(5e5)
#' @export
calc_foraging_velocity <- function(mass) {
  # m/s
  mass_kg <- mass / 1000
  CONSTANTS$FORAGE_VEL_A * (mass_kg ^ CONSTANTS$FORAGE_VEL_B)
}

#' Daily water requirement from body mass
#'
#' Computes daily water requirement via a linear scaling with mass.
#'
#' @param mass Numeric mass of the herbivore (g).
#' @return Numeric daily water requirement (g or mL per day, unit per CONSTANTS).
#' @examples
#' calc_water_requirement(5e5)
#' @export
calc_water_requirement <- function(mass) {
  # WATER_TURNOVER in L/kg/day → return g/day
  mass_kg <- mass / 1000
  (CONSTANTS$WATER_TURNOVER * mass_kg) * 1000
}
