#' Derive an ingested available-energy schedule
#'
#' Convert prescribed dry-matter intake rates to the existing ingested
#' available-energy schedule using one fixed dry-matter-basis
#' metabolizable-energy density.
#'
#' @param parameters A food-energy parameter record created by
#'   [new_food_energy_parameters()].
#' @param schedule A prescribed dry-matter intake schedule created by
#'   [new_dry_matter_intake_schedule()].
#'
#' @return A 24-row ingested available-energy schedule created by
#'   [new_ingested_available_energy_schedule()].
#' @export
derive_ingested_available_energy_schedule <- function(
  parameters,
  schedule
) {
  .validate_food_energy_parameters(parameters)
  .validate_dry_matter_intake_schedule(schedule)

  converted_rates_kj_h <-
    as.double(schedule$prescribed_dry_matter_intake_kg_dm_h) *
      as.double(parameters$metabolizable_energy_density_kj_kg_dm)
  if (any(!is.finite(converted_rates_kj_h))) {
    stop(
      "Converted ingested available-energy rates must all be finite.",
      call. = FALSE
    )
  }

  new_ingested_available_energy_schedule(
    as.integer(schedule$hour_of_day),
    converted_rates_kj_h
  )
}

.validate_food_energy_parameters <- function(parameters) {
  density_name <- "metabolizable_energy_density_kj_kg_dm"
  if (!.has_exact_named_fields(parameters, density_name)) {
    stop(
      paste0(
        "`parameters` must be a list record containing only ",
        "`metabolizable_energy_density_kj_kg_dm`."
      ),
      call. = FALSE
    )
  }

  .validate_food_energy_density(
    parameters$metabolizable_energy_density_kj_kg_dm,
    "parameters$metabolizable_energy_density_kj_kg_dm"
  )

  invisible(NULL)
}

.validate_dry_matter_intake_schedule <- function(schedule) {
  expected_names <- c(
    "hour_of_day",
    "prescribed_dry_matter_intake_kg_dm_h"
  )
  if (
    !is.data.frame(schedule) ||
      nrow(schedule) != 24L ||
      !.has_exact_named_fields(schedule, expected_names)
  ) {
    stop(
      paste0(
        "`schedule` must be a 24-row data frame containing only ",
        "`hour_of_day` and `prescribed_dry_matter_intake_kg_dm_h`."
      ),
      call. = FALSE
    )
  }

  .validate_dry_matter_intake_schedule_fields(
    schedule$hour_of_day,
    schedule$prescribed_dry_matter_intake_kg_dm_h
  )

  invisible(NULL)
}
