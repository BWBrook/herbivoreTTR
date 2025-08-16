# Calculate plant tastiness based on distance, nutritional match, and defense
calc_plant_tastiness <- function(plants_in_range, herbivore, desired_dp_dc_ratio) {
  with(plants_in_range, {
    diff_ratio <- abs(desired_dp_dc_ratio - (ns / cs))
    tastiness <- 1 / (diff_ratio + distance + b_def) # Can adjust weighting factors here if needed
    tastiness[is.nan(tastiness) | is.infinite(tastiness)] <- 0
    tastiness
  })
}
