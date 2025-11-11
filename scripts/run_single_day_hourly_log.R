#!/usr/bin/env Rscript

message("== HerbivoreTTR hourly log demo (1 day) ==")

if (!exists("init_project_options")) {
  for (f in list.files("R", full.names = TRUE)) {
    sys.source(f, envir = globalenv())
  }
  if (!exists("%>%", inherits = TRUE) && requireNamespace("magrittr", quietly = TRUE)) {
    `%>%` <<- magrittr::`%>%`
  }
}

init_project_options()

sim <- init_simulation()
conditions <- sim[["conditions"]]
plants <- sim[["plants"]]
herbivore <- sim[["herbivore"]]

start_day <- CONSTANTS$SPIN_UP_LENGTH * nrow(conditions) + 1L

message(sprintf("Running day %d after spin-up", start_day))
res <- run_daily_herbivore_simulation(
  herbivore = herbivore,
  plants = plants,
  conditions = conditions,
  day_of_simulation = start_day,
  minute_limit = 1440L
)

log_path <- write_hourly_herbivore_log(
  daily_record = res$daily_record,
  day_of_simulation = res$daily_summary$day_of_simulation
)

message(sprintf("Hourly log written to %s", log_path))
message("== Hourly log demo completed ==")
