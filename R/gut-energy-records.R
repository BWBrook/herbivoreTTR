#' Create a gut-energy state
#'
#' Create the dynamic state record for the one-pool gut-energy buffer.
#'
#' @param gut_available_energy_kj Finite, non-negative numeric scalar giving
#'   assimilable energy available in the gut in kilojoules.
#'
#' @return A plain named list containing `gut_available_energy_kj`.
#' @export
new_gut_energy_state <- function(gut_available_energy_kj) {
  .validate_nonnegative_numeric_scalar(
    gut_available_energy_kj,
    "gut_available_energy_kj"
  )

  list(
    gut_available_energy_kj = as.double(unclass(gut_available_energy_kj))
  )
}

#' Create gut-energy parameters
#'
#' Create the fixed parameter record for the one-pool gut-energy buffer.
#'
#' @param gut_release_fraction_h Finite numeric scalar in `(0, 1]` giving the
#'   fraction of opening gut energy released per hour.
#'
#' @return A plain named list containing `gut_release_fraction_h`.
#' @export
new_gut_energy_parameters <- function(gut_release_fraction_h) {
  .validate_gut_release_fraction(gut_release_fraction_h)

  list(
    gut_release_fraction_h = as.double(unclass(gut_release_fraction_h))
  )
}

#' Create a prescribed ingested available-energy schedule
#'
#' Create the prescribed available-energy input to the gut for each of the 24
#' one-hour intervals in a day.
#'
#' @param hour_of_day Numeric vector equal to `0:23`, in order.
#' @param prescribed_ingested_available_energy_kj_h Finite, non-negative
#'   numeric vector of 24 prescribed available-energy ingestion rates in
#'   kilojoules per hour.
#'
#' @return A base data frame with 24 rows and the columns `hour_of_day` and
#'   `prescribed_ingested_available_energy_kj_h`.
#' @export
new_ingested_available_energy_schedule <- function(
  hour_of_day,
  prescribed_ingested_available_energy_kj_h
) {
  .validate_ingested_available_energy_schedule_fields(
    hour_of_day,
    prescribed_ingested_available_energy_kj_h
  )

  data.frame(
    hour_of_day = as.integer(unclass(hour_of_day)),
    prescribed_ingested_available_energy_kj_h =
      as.double(unclass(prescribed_ingested_available_energy_kj_h))
  )
}

.validate_gut_release_fraction <- function(value) {
  if (
    !.is_semantic_numeric_vector(value) ||
      length(value) != 1L ||
      !is.finite(as.double(unclass(value))) ||
      as.double(unclass(value)) <= 0 ||
      as.double(unclass(value)) > 1
  ) {
    stop(
      "`gut_release_fraction_h` must be one finite numeric value in (0, 1].",
      call. = FALSE
    )
  }

  invisible(NULL)
}

.validate_ingested_available_energy_schedule_fields <- function(
  hour_of_day,
  prescribed_ingested_available_energy_kj_h
) {
  if (!.is_hour_of_day_schedule(hour_of_day)) {
    stop(
      "`hour_of_day` must contain the ordered whole numeric values `0:23`.",
      call. = FALSE
    )
  }

  if (
    !.is_semantic_numeric_vector(
      prescribed_ingested_available_energy_kj_h
    ) ||
      length(prescribed_ingested_available_energy_kj_h) != 24L ||
      any(!is.finite(as.double(unclass(
        prescribed_ingested_available_energy_kj_h
      )))) ||
      any(as.double(unclass(
        prescribed_ingested_available_energy_kj_h
      )) < 0)
  ) {
    stop(
      paste0(
        "`prescribed_ingested_available_energy_kj_h` must contain 24 finite, ",
        "non-negative numeric values."
      ),
      call. = FALSE
    )
  }

  invisible(NULL)
}
