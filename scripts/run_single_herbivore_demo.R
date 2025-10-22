#!/usr/bin/env Rscript

message("== HerbivoreTTR single-herbivore demo (3 days) ==")

if (!exists("init_project_options")) {
  for (f in list.files("R", full.names = TRUE)) {
    sys.source(f, envir = globalenv())
  }
  if (!exists("%>%", inherits = TRUE) && requireNamespace("magrittr", quietly = TRUE)) {
    `%>%` <<- magrittr::`%>%`
  }
}

init_project_options()

start_time <- Sys.time()

dir.create(file.path("data", "outputs"), recursive = TRUE, showWarnings = FALSE)

demo <- run_herbivore_days(days = 3L, minute_limit = 1440)
summary_df <- demo$daily_summary

timestamp_label <- format(start_time, "%Y%m%d-%H%M%S")

summary_path <- file.path(
  "data", "outputs",
  sprintf("herbivore_demo_daily_%s.csv", timestamp_label)
)
utils::write.csv(summary_df, summary_path, row.names = FALSE)
message(sprintf("Daily summary written to %s", summary_path))

final_day <- tail(summary_df$day_of_simulation, 1)
plants_path <- file.path(
  "data", "outputs",
  sprintf("herbivore_demo_plants_day%d_%s.csv", final_day, timestamp_label)
)
write_plants_daily(
  plants = demo$plants,
  day = final_day,
  year = 1L,
  path = plants_path
)
message(sprintf("Plant snapshot written to %s", plants_path))

herb_path <- file.path(
  "data", "outputs",
  sprintf("herbivore_demo_herbivore_day%d_%s.csv", final_day, timestamp_label)
)
write_herbivores_daily(
  herbivore = demo$herbivore,
  day = final_day,
  year = 1L,
  path = herb_path
)
message(sprintf("Herbivore snapshot written to %s", herb_path))

elapsed_ms <- round(as.numeric(difftime(Sys.time(), start_time, units = "secs")) * 1000)

log_files <- list.files(
  file.path("data", "outputs"),
  pattern = "^test_log_\\d+\\.csv$",
  full.names = TRUE
)

if (length(log_files) == 0) {
  log_stub <- gsub("[^0-9]", "", format(start_time, "%Y-%m-%dT%H:%M:%S"))
  log_path <- file.path("data", "outputs", sprintf("test_log_%s.csv", log_stub))
  writeLines("timestamp,suite,test_name,status,duration_ms,notes", con = log_path)
} else {
  log_path <- log_files[order(log_files)][length(log_files)]
}

total_intake <- sum(summary_df$total_biomass_eaten)
log_entry <- data.frame(
  timestamp = format(start_time, "%Y-%m-%dT%H:%M:%S"),
  suite = "manual_runs",
  test_name = "single_herbivore_demo_3days",
  status = if (total_intake > 0) "pass" else "warn",
  duration_ms = if (elapsed_ms > 0) as.character(elapsed_ms) else "",
  notes = sprintf("Total biomass eaten %.4f kg DM", total_intake),
  stringsAsFactors = FALSE
)

write.table(
  log_entry,
  file = log_path,
  sep = ",",
  row.names = FALSE,
  col.names = FALSE,
  quote = TRUE,
  append = TRUE
)
message(sprintf("Logged demo run to %s", log_path))

message("== Demo completed ==")
