#' Summarise plant-level day changes
#'
#' Compares plant states at the start and end of a day and computes
#' classification flags plus biomass deltas for downstream logging.
#'
#' @param plants_start Data frame of plant state at the start of the day
#'   (before the daily TTR growth update and herbivory).
#' @param plants_end Data frame of plant state at the end of the day
#'   (after herbivory).
#' @param tolerance Numeric tolerance for detecting consumption (kg DM).
#' @return A data frame with start/end columns, deltas, and a `was_eaten`
#'   logical flag for each plant.
summarise_plant_day_states <- function(plants_start, plants_end, tolerance = 1e-6) {
  if (is.null(plants_start) || is.null(plants_end)) {
    rlang::abort("Both start and end plant states must be supplied.",
      class = "herbivoreTTR_forensics_missing_plants"
    )
  }

  keep_cols <- c("plant_id", "veg_type", "xcor", "ycor", "ms", "bleaf", "bstem", "bdef")
  start_df <- plants_start %>%
    dplyr::select(dplyr::all_of(keep_cols)) %>%
    dplyr::rename_with(~ paste0(.x, "_start"), -plant_id)
  end_df <- plants_end %>%
    dplyr::select(dplyr::all_of(keep_cols)) %>%
    dplyr::rename_with(~ paste0(.x, "_end"), -plant_id)

  joined <- dplyr::full_join(start_df, end_df, by = "plant_id")

  joined <- joined %>%
    dplyr::mutate(
      delta_ms    = .data$ms_end    - .data$ms_start,
      delta_bleaf = .data$bleaf_end - .data$bleaf_start,
      delta_bstem = .data$bstem_end - .data$bstem_start,
      delta_bdef  = .data$bdef_end  - .data$bdef_start,
      was_eaten   = delta_ms < (-abs(tolerance))
    )

  joined <- joined %>%
    dplyr::mutate(
      veg_type = dplyr::coalesce(.data$veg_type_start, .data$veg_type_end),
      xcor = dplyr::coalesce(.data$xcor_start, .data$xcor_end),
      ycor = dplyr::coalesce(.data$ycor_start, .data$ycor_end)
    )

  joined
}

#' Convert a daily minute-by-minute record into a data frame
#'
#' @param daily_record List of per-minute entries produced by
#'   `run_daily_herbivore_simulation()`.
#' @return Data frame (one row per minute). Empty data frame when no records
#'   are available.
build_daily_record_table <- function(daily_record) {
  if (length(daily_record) == 0) {
    return(data.frame())
  }
  rows <- lapply(daily_record, function(entry) {
    if (is.null(entry)) return(NULL)
    empty <- vapply(entry, is.null, logical(1))
    entry[empty] <- NA
    data.frame(entry, stringsAsFactors = FALSE)
  })
  rows <- rows[!vapply(rows, is.null, logical(1))]
  if (!length(rows)) {
    return(data.frame())
  }
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}
