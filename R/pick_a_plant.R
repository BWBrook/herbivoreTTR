# Pick a plant based on weighted random selection by tastiness
pick_a_plant <- function(plants_in_range, tastiness_scores) {
  if (sum(tastiness_scores) == 0) {
    return(NA_integer_)  # No tasty plants; returns NA
  } else {
    prob <- tastiness_scores / sum(tastiness_scores)
    selected_row <- sample(seq_len(nrow(plants_in_range)), 1, prob = prob)
    return(plants_in_range$plant_id[selected_row])
  }
}
