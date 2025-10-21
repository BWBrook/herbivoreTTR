#' Initialise annual environmental conditions
#'
#' Generates daily temperature, available soil N, and standing water series
#' using simple deterministic or stochastic patterns.
#'
#' @param days_in_year Number of days to generate.
#' @param mode One of "flat", "stochastic", or "seasonal".
#' @param mean_temp Mean temperature (deg C) baseline for sinusoid.
#' @param amplitude Amplitude (deg C) for seasonal temperature pattern.
#' @return data.frame with columns `day`, `temp_mean`, `sw`, `N`.
#' @examples
#' conditions <- init_conditions(mode = "seasonal")
#' head(conditions)
#' @export
init_conditions <- function(days_in_year = 365,
                            mode = "flat",
                            mean_temp = 15,
                            amplitude = 10) {

  temp_mean <- mean_temp + amplitude * sin(seq(0, 2 * pi, length.out = days_in_year))
  # Southern grassland: mean_temp = 15, amplitude = 10 → 5°C to 25°C
  # Northern savanna: mean_temp = 25, amplitude = 5 → 20°C to 30°C
  # Rainforest plateau: mean_temp = 22, amplitude = 2 → 20°C to 24°C

  if (mode == "flat") {
    sw <- rep(0.5, days_in_year)
    soil_n <- rep(0.5, days_in_year)

  } else if (mode == "stochastic") {
    sw <- runif(days_in_year, min = 0.3, max = 0.6)
    soil_n <- runif(days_in_year, min = 0.4, max = 0.6)

  } else if (mode == "seasonal") {
    sw <- 0.45 + 0.1 * sin(seq(0, 2 * pi, length.out = days_in_year))
    soil_n <- 0.5 + 0.05 * cos(seq(0, 2 * pi, length.out = days_in_year))

  } else {
    rlang::abort(
      "Unknown mode for init_conditions: choose 'flat', 'stochastic', or 'seasonal'",
      class = "herbivoreTTR_init_conditions_mode",
      invalid_mode = mode
    )
  }

  conditions <- data.frame(
    day = seq_len(days_in_year),
    temp_mean = temp_mean, # temperature on this day [C]
    sw = sw, # standing water on this day [L]
    N = soil_n # N available in soil on this day [kg]
  )

  return(conditions)
}
