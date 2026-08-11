#' Create a forage-acquisition ceiling schedule
#'
#' Create the maximum dry-matter acquisition rate supplied by an external,
#' non-depleting forage environment for each of the 24 one-hour intervals in a
#' day. The ceiling is a rate, not a forage stock.
#'
#' @param hour_of_day Numeric vector equal to `0:23`, in order.
#' @param forage_acquisition_ceiling_kg_dm_h Finite, non-negative numeric
#'   vector of 24 acquisition ceilings in kilograms dry matter per hour.
#'
#' @return A base data frame with 24 rows and the columns `hour_of_day` and
#'   `forage_acquisition_ceiling_kg_dm_h`.
#' @export
new_forage_acquisition_ceiling_schedule <- function(
  hour_of_day,
  forage_acquisition_ceiling_kg_dm_h
) {
  .validate_forage_acquisition_ceiling_schedule_fields(
    hour_of_day,
    forage_acquisition_ceiling_kg_dm_h
  )

  data.frame(
    hour_of_day = as.integer(hour_of_day),
    forage_acquisition_ceiling_kg_dm_h =
      as.double(forage_acquisition_ceiling_kg_dm_h)
  )
}

.validate_forage_acquisition_ceiling_schedule_fields <- function(
  hour_of_day,
  forage_acquisition_ceiling_kg_dm_h
) {
  if (!.is_hour_of_day_schedule(hour_of_day)) {
    stop(
      "`hour_of_day` must contain the ordered whole numeric values `0:23`.",
      call. = FALSE
    )
  }

  if (
    !.is_numeric_vector(forage_acquisition_ceiling_kg_dm_h) ||
      length(forage_acquisition_ceiling_kg_dm_h) != 24L ||
      any(!is.finite(as.double(forage_acquisition_ceiling_kg_dm_h))) ||
      any(as.double(forage_acquisition_ceiling_kg_dm_h) < 0)
  ) {
    stop(
      paste0(
        "`forage_acquisition_ceiling_kg_dm_h` must contain 24 finite, ",
        "non-negative numeric values."
      ),
      call. = FALSE
    )
  }

  invisible(NULL)
}

.validate_forage_acquisition_ceiling_schedule <- function(schedule) {
  expected_names <- c(
    "hour_of_day",
    "forage_acquisition_ceiling_kg_dm_h"
  )
  if (
    !is.data.frame(schedule) ||
      nrow(schedule) != 24L ||
      !.has_exact_named_fields(schedule, expected_names)
  ) {
    stop(
      paste0(
        "`forage_acquisition_ceiling_schedule` must be a 24-row data ",
        "frame containing only `hour_of_day` and ",
        "`forage_acquisition_ceiling_kg_dm_h`."
      ),
      call. = FALSE
    )
  }

  .validate_forage_acquisition_ceiling_schedule_fields(
    schedule$hour_of_day,
    schedule$forage_acquisition_ceiling_kg_dm_h
  )

  invisible(NULL)
}
