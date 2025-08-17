#' Pick a plant by tastiness-weighted sampling
#'
#' Samples one plant_id from candidates using probabilities proportional to
#' provided `tastiness_scores`. Returns `NA_integer_` when all scores are zero.
#'
#' @param plants_in_range data.frame of candidate plants; must include
#'   `plant_id` and have the same number of rows as `tastiness_scores`.
#' @param tastiness_scores Numeric vector of non-negative scores.
#' @return Integer plant_id or `NA_integer_` when no suitable plant exists.
#' @examples
#' # pick_a_plant(plants_in_range, scores)
#' @export
pick_a_plant <- function(plants_in_range, tastiness_scores) {
  if (sum(tastiness_scores) == 0) {
    return(NA_integer_)  # No tasty plants; returns NA
  } else {
    prob <- tastiness_scores / sum(tastiness_scores)
    selected_row <- sample(seq_len(nrow(plants_in_range)), 1, prob = prob)
    return(plants_in_range$plant_id[selected_row])
  }
}
