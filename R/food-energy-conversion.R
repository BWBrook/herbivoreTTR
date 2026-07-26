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
    schedule$prescribed_dry_matter_intake_kg_dm_h *
      parameters$metabolizable_energy_density_kj_kg_dm
  if (any(!is.finite(converted_rates_kj_h))) {
    stop(
      "Converted ingested available-energy rates must all be finite.",
      call. = FALSE
    )
  }

  new_ingested_available_energy_schedule(
    schedule$hour_of_day,
    converted_rates_kj_h
  )
}

.validate_food_energy_parameters <- function(parameters) {
  density_name <- "metabolizable_energy_density_kj_kg_dm"
  if (!.is_exact_plain_named_list(parameters, density_name)) {
    stop(
      paste0(
        "`parameters` must be a plain list containing only ",
        "`metabolizable_energy_density_kj_kg_dm`."
      ),
      call. = FALSE
    )
  }

  .validate_food_energy_density(
    parameters$metabolizable_energy_density_kj_kg_dm,
    "parameters$metabolizable_energy_density_kj_kg_dm"
  )
  if (
    typeof(parameters$metabolizable_energy_density_kj_kg_dm) !=
      "double"
  ) {
    stop(
      paste0(
        "`parameters$metabolizable_energy_density_kj_kg_dm` must retain ",
        "double storage from the parameter constructor."
      ),
      call. = FALSE
    )
  }

  invisible(NULL)
}

.validate_dry_matter_intake_schedule <- function(schedule) {
  expected_names <- c(
    "hour_of_day",
    "prescribed_dry_matter_intake_kg_dm_h"
  )
  expected_attributes <- list(
    names = expected_names,
    class = "data.frame",
    row.names = seq_len(24L)
  )
  if (
    !identical(typeof(schedule), "list") ||
      !identical(dim(schedule), c(24L, 2L)) ||
      !identical(attributes(schedule), expected_attributes)
  ) {
    stop(
      "`schedule` must be the exact 24-row dry-matter intake data frame.",
      call. = FALSE
    )
  }

  .validate_dry_matter_intake_schedule_fields(
    schedule$hour_of_day,
    schedule$prescribed_dry_matter_intake_kg_dm_h
  )
  if (
    typeof(schedule$prescribed_dry_matter_intake_kg_dm_h) !=
      "double"
  ) {
    stop(
      paste0(
        "`schedule$prescribed_dry_matter_intake_kg_dm_h` must retain ",
        "double storage from the schedule constructor."
      ),
      call. = FALSE
    )
  }

  invisible(NULL)
}
