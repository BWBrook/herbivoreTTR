#' Create a prescribed routine-activity expenditure schedule
#'
#' Create the prescribed routine-activity expenditure rate for each of the 24
#' one-hour intervals in a day. Routine activity is incremental to the fixed
#' maintenance expenditure.
#'
#' @param hour_of_day Integer vector equal to `0:23`, in order.
#' @param prescribed_routine_activity_expenditure_kj_h Finite, non-negative
#'   numeric vector of 24 prescribed routine-activity expenditure rates in
#'   kilojoules per hour.
#'
#' @return A base data frame with 24 rows and the columns `hour_of_day` and
#'   `prescribed_routine_activity_expenditure_kj_h`.
#' @export
new_routine_activity_expenditure_schedule <- function(
  hour_of_day,
  prescribed_routine_activity_expenditure_kj_h
) {
  .validate_routine_activity_expenditure_schedule_fields(
    hour_of_day,
    prescribed_routine_activity_expenditure_kj_h
  )

  data.frame(
    hour_of_day = hour_of_day,
    prescribed_routine_activity_expenditure_kj_h =
      as.double(prescribed_routine_activity_expenditure_kj_h)
  )
}

.validate_routine_activity_expenditure_schedule_fields <- function(
  hour_of_day,
  prescribed_routine_activity_expenditure_kj_h
) {
  if (!is.integer(hour_of_day) || !identical(hour_of_day, 0:23)) {
    stop("`hour_of_day` must be integer `0:23`, in order.", call. = FALSE)
  }

  if (
    !.is_bare_numeric_vector(
      prescribed_routine_activity_expenditure_kj_h
    ) ||
      length(prescribed_routine_activity_expenditure_kj_h) != 24L ||
      any(!is.finite(prescribed_routine_activity_expenditure_kj_h)) ||
      any(prescribed_routine_activity_expenditure_kj_h < 0)
  ) {
    stop(
      paste0(
        "`prescribed_routine_activity_expenditure_kj_h` must contain 24 ",
        "finite, non-negative numeric values."
      ),
      call. = FALSE
    )
  }

  invisible(NULL)
}

.validate_routine_activity_expenditure_schedule <- function(schedule) {
  expected_names <- c(
    "hour_of_day",
    "prescribed_routine_activity_expenditure_kj_h"
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
      paste0(
        "`routine_activity_schedule` must be the exact 24-row ",
        "routine-activity expenditure data frame."
      ),
      call. = FALSE
    )
  }

  .validate_routine_activity_expenditure_schedule_fields(
    schedule$hour_of_day,
    schedule$prescribed_routine_activity_expenditure_kj_h
  )
  if (
    typeof(schedule$prescribed_routine_activity_expenditure_kj_h) !=
      "double"
  ) {
    stop(
      paste0(
        "`routine_activity_schedule$",
        "prescribed_routine_activity_expenditure_kj_h` must retain double ",
        "storage from the schedule constructor."
      ),
      call. = FALSE
    )
  }

  invisible(NULL)
}

.validate_routine_activity_expenditure_input_row <- function(activity_row) {
  expected_names <- c(
    "hour_of_day",
    "prescribed_routine_activity_expenditure_kj_h"
  )
  if (
    !identical(class(activity_row), "data.frame") ||
      !identical(dim(activity_row), c(1L, 2L)) ||
      !identical(names(activity_row), expected_names) ||
      !identical(
        names(attributes(activity_row)),
        c("names", "row.names", "class")
      )
  ) {
    stop(
      paste0(
        "`activity_row` must be exactly one row from a routine-activity ",
        "expenditure schedule."
      ),
      call. = FALSE
    )
  }

  if (
    typeof(activity_row$hour_of_day) != "integer" ||
      !is.null(attributes(activity_row$hour_of_day)) ||
      is.na(activity_row$hour_of_day) ||
      activity_row$hour_of_day < 0L ||
      activity_row$hour_of_day > 23L
  ) {
    stop(
      "`activity_row$hour_of_day` must be an integer from 0 to 23.",
      call. = FALSE
    )
  }

  .validate_nonnegative_numeric_scalar(
    activity_row$prescribed_routine_activity_expenditure_kj_h,
    "activity_row$prescribed_routine_activity_expenditure_kj_h"
  )
  if (
    typeof(activity_row$prescribed_routine_activity_expenditure_kj_h) !=
      "double"
  ) {
    stop(
      paste0(
        "`activity_row$prescribed_routine_activity_expenditure_kj_h` must ",
        "retain double storage from the schedule constructor."
      ),
      call. = FALSE
    )
  }

  invisible(NULL)
}
