#!/usr/bin/env Rscript

# Forensic logging of a single herbivore day. Captures per-minute activity,
# plant start/end states, herbivore start/end states, summary stats, and a
# diagnostic map for visual inspection.

message("== HerbivoreTTR single-day forensic logger ==")

if (!exists("init_project_options")) {
  for (f in list.files("R", full.names = TRUE)) {
    sys.source(f, envir = globalenv())
  }
  if (!exists("%>%", inherits = TRUE) && requireNamespace("magrittr", quietly = TRUE)) {
    `%>%` <<- magrittr::`%>%`
  }
}

`%||%` <- function(x, y) {
  if (is.null(x) || (is.atomic(x) && length(x) == 0)) y else x
}

init_project_options()

run_timestamp <- Sys.time()
run_label <- format(run_timestamp, "%Y%m%d-%H%M%S")
output_dir <- file.path("data", "outputs", "day", paste0("forensic_day_", run_label))
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
message(sprintf("Output directory: %s", output_dir))

sim <- init_simulation()
conditions <- sim[["conditions"]]
plants <- sim[["plants"]]
herbivore <- sim[["herbivore"]]

start_day <- CONSTANTS$SPIN_UP_LENGTH * nrow(conditions) + 1L
message(sprintf("Running diagnostics for day %d", start_day))

res <- run_daily_herbivore_simulation(
  herbivore = herbivore,
  plants = plants,
  conditions = conditions,
  day_of_simulation = start_day,
  minute_limit = 1440L,
  capture_diagnostics = TRUE
)

diag <- res$diagnostics
if (is.null(diag)) {
  stop("Diagnostics were not captured; please rerun with capture_diagnostics = TRUE")
}

# Helper to write CSVs with consistent options
write_csv <- function(df, path) {
  utils::write.csv(df, path, row.names = FALSE)
  path
}

# Convert daily record to a tidy table
minute_log <- build_daily_record_table(res$daily_record)
minute_log_path <- file.path(output_dir, "herbivore_minute_log.csv")
write_csv(minute_log, minute_log_path)
message(sprintf("Per-minute log: %s", minute_log_path))

# Summarise plant-level changes
plant_changes <- summarise_plant_day_states(
  plants_start = diag$plants_start,
  plants_end = diag$plants_end,
  tolerance = 1e-6
)

plant_changes_path <- file.path(output_dir, "plants_all_changes.csv")
write_csv(plant_changes, plant_changes_path)

make_state_table <- function(df, eaten_flag, which_end = c("start", "end")) {
  which_end <- match.arg(which_end)
  prefix <- if (which_end == "start") "_start" else "_end"
  cols <- c(
    "plant_id",
    "veg_type",
    "xcor",
    "ycor",
    paste0("ms", prefix),
    paste0("bleaf", prefix),
    paste0("bstem", prefix),
    paste0("bdef", prefix)
  )
  out <- df[df$was_eaten == eaten_flag, cols, drop = FALSE]
  names(out) <- c("plant_id", "veg_type", "xcor", "ycor", "ms", "bleaf", "bstem", "bdef")
  out
}

eaten_start <- make_state_table(plant_changes, TRUE, "start")
eaten_end   <- make_state_table(plant_changes, TRUE, "end")
uneaten_start <- make_state_table(plant_changes, FALSE, "start")
uneaten_end   <- make_state_table(plant_changes, FALSE, "end")

write_csv(eaten_start, file.path(output_dir, "plants_eaten_start.csv"))
write_csv(eaten_end,   file.path(output_dir, "plants_eaten_end.csv"))
write_csv(uneaten_start, file.path(output_dir, "plants_uneaten_start.csv"))
write_csv(uneaten_end,   file.path(output_dir, "plants_uneaten_end.csv"))

herbivore_snapshot <- function(h, label) {
  data.frame(
    state = label,
    mass = h$mass,
    xcor = h$xcor,
    ycor = h$ycor,
    gut_content = h$gut_content,
    gut_capacity = h$gut_capacity,
    bite_size = h$bite_size,
    handling_time = h$handling_time,
    fv_max = h$fv_max,
    distance_moved = `%||%`(h$distance_moved, NA_real_),
    intake_total_day = `%||%`(h$intake_total_day, NA_real_),
    intake_PE_day = `%||%`(h$intake_PE_day, NA_real_),
    intake_NPE_day = `%||%`(h$intake_NPE_day, NA_real_),
    energy_balance = `%||%`(h$energy_balance, NA_real_),
    water_balance = `%||%`(h$water_balance, NA_real_),
    daily_water_requirement = `%||%`(h$daily_water_requirement, NA_real_),
    behaviour = `%||%`(h$behaviour, NA_character_),
    selected_plant_id = `%||%`(h$selected_plant_id, NA_integer_),
    stringsAsFactors = FALSE
  )
}

