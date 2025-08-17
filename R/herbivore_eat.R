#' Consume biomass from the selected plant
#'
#' Internal helper that transfers intake from a selected plant to the
#' herbivore's gut and updates plant biomass. Handles basic constraints
#' (bite size, handling time, gut capacity, remaining plant biomass).
#'
#' @param herbivore Herbivore state list; requires `selected_plant_id`,
#'   `handling_time`, `bite_size`, `gut_capacity`, `gut_content`, and
#'   `digestion` vectors.
#' @param plants data.frame of plants with `plant_id`, `ms`, `bdef`, `xcor`,
#'   `ycor`.
#' @return List with updated `herbivore` and `plants`.
#' @keywords internal
herbivore_eat <- function(herbivore, plants) {

  plant <- plants %>% dplyr::filter(plant_id == herbivore$selected_plant_id)

  total_shoot <- plant$bleaf + plant$bstem + plant$bdef
  prop_defence <- if (total_shoot > 0) plant$bdef / total_shoot else 0
  # intake_rate in kg/min: handling_time is min per g; convert to kg with /1000
  intake_rate_kg <- (1 / herbivore$handling_time) / 1000 * (1 - prop_defence)

  # Calculate maximum possible intake given constraints
  # Available gut capacity in kg (gut is tracked in grams)
  capacity_kg <- pmax(herbivore$gut_capacity - herbivore$gut_content, 0) / 1000
  bite_limit_kg <- herbivore$bite_size / 1000
  available_plant_kg <- pmax(plant$ms - CONSTANTS$MIN_SHOOT, 0)
  potential_intake_kg <- min(intake_rate_kg, bite_limit_kg, capacity_kg, available_plant_kg)

  if (potential_intake_kg <= 0) return(list(herbivore=herbivore, plants=plants))

  # Allocate intake to leaf/stem/def by their proportions in shoot
  total_parts <- total_shoot
  if (total_parts <= 0) return(list(herbivore=herbivore, plants=plants))
  leaf_intake_kg <- potential_intake_kg * (plant$bleaf / total_parts)
  stem_intake_kg <- potential_intake_kg * (plant$bstem / total_parts)
  def_intake_kg  <- potential_intake_kg * (plant$bdef  / total_parts)

  # Update digestion vectors (first hour position)
  # Push intakes to gut in grams
  herbivore$digestion$bleaf[1]   <- herbivore$digestion$bleaf[1] + leaf_intake_kg * 1000
  herbivore$digestion$bstem[1]   <- herbivore$digestion$bstem[1] + stem_intake_kg * 1000
  herbivore$digestion$bdef[1]    <- herbivore$digestion$bdef[1]  + def_intake_kg * 1000

  # Schedule digestible carbohydrate (dc_*) and protein (dp_*) grams for release after MRT
  digestible_carbs <- function(dm_kg) dm_kg * 1000 * CONSTANTS$FRACTION_C * CONSTANTS$PROP_DIGEST_SC
  digestible_prot  <- function(dm_kg) dm_kg * 1000 * CONSTANTS$FRACTION_N * CONSTANTS$N_TO_PROTEIN * CONSTANTS$PROP_DIGEST_TP

  herbivore$digestion$dc_leaf[1] <- herbivore$digestion$dc_leaf[1] + digestible_carbs(leaf_intake_kg)
  herbivore$digestion$dc_stem[1] <- herbivore$digestion$dc_stem[1] + digestible_carbs(stem_intake_kg)
  herbivore$digestion$dp_leaf[1] <- herbivore$digestion$dp_leaf[1] + digestible_prot(leaf_intake_kg)
  herbivore$digestion$dp_stem[1] <- herbivore$digestion$dp_stem[1] + digestible_prot(stem_intake_kg)
  herbivore$digestion$dp_def[1]  <- herbivore$digestion$dp_def[1]  + digestible_prot(def_intake_kg)

  # Update plant biomass after consumption
  plants <- plants %>% 
    dplyr::mutate(
      bleaf = ifelse(plant_id == herbivore$selected_plant_id, pmax(bleaf - leaf_intake_kg, 0), bleaf),
      bstem = ifelse(plant_id == herbivore$selected_plant_id, pmax(bstem - stem_intake_kg, 0), bstem),
      bdef  = ifelse(plant_id == herbivore$selected_plant_id, pmax(bdef  - def_intake_kg,  0), bdef)
    )
  plants <- plants %>%
    dplyr::mutate(
      ms = ifelse(plant_id == herbivore$selected_plant_id, pmax(bleaf + bstem + bdef, 0), ms)
    )

  # Update herbivore gut content
  # Update daily intake tracker and gut content
  herbivore$intake_total_day <- herbivore$intake_total_day + potential_intake_kg * 1000
  herbivore <- update_gut_content(herbivore)

  return(list(herbivore=herbivore, plants=plants))
}
