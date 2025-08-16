# Calculate plant tastiness based on distance, nutritional match, and defense
calc_plant_tastiness <- function(plants_in_range, herbivore, desired_dp_dc_ratio) {
  # Use defence column name consistent with init_plants: `bdef`
  with(plants_in_range, {
    diff_ratio <- abs(desired_dp_dc_ratio - (ns / cs))
    defence <- if (!"bdef" %in% names(plants_in_range)) 0 else bdef
    tastiness <- 1 / (diff_ratio + distance + defence)
    tastiness[is.nan(tastiness) | is.infinite(tastiness)] <- 0
    tastiness
  })
}