herb_snapshots <- rbind(
  herbivore_snapshot(diag$herbivore_start, "start"),
  herbivore_snapshot(res$herbivore, "end")
)
herb_path <- file.path(output_dir, "herbivore_states.csv")
write_csv(herb_snapshots, herb_path)
saveRDS(diag$herbivore_start, file.path(output_dir, "herbivore_start.rds"))
saveRDS(res$herbivore, file.path(output_dir, "herbivore_end.rds"))

# Summary stats
n_eaten <- sum(plant_changes$was_eaten, na.rm = TRUE)
total_plants <- nrow(plant_changes)
consumed_mass <- sum(pmax(-plant_changes$delta_ms, 0), na.rm = TRUE)
uneaten_growth <- plant_changes$delta_ms[!plant_changes$was_eaten]
summary_stats <- data.frame(
  metric = c(
    "timestamp",
    "day_of_simulation",
    "minutes_recorded",
    "total_plants",
    "plants_eaten",
    "plants_uneaten",
    "total_biomass_eaten_kg",
    "total_distance_moved_m",
    "avg_growth_uneaten_kg",
    "total_growth_uneaten_kg",
    "energy_balance_end_kJ",
    "water_balance_end_kg"
  ),
  value = c(
    format(run_timestamp, "%Y-%m-%d %H:%M:%S"),
    diag$day_of_simulation,
    nrow(minute_log),
    total_plants,
    n_eaten,
    total_plants - n_eaten,
    round(consumed_mass, 6),
    round(`%||%`(res$herbivore$distance_moved, 0), 3),
    if (length(uneaten_growth)) round(mean(uneaten_growth), 6) else NA,
    if (length(uneaten_growth)) round(sum(uneaten_growth), 6) else NA,
    res$herbivore$energy_balance,
    res$herbivore$water_balance
  ),
  stringsAsFactors = FALSE
)
write_csv(summary_stats, file.path(output_dir, "summary_stats.csv"))

# Diagnostic plot
plot_width <- sqrt(CONSTANTS$PLOT_SIZE)
plot_height <- sqrt(CONSTANTS$PLOT_SIZE)
plant_cols <- ifelse(plant_changes$was_eaten, "forestgreen", "firebrick3")
plant_cols[is.na(plant_cols)] <- "grey70"

hourly_log <- minute_log[minute_log$minute %% 60 == 0, , drop = FALSE]
if (nrow(hourly_log) == 0) hourly_log <- minute_log

png(file.path(output_dir, "plant_map.png"), width = 1200, height = 1000, res = 150)
par(mar = c(5, 5, 4, 2))
plot(
  plant_changes$xcor, plant_changes$ycor,
  col = plant_cols,
  pch = 19,
  cex = 0.6,
  xlim = c(0, plot_width),
  ylim = c(0, plot_height),
  xlab = "x (m)",
  ylab = "y (m)",
  main = sprintf("Day %d plant map", diag$day_of_simulation)
)

if (nrow(hourly_log) > 0) {
  lines(hourly_log$xcor, hourly_log$ycor, col = "steelblue3", lwd = 1.2)
  points(hourly_log$xcor, hourly_log$ycor, pch = 21, bg = "steelblue3", col = "black")
  text(hourly_log$xcor, hourly_log$ycor, labels = round(hourly_log$minute / 60, 1), cex = 0.6, pos = 3)
}

points(diag$herbivore_start$xcor, diag$herbivore_start$ycor, pch = 4, col = "black", lwd = 2)
points(res$herbivore$xcor, res$herbivore$ycor, pch = 8, col = "black", lwd = 2)
legend(
  "topright",
  legend = c("Eaten", "Uneaten", "Herbivore path", "Start", "End"),
  col = c("forestgreen", "firebrick3", "steelblue3", "black", "black"),
  pch = c(19, 19, NA, 4, 8),
  lty = c(NA, NA, 1, NA, NA),
  pt.bg = c(NA, NA, "steelblue3", NA, NA),
  bty = "n"
)

dev.off()

message("== Forensic logging complete ==")
message(sprintf("Files written under: %s", output_dir))
