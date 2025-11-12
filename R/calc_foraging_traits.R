#' Compute herbivore foraging traits
#'
#' Calculates bite size, gut capacity, handling time, and foraging velocity
#' from the herbivore mass using allometric relations.
#'
#' @param herbivore Herbivore state list with `mass` (g).
#' @return Updated `herbivore` list with fields `gut_capacity` (g),
#'   `bite_size` (g), `handling_time` (min/g), and `fv_max` (m/s).
#' @examples
#' h <- init_herbivore(5e5)
#' h <- calc_foraging_traits(h)
#' @export
calc_foraging_traits <- function(herbivore) {
  herbivore$gut_capacity   <- calc_gut_capacity(herbivore$mass) # maximum gut_capacity (g DM)
  herbivore$bite_size      <- calc_bite_size(herbivore$mass) # bite size [g DM/bite]
  herbivore$handling_time  <- calc_handling_time(herbivore$mass) # time to handle (crop and chew) a unit of food [min/g DM]
  herbivore$fv_max <- calc_foraging_velocity(herbivore$mass) # maximum foraging velocity [m/s]
  return(herbivore)
}
