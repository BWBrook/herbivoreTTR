#' Plant 'tastiness' score
#'
#' Heuristic combining distance, nutrient ratio mismatch, and defence to
#' prioritise plants for feeding. Larger values are more attractive.
#'
#' @param plants_in_range data.frame of nearby plants; expects `ns`, `cs`,
#'   optional `bdef`, and `distance`.
#' @param herbivore Herbivore state list (unused placeholder for future use).
#' @param desired_dp_dc_ratio Numeric target ratio of digestible protein to
#'   digestible carbohydrate.
#' @return Numeric vector of tastiness scores aligned to `plants_in_range`.
#' @examples
#' # scores <- calc_plant_tastiness(plants_in_range, herb, 0.2)
#' @export
calc_plant_tastiness <- function(plants_in_range, herbivore, desired_dp_dc_ratio) {
  # Use defence column name consistent with init_plants: `bdef`
  with(plants_in_range, {
    diff_ratio <- abs(desired_dp_dc_ratio - (ns / cs))
    defence <- if (!"bdef" %in% names(plants_in_range)) 0 else bdef
    size_bonus <- log1p(ms) / log1p(10)  # gentle 0..~>1 scaling; 10 kg ~ 1.0
    tastiness <- size_bonus / (diff_ratio + distance + defence)
    tastiness[is.nan(tastiness) | is.infinite(tastiness)] <- 0
    tastiness
  })
}
