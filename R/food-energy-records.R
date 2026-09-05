#' Create food-energy parameters
#'
#' Create the fixed food-property record used to convert prescribed dry-matter
#' intake to available-energy input.
#'
#' @param metabolizable_energy_density_kj_kg_dm Finite, strictly positive
#'   numeric scalar giving metabolizable-energy density in kilojoules per
#'   kilogram dry matter.
#'
#' @return A plain named list containing
#'   `metabolizable_energy_density_kj_kg_dm`.
#' @export
new_food_energy_parameters <- function(
  metabolizable_energy_density_kj_kg_dm
) {
  .validate_positive_numeric_scalar(
    metabolizable_energy_density_kj_kg_dm,
    "metabolizable_energy_density_kj_kg_dm"
  )

  list(
    metabolizable_energy_density_kj_kg_dm =
      as.double(metabolizable_energy_density_kj_kg_dm)
  )
}

#' Create a prescribed dry-matter intake schedule
#'
#' Create the prescribed dry-matter intake rate for each of the 24 one-hour
#' intervals in a day.
#'
#' @param hour_of_day Numeric vector equal to `0:23`, in order.
#' @param prescribed_dry_matter_intake_kg_dm_h Finite, non-negative numeric
#'   vector of 24 prescribed dry-matter intake rates in kilograms dry matter
#'   per hour.
#'
#' @return A base data frame with 24 rows and the columns `hour_of_day` and
#'   `prescribed_dry_matter_intake_kg_dm_h`.
#' @export
new_dry_matter_intake_schedule <- function(
  hour_of_day,
  prescribed_dry_matter_intake_kg_dm_h
) {
  .validate_dry_matter_intake_schedule_fields(
    hour_of_day,
    prescribed_dry_matter_intake_kg_dm_h
  )

  data.frame(
    hour_of_day = as.integer(hour_of_day),
    prescribed_dry_matter_intake_kg_dm_h =
      as.double(prescribed_dry_matter_intake_kg_dm_h)
  )
}

.validate_dry_matter_intake_schedule_fields <- function(
  hour_of_day,
  prescribed_dry_matter_intake_kg_dm_h
) {
  if (!.is_hour_of_day_schedule(hour_of_day)) {
    stop(
      "`hour_of_day` must contain the ordered whole numeric values `0:23`.",
      call. = FALSE
    )
  }

  .validate_nonnegative_daily_numeric_vector(
    prescribed_dry_matter_intake_kg_dm_h,
    "prescribed_dry_matter_intake_kg_dm_h"
  )

  invisible(NULL)
}
