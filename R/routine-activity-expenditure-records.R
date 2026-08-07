#' Create a prescribed routine-activity expenditure schedule
#'
#' Create the prescribed routine-activity expenditure rate for each of the 24
#' one-hour intervals in a day. Routine activity is incremental to the fixed
#' maintenance expenditure.
#'
#' @param hour_of_day Numeric vector equal to `0:23`, in order.
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
    hour_of_day = as.integer(unclass(hour_of_day)),
    prescribed_routine_activity_expenditure_kj_h =
      as.double(unclass(prescribed_routine_activity_expenditure_kj_h))
  )
}

.validate_routine_activity_expenditure_schedule_fields <- function(
  hour_of_day,
  prescribed_routine_activity_expenditure_kj_h
) {
  if (!.is_hour_of_day_schedule(hour_of_day)) {
    stop(
      "`hour_of_day` must contain the ordered whole numeric values `0:23`.",
      call. = FALSE
    )
  }

  if (
    !.is_semantic_numeric_vector(
      prescribed_routine_activity_expenditure_kj_h
    ) ||
      length(prescribed_routine_activity_expenditure_kj_h) != 24L ||
      any(!is.finite(as.double(unclass(
        prescribed_routine_activity_expenditure_kj_h
      )))) ||
      any(as.double(unclass(
        prescribed_routine_activity_expenditure_kj_h
      )) < 0)
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
  if (
    !is.data.frame(schedule) ||
      nrow(schedule) != 24L ||
      !.has_exact_named_fields(schedule, expected_names)
  ) {
    stop(
      paste0(
        "`routine_activity_schedule` must be a 24-row data frame ",
        "containing only `hour_of_day` and ",
        "`prescribed_routine_activity_expenditure_kj_h`."
      ),
      call. = FALSE
    )
  }

  .validate_routine_activity_expenditure_schedule_fields(
    schedule$hour_of_day,
    schedule$prescribed_routine_activity_expenditure_kj_h
  )

  invisible(NULL)
}

.validate_routine_activity_expenditure_input_row <- function(activity_row) {
  expected_names <- c(
    "hour_of_day",
    "prescribed_routine_activity_expenditure_kj_h"
  )
  if (
    !is.data.frame(activity_row) ||
      nrow(activity_row) != 1L ||
      !.has_exact_named_fields(activity_row, expected_names)
  ) {
    stop(
      paste0(
        "`activity_row` must be a one-row data frame containing only ",
        "`hour_of_day` and ",
        "`prescribed_routine_activity_expenditure_kj_h`."
      ),
      call. = FALSE
    )
  }

  if (
    !.is_hour_of_day_scalar(activity_row$hour_of_day)
  ) {
    stop(
      "`activity_row$hour_of_day` must be one whole numeric value from 0 to 23.",
      call. = FALSE
    )
  }

  .validate_nonnegative_numeric_scalar(
    activity_row$prescribed_routine_activity_expenditure_kj_h,
    "activity_row$prescribed_routine_activity_expenditure_kj_h"
  )

  invisible(NULL)
}
