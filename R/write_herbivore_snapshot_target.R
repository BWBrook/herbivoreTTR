#' Write a herbivore snapshot CSV for the targets pipeline
#'
#' Wraps `write_herbivores_daily()` with directory management so `_targets.R`
#' remains clean of inline side-effects.
#'
#' @param herbivore Herbivore state list.
#' @param day Integer day index.
#' @param base_dir Output directory; defaults to `data/outputs`.
#' @param year Simulation year (default 1).
#' @return The file path that was written.
#' @noRd
write_herbivore_snapshot_target <- function(herbivore,
                                            day,
                                            base_dir = "data/outputs",
                                            year = 1L) {
  if (!dir.exists(base_dir)) {
    created <- dir.create(base_dir, recursive = TRUE, showWarnings = FALSE)
    if (!created) {
      rlang::abort(
        "Failed to create herbivore output directory",
        class = "herbivoreTTR_herb_output_dir_create",
        output_dir = base_dir
      )
    }
  }

  path <- file.path(base_dir, sprintf("herb_day%03d.csv", as.integer(day)))
  write_herbivores_daily(herbivore = herbivore, day = day, year = year, path = path) # nolint: object_usage_linter
  path
}
