# Run from the project root. Sourcing and direct execution write no files.
source("experiments/red-kangaroo-budget.R")
source("experiments/red-kangaroo-short.R")
source("experiments/red-kangaroo-validation.R")
source("experiments/red-kangaroo-figures.R")

run_red_kangaroo_benchmark <- function() {
  budget <- run_red_kangaroo_budget()
  short <- run_short_kangaroo_benchmark()
  checks <- validate_red_kangaroo_benchmark(budget, short)
  list(budget = budget, short = short, checks = checks)
}

write_red_kangaroo_benchmark_outputs <- function(result, directory) {
  if (!is.character(directory) || length(directory) != 1L ||
      is.na(directory) || !nzchar(directory)) {
    stop("Supply one explicit output directory.", call. = FALSE)
  }
  dir.create(directory, recursive = TRUE, showWarnings = FALSE)
  saveRDS(result, file.path(directory, "benchmark.rds"))
  for (part in c("budget", "short")) {
    for (name in names(result[[part]])) {
      if (is.data.frame(result[[part]][[name]])) write.csv(result[[part]][[name]],
        file.path(directory, paste0(part, "-", name, ".csv")), row.names = FALSE)
    }
  }
  write.csv(result$checks, file.path(directory, "accounting-checks.csv"), row.names = FALSE)
  write_red_kangaroo_benchmark_pdf(result$budget, result$short,
    file.path(directory, "red-kangaroo-benchmark.pdf"))
  invisible(directory)
}

if (sys.nframe() == 0L) {
  result <- run_red_kangaroo_benchmark()
  print(result$budget$energy[, c("energy_case", "derived_intake_kg_dm_day",
    "implied_food_water_kg_day_at_synthetic_yield")], row.names = FALSE)
  print(subset(result$short$rmse, scenario_id == "S1.0_R0_phi0.0" &
    x_pairing == "midpoint" & j_offset_kg_dm_ha == 0), row.names = FALSE)
  print(result$checks, row.names = FALSE)
}
