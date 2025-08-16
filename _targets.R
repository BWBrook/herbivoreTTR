## Targets pipeline definition
##
## This is the entry point for your {targets} workflow.  It sources
## package bootstrap and global options, sets pipeline-wide defaults via
## `tar_option_set()`, defines helper functions, and enumerates the
## targets that constitute your DAG.  Replace the placeholders with
## real logic as your project evolves.

source("R/packages.R"); lib()
source("R/options.R")

tar_option_set(
  packages = character(),         # packages loaded via lib()
  format = "qs",                  # use the fast qs format for local targets
  memory = "transient",
  garbage_collection = TRUE
)

## Helper to read a delimited file quickly.  `vroom` streams data from
## disk and infers column types; disable column type messages via
## options in options.R.
lread <- function(path) vroom::vroom(path, show_col_types = FALSE)

list(
  ## Configuration: read YAML into a list.  Use config::get() to
  ## select profile-specific settings (see config/config.yaml).
  tar_target(cfg, config::get(file = "config/config.yaml")),

  ## Manifest: a CSV enumerating the raw data files.  Each row should
  ## include at least a `path` column pointing to a file under
  ## data/raw/.  Add other columns as needed (id, checksum, etc.).
  tar_target(raw_manifest, "metadata/data_manifest.csv", format = "file"),
  tar_target(raw_files, readr::read_csv(raw_manifest, show_col_types = FALSE)),

  ## Ingest raw CSVs listed in the manifest.  Pattern maps over rows.
  tar_target(raw_tbl, lread(raw_files$path), pattern = map(raw_files), iteration = "list"),

  ## Validate schema early.  Here we check for required columns; replace
  ## with pointblank/validate calls for richer assertions.  Failing
  ## validations should stop the pipeline.
  tar_target(validated, {
    stopifnot(all(c("id","date","value") %in% names(raw_tbl)))
    raw_tbl
  }, pattern = map(raw_tbl), iteration = "list"),

  ## Write each validated table to a Parquet file in data/interim/ and
  ## return the file path.  Downstream tasks can read from these
  ## columnar stores.  Avoid serialising large objects into RDS files.
  tar_target(interim_parquet, {
    dir.create("data/interim", showWarnings = FALSE, recursive = TRUE)
    path <- file.path("data/interim", paste0("data_", tar_group(), ".parquet"))
    arrow::write_parquet(validated, path)
    path
  }, pattern = map(validated), format = "file"),

  ## Placeholder analysis: compute summary statistics or fit models.
  tar_target(model_fit, {
    list(n_rows = sum(vapply(validated, nrow, integer(1))))
  }),

  ## Render the Quarto report after all upstream targets.  The
  ## `tar_quarto()` function caches the output and re-runs only when
  ## inputs change.  Create `reports/paper.qmd` with your analysis.
  tar_quarto(report, path = "reports/paper.qmd")
)