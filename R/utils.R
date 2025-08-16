# Supporting utility functions

select_randomly <- function(vec) sample(vec, 1, replace=FALSE)

# Calculate Euclidean distance between herbivore and plant (considering toroidal wrapping)
calc_toroidal_distance <- function(x1, y1, x2, y2, plot_width, plot_height) {
  dx <- pmin(abs(x1 - x2), plot_width - abs(x1 - x2))
  dy <- pmin(abs(y1 - y2), plot_height - abs(y1 - y2))
  sqrt(dx^2 + dy^2)
}
