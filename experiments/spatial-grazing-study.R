# Deterministic factorial and structural controls. No files are written.
# Rscript experiments/spatial-grazing-study.R prints compact summaries.
source("experiments/spatial-grazing-validation.R")

spatial_condition_summary <- function(run) {
  daily <- run$daily[run$daily$complete_day, , drop = FALSE]
  base <- subset(daily, phase == "baseline")
  treatment <- subset(daily, phase == "treatment")
  recovery <- subset(daily, phase == "recovery")
  slope <- function(d, n) {
    if (nrow(d) < n) return(NA_real_)
    d <- tail(d, n)
    unname(coef(lm(body_energy_kj ~ day, data = d))[2])
  }
  h <- run$hourly
  data.frame(completed = is.na(run$stop_day), stop_day = run$stop_day,
    stop_hour = run$stop_hour,
    baseline_end_kj = if (nrow(base)) tail(base$body_energy_kj, 1) else NA_real_,
    baseline_slope_28_kj_day = slope(base, 28),
    treatment_days = nrow(treatment),
    treatment_last_complete_day_energy_kj = if (nrow(treatment)) tail(treatment$body_energy_kj, 1) else NA_real_,
    treatment_slope_28_kj_day = if (nrow(treatment) == 84) slope(treatment, 28) else NA_real_,
    treatment_slope_56_kj_day = if (nrow(treatment) == 84) slope(treatment, 56) else NA_real_,
    recovery_end_difference_kj = if (nrow(recovery) == 60)
      tail(recovery$body_energy_kj, 1) - tail(base$body_energy_kj, 1) else NA_real_,
    min_water_kg = min(h$body_water_kg),
    treatment_intake_kg_dm_day = if (nrow(treatment)) mean(treatment$intake_kg_dm) else NA_real_,
    treatment_water_h_day = if (nrow(treatment)) mean(treatment$water_travel_h) else NA_real_,
    treatment_forage_h_day = if (nrow(treatment)) mean(treatment$forage_travel_h) else NA_real_,
    treatment_water_kj_day = if (nrow(treatment)) mean(treatment$water_expenditure_kj) else NA_real_,
    end_forage_mass_kg_dm = tail(h$forage_mass_kg_dm, 1),
    max_plant_balance_kg_dm = max(abs(h$plant_balance_kg_dm)),
    max_energy_balance_kj = max(abs(h$energy_balance_kj)),
    max_water_balance_kg = max(abs(h$water_balance_kg)))
}

run_spatial_grazing_study <- function(progress = interactive()) {
  validate_spatial_grazing()
  design <- expand.grid(area_ha = c(.08, .04), growth_multiplier = c(1, .6),
    water_duration_h = c(.5, 3), water_cost_kj = c(0, 900))
  design$id <- sprintf("factorial_%02d", seq_len(nrow(design)))
  design$boundary <- "periodic"
  design$grid_side <- 2L
  design$policy <- "local"
  design$heterogeneous <- TRUE
  controls <- data.frame(area_ha = .08, growth_multiplier = .6,
    water_duration_h = 3, water_cost_kj = 900,
    id = c("bounded", "informed", "homogeneous", "subdivide_periodic", "subdivide_bounded"),
    boundary = c("bounded", "periodic", "periodic", "periodic", "bounded"),
    grid_side = c(2L, 2L, 2L, 4L, 4L),
    policy = c("local", "informed", "local", "local", "local"),
    heterogeneous = c(TRUE, TRUE, FALSE, TRUE, TRUE))
  design <- rbind(design, controls)
  runs <- vector("list", nrow(design))
  summaries <- vector("list", nrow(design))
  for (i in seq_len(nrow(design))) {
    d <- design[i, ]
    if (progress) message("Running ", d$id)
    system <- new_spatial_grazing_system(d$area_ha, d$boundary, d$grid_side,
      d$policy, d$heterogeneous)
    runs[[i]] <- run_spatial_grazing(system, d$growth_multiplier,
      d$water_duration_h, d$water_cost_kj)
    summaries[[i]] <- spatial_condition_summary(runs[[i]])
  }
  names(runs) <- design$id
  summary <- cbind(design, do.call(rbind, summaries))
  assert_that(all(summary$max_plant_balance_kg_dm < 1e-9), "all plant balances")
  assert_that(all(summary$max_energy_balance_kj < 1e-8), "all energy balances")
  assert_that(all(summary$max_water_balance_kg < 1e-10), "all water balances")
  # The 2x2 central grid has identical periodic and bounded distances.
  primary <- with(design, area_ha == .08 & growth_multiplier == .6 &
    water_duration_h == 3 & water_cost_kj == 900 & id != "bounded" &
    grid_side == 2 & policy == "local" & heterogeneous)
  assert_that(identical(runs[[which(primary)]]$hourly, runs$bounded$hourly),
    "2x2 boundary geometry null")
  list(design = design, runs = runs, summary = summary)
}

if (sys.nframe() == 0L) {
  result <- run_spatial_grazing_study(progress = TRUE)
  print(result$summary, row.names = FALSE, digits = 5)
}
