#' Summarise minute-level herbivore records to hourly metrics
#'
#' Aggregates the per-minute `daily_record` emitted by
#' `run_daily_herbivore_simulation()` into hourly statistics. Numeric state
#' variables are averaged, while cumulative quantities are differenced to
#' recover per-hour totals alongside their cumulative values.
#'
#' @param daily_record List of per-minute records (see
#'   `run_daily_herbivore_simulation()`).
#' @param day_of_simulation Integer day index associated with the record.
#' @param minutes_per_hour Integer number of minutes grouped into each hour
#'   (defaults to 60 to match the simulation step).
#' @return A data.frame with one row per hour, including day metadata, hourly
#'   means, and cumulative & per-hour totals for key herbivore attributes.
#' @examples
#' \dontrun{
#' sim <- init_simulation()
#' res <- run_daily_herbivore_simulation(sim$herbivore, sim$plants, sim$conditions)
#' hourly <- summarise_hourly_herbivore_record(res$daily_record, res$daily_summary$day_of_simulation)
#' }
#' @export
summarise_hourly_herbivore_record <- function(daily_record,
                                              day_of_simulation,
                                              minutes_per_hour = 60L) {
  if (is.null(daily_record) || length(daily_record) == 0L) {
    return(data.frame())
  }
  valid_idx <- !vapply(daily_record, is.null, logical(1L))
  if (!any(valid_idx)) {
    return(data.frame())
  }
  record_df <- do.call(
    rbind,
    lapply(daily_record[valid_idx], function(entry) {
      entry$selected_plant_id <- ifelse(is.null(entry$selected_plant_id), NA_integer_, entry$selected_plant_id)
      entry$behaviour <- ifelse(is.null(entry$behaviour), NA_character_, entry$behaviour)
      data.frame(entry, stringsAsFactors = FALSE)
    })
  )
  record_df$hour <- ((record_df$minute - 1L) %/% minutes_per_hour) + 1L

  hour_ids <- sort(unique(record_df$hour))
  cumulative_fields <- c(
    "distance_moved",
    "intake_total_day",
    "intake_pe_day",
    "intake_npe_day",
    "intake_water_forage",
    "intake_water_drink"
  )
  mean_fields <- c("xcor", "ycor", "gut_content", "energy_balance", "water_balance")

  prev_cumulative <- as.list(setNames(rep(0, length(cumulative_fields)), cumulative_fields))

  hourly_rows <- lapply(hour_ids, function(h) {
    slice <- record_df[record_df$hour == h, , drop = FALSE]
    if (nrow(slice) == 0L) return(NULL)
    hour_means <- vapply(mean_fields, function(col) mean(slice[[col]], na.rm = TRUE), numeric(1L))

    hourly_totals <- vapply(cumulative_fields, function(col) {
      latest <- tail(slice[[col]], 1)
      latest <- ifelse(is.finite(latest), latest, prev_cumulative[[col]])
      total <- latest - prev_cumulative[[col]]
      prev_cumulative[[col]] <<- latest
      total
    }, numeric(1L))

    cumulative_latest <- vapply(cumulative_fields, function(col) prev_cumulative[[col]], numeric(1L))

    last_behaviour <- tail(stats::na.omit(slice$behaviour), 1)
    last_behaviour <- ifelse(length(last_behaviour), last_behaviour, NA_character_)
    last_plant <- tail(stats::na.omit(slice$selected_plant_id), 1)
    last_plant <- ifelse(length(last_plant), last_plant, NA_integer_)

    data.frame(
      day_of_simulation = day_of_simulation,
      hour = h,
      minute_start = (h - 1L) * minutes_per_hour + 1L,
      minute_end = min(h * minutes_per_hour, max(record_df$minute, na.rm = TRUE)),
      xcor_mean = hour_means[["xcor"]],
      ycor_mean = hour_means[["ycor"]],
      gut_content_mean = hour_means[["gut_content"]],
      energy_balance_mean = hour_means[["energy_balance"]],
      water_balance_mean = hour_means[["water_balance"]],
      selected_plant_id_last = last_plant,
      behaviour_last = last_behaviour,
      distance_moved_hour = hourly_totals[["distance_moved"]],
      distance_moved_cumulative = cumulative_latest[["distance_moved"]],
      intake_total_hour = hourly_totals[["intake_total_day"]],
      intake_total_cumulative = cumulative_latest[["intake_total_day"]],
      intake_pe_hour = hourly_totals[["intake_pe_day"]],
      intake_pe_cumulative = cumulative_latest[["intake_pe_day"]],
      intake_npe_hour = hourly_totals[["intake_npe_day"]],
      intake_npe_cumulative = cumulative_latest[["intake_npe_day"]],
      intake_water_forage_hour = hourly_totals[["intake_water_forage"]],
      intake_water_forage_cumulative = cumulative_latest[["intake_water_forage"]],
      intake_water_drink_hour = hourly_totals[["intake_water_drink"]],
      intake_water_drink_cumulative = cumulative_latest[["intake_water_drink"]],
      stringsAsFactors = FALSE
    )
  })
  hourly_rows <- hourly_rows[!vapply(hourly_rows, is.null, logical(1L))]
  if (!length(hourly_rows)) {
    return(data.frame())
  }
  do.call(rbind, hourly_rows)
}

#' Write hourly herbivore metrics to CSV
#'
#' Convenience wrapper around `summarise_hourly_herbivore_record()` that takes
#' the daily simulation output, summarises it, and writes a CSV log.
#'
#' @param daily_record Minute-level list from `run_daily_herbivore_simulation()`.
#' @param day_of_simulation Integer day index.
#' @param base_dir Output directory (default `data/outputs`).
#' @param prefix File name prefix (default `"herbivore_hourly"`).
#' @return Invisibly returns the file path written.
#' @examples
#' \dontrun{
#' res <- run_daily_herbivore_simulation(...)
#' write_hourly_herbivore_log(res$daily_record, res$daily_summary$day_of_simulation)
#' }
#' @export
write_hourly_herbivore_log <- function(daily_record,
                                       day_of_simulation,
                                       base_dir = "data/outputs",
                                       prefix = "herbivore_hourly") {
  hourly_df <- summarise_hourly_herbivore_record(
    daily_record = daily_record,
    day_of_simulation = day_of_simulation
  )
  if (nrow(hourly_df) == 0L) {
    rlang::abort(
      "No minute-level records were available to summarise.",
      class = "herbivoreTTR_hourly_no_records"
    )
  }
  if (!dir.exists(base_dir)) {
    dir_ok <- dir.create(base_dir, recursive = TRUE, showWarnings = FALSE)
    if (!dir_ok) {
      rlang::abort(
        "Unable to create output directory for hourly log.",
        class = "herbivoreTTR_hourly_dir_create",
        output_dir = base_dir
      )
    }
  }
  timestamp_label <- format(Sys.time(), "%Y%m%d-%H%M%S")
  file_path <- file.path(
    base_dir,
    sprintf(
      "%s_day%d_%s.csv",
      prefix,
      as.integer(day_of_simulation),
      timestamp_label
    )
  )
  utils::write.csv(hourly_df, file = file_path, row.names = FALSE)
  invisible(file_path)
}
