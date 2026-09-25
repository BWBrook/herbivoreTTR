# Encounter and policy sensitivity (063).  Sourcing this file writes nothing.
# The experiment is deliberately a thin wrapper around the frozen 062 model.
source("experiments/feeding-access-study.R")

feeding_access_sensitivity_coefficients <- c(.3, .6, 1.5, 3, 5)
feeding_access_sensitivity_layouts <- c("continuous", "clustered", "fragmented")

new_feeding_access_sensitivity_system <- function(configuration, coefficient_m2_h) {
  stopifnot(length(configuration) == 1L,
    configuration %in% feeding_access_sensitivity_layouts,
    length(coefficient_m2_h) == 1L, is.numeric(coefficient_m2_h),
    is.finite(coefficient_m2_h), coefficient_m2_h > 0)
  system <- new_feeding_access_system(configuration)
  system$search_area_m2_h <- coefficient_m2_h
  system
}

feeding_access_sensitivity_design <- function() {
  sustained <- expand.grid(
    coefficient_m2_h = feeding_access_sensitivity_coefficients,
    configuration = feeding_access_sensitivity_layouts,
    water = c("near", "far"),
    policy = c("experienced", "informed"),
    stringsAsFactors = FALSE
  )
  sustained$profile <- "sustained"
  sustained$comparison <- "sustained"

  undisturbed <- expand.grid(
    coefficient_m2_h = feeding_access_sensitivity_coefficients,
    configuration = c("clustered", "fragmented"),
    water = "near",
    policy = c("experienced", "informed", "cyclic"),
    stringsAsFactors = FALSE
  )
  undisturbed$profile <- "none"
  undisturbed$comparison <- "undisturbed"

  design <- rbind(sustained, undisturbed)
  design$access <- "physical"
  design$subdivisions <- 1L
  design$boundary <- "bounded"
  design$role <- ifelse(design$comparison == "undisturbed" &
    design$coefficient_m2_h == .6 & design$policy != "experienced",
    "primary_control", "sensitivity")
  design$baseline_key <- paste(design$coefficient_m2_h, design$configuration, sep = "_")
  design$id <- sprintf("sensitivity_%03d", seq_len(nrow(design)))
  design[c("id", "coefficient_m2_h", "configuration", "profile", "water",
    "policy", "access", "subdivisions", "boundary", "comparison", "role",
    "baseline_key")]
}

feeding_access_sensitivity_period <- function(hourly, first_day, last_day) {
  observed <- hourly[hourly$day >= first_day & hourly$day <= last_day,,drop = FALSE]
  if (!nrow(observed)) {
    return(data.frame(intake_kg_dm = NA_real_, net_production_kg_dm = NA_real_,
      mean_net_production_kg_dm_h = NA_real_, observed_days = 0L,
      observed_hours = 0L))
  }
  net <- observed$plant_growth_kg_dm - observed$plant_senescence_kg_dm
  data.frame(intake_kg_dm = sum(observed$intake_kg_dm),
    net_production_kg_dm = sum(net),
    mean_net_production_kg_dm_h = mean(net),
    observed_days = length(unique(observed$day)),
    observed_hours = nrow(observed))
}

feeding_access_sensitivity_growth_multiplier <- function(profile, n_hours) {
  stopifnot(profile %in% c("none", "sustained"), n_hours >= 0)
  f <- rep(1, n_hours)
  if (profile == "sustained") f[seq_len(min(84L * 24L, n_hours))] <- .6
  f
}

feeding_access_sensitivity_validate_run <- function(run, system, profile) {
  hourly <- run$hourly
  assert_that(max(abs(hourly$plant_balance_kg_dm)) < 1e-9,
    "sensitivity plant closure")
  assert_that(max(abs(hourly$energy_balance_kj)) < 1e-8,
    "sensitivity energy closure")
  assert_that(max(abs(hourly$water_balance_kg)) < 1e-10,
    "sensitivity water closure")
  observed <- hourly[hourly$day >= 61L,,drop = FALSE]
  if (!nrow(observed)) observed <- hourly
  if (nrow(observed)) {
    bound <- feeding_access_supply_bound(system, run$initial_branch_state,
      feeding_access_sensitivity_growth_multiplier(profile, nrow(observed)))
    cumulative_intake <- cumsum(observed$intake_kg_dm)
    assert_that(all(observed$body_energy_kj + observed$gut_energy_kj <=
      bound$combined_energy_upper_kj + 1e-7),
      "sensitivity combined energy bound")
    assert_that(all(cumulative_intake <= bound$harvest_upper_kg_dm + 1e-9) &&
      all(cumulative_intake <= bound$intake_upper_kg_dm + 1e-9),
      "sensitivity cumulative intake bounds")
  }
  invisible(TRUE)
}

feeding_access_sensitivity_summary <- function(run, system, profile) {
  stopifnot(!is.null(run))
  # This calls the existing bound and ledger checks.  It must not be called for
  # a branch whose day-60 baseline exited, because no branch exists then.
  feeding_access_sensitivity_validate_run(run, system, profile)
  checked <- feeding_access_summary(run, system, profile)
  hourly <- run$hourly
  end <- if (nrow(hourly)) hourly[nrow(hourly),,drop = FALSE] else NULL
  forcing <- feeding_access_sensitivity_period(hourly, 61L, 144L)
  recovery <- feeding_access_sensitivity_period(hourly, 145L, 228L)
  complete <- is.na(run$stop_day)
  final_slope <- checked$final_slope_kj_day
  if (!complete) final_slope <- NA_real_
  data.frame(
    branch_evaluable = TRUE,
    baseline_complete = TRUE,
    baseline_exit_day = NA_integer_,
    baseline_exit_hour = NA_integer_,
    completed = complete,
    exit_day = run$stop_day,
    exit_hour = run$stop_hour,
    end_day = if (is.null(end)) NA_integer_ else end$day,
    end_hour = if (is.null(end)) NA_integer_ else end$hour,
    energy_day60_kj = checked$energy_day60_kj,
    energy_end_kj = if (is.null(end)) NA_real_ else end$body_energy_kj,
    accessible_forage_end_kg_dm = if (is.null(end)) NA_real_ else end$accessible_mass_kg_dm,
    min_water_kg = checked$min_water_kg,
    station_count_post60 = length(unique(hourly$station[hourly$day >= 61L &
      hourly$intake_kg_dm > 0])),
    intake_61_144_kg_dm = forcing$intake_kg_dm,
    net_production_61_144_kg_dm = forcing$net_production_kg_dm,
    mean_net_production_61_144_kg_dm_h = forcing$mean_net_production_kg_dm_h,
    observed_days_61_144 = forcing$observed_days,
    observed_hours_61_144 = forcing$observed_hours,
    intake_145_228_kg_dm = recovery$intake_kg_dm,
    net_production_145_228_kg_dm = recovery$net_production_kg_dm,
    mean_net_production_145_228_kg_dm_h = recovery$mean_net_production_kg_dm_h,
    observed_days_145_228 = recovery$observed_days,
    observed_hours_145_228 = recovery$observed_hours,
    final_28d_reserve_slope_kj_day = final_slope,
    max_plant_balance_kg_dm = checked$max_plant_balance_kg_dm,
    max_energy_balance_kj = checked$max_energy_balance_kj,
    max_water_balance_kg = checked$max_water_balance_kg,
    stringsAsFactors = FALSE
  )
}

feeding_access_sensitivity_unevaluable_summary <- function(baseline) {
  data.frame(
    branch_evaluable = FALSE,
    baseline_complete = FALSE,
    baseline_exit_day = baseline$stop_day,
    baseline_exit_hour = baseline$stop_hour,
    completed = NA,
    exit_day = NA_integer_,
    exit_hour = NA_integer_,
    end_day = NA_integer_, end_hour = NA_integer_,
    energy_day60_kj = NA_real_, energy_end_kj = NA_real_,
    accessible_forage_end_kg_dm = NA_real_, min_water_kg = NA_real_,
    station_count_post60 = NA_integer_,
    intake_61_144_kg_dm = NA_real_, net_production_61_144_kg_dm = NA_real_,
    mean_net_production_61_144_kg_dm_h = NA_real_, observed_days_61_144 = 0L,
    observed_hours_61_144 = 0L,
    intake_145_228_kg_dm = NA_real_, net_production_145_228_kg_dm = NA_real_,
    mean_net_production_145_228_kg_dm_h = NA_real_, observed_days_145_228 = 0L,
    observed_hours_145_228 = 0L, final_28d_reserve_slope_kj_day = NA_real_,
    max_plant_balance_kg_dm = NA_real_, max_energy_balance_kj = NA_real_,
    max_water_balance_kg = NA_real_, stringsAsFactors = FALSE
  )
}

assert_feeding_access_sensitivity_reference <- function(result,
  reference_path = "outputs/feeding-access-062/study.rds") {
  stopifnot(file.exists(reference_path))
  reference <- readRDS(reference_path)
  checks <- rbind(
    expand.grid(comparison = "sustained", configuration = feeding_access_sensitivity_layouts,
      water = c("near", "far"), policy = c("experienced", "informed"),
      stringsAsFactors = FALSE),
    expand.grid(comparison = "undisturbed", configuration = c("clustered", "fragmented"),
      water = "near", policy = "experienced", stringsAsFactors = FALSE)
  )
  stopifnot(nrow(checks) == 14L)
  for (k in seq_len(nrow(checks))) {
    configuration <- checks$configuration[[k]]
    water <- checks$water[[k]]
    policy <- checks$policy[[k]]
    comparison <- checks$comparison[[k]]
      i <- which(result$design$coefficient_m2_h == .6 &
        result$design$configuration == configuration &
        result$design$comparison == comparison & result$design$water == water &
        result$design$policy == policy)
      target_profile <- if (comparison == "sustained") "sustained" else "none"
      j <- which(reference$design$configuration == configuration &
        reference$design$profile == target_profile &
        reference$design$water == water & reference$design$policy == policy &
        reference$design$access == "physical" &
        reference$design$subdivisions == 1L & reference$design$boundary == "bounded")
      stopifnot(length(i) == 1L, length(j) == 1L)
      a <- result$runs[[result$design$id[[i]]]]
      b <- reference$runs[[reference$design$id[[j]]]]
      stopifnot(identical(a$stop_day, b$stop_day), identical(a$stop_hour, b$stop_hour),
        identical(a$hourly$station, b$hourly$station),
        identical(a$hourly$body_energy_kj, b$hourly$body_energy_kj))
  }
  invisible(TRUE)
}

feeding_access_sensitivity_ratios <- function() {
  q <- feeding_access_sensitivity_coefficients
  data.frame(coefficient_m2_h = q,
    adequacy_density_kg_dm_ha = 200 + 10000 * .020 / q,
    access_at_baseline_equilibrium = q * (1000 - 200) / 10000 / .020,
    access_at_baseline_production_optimum = q * (500 - 200) / 10000 / .020,
    demand_over_max_landscape_renewal_baseline = .32 / (24 * .08 * .25),
    demand_over_max_landscape_renewal_forced = .32 / (24 * .08 * .016),
    opening_reserve_reference_days = 40000 / 3200,
    opening_reserve_over_baseline_relaxation = (40000 / 3200) * 24 * .001,
    opening_reserve_over_forced_relaxation = (40000 / 3200) * 24 * .0002)
}

run_feeding_access_sensitivity <- function(cores = 1L, progress = interactive(),
  reference_path = "outputs/feeding-access-062/study.rds",
  check_reference = TRUE) {
  stopifnot(length(cores) == 1L, cores == as.integer(cores), cores >= 1L, cores <= 3L)
  validate_feeding_access()
  design <- feeding_access_sensitivity_design()
  baseline_keys <- unique(design$baseline_key)
  systems <- setNames(lapply(seq_along(baseline_keys), function(i) {
    key <- baseline_keys[[i]]
    d <- design[match(key, design$baseline_key),,drop = FALSE]
    new_feeding_access_sensitivity_system(d$configuration, d$coefficient_m2_h)
  }), baseline_keys)
  baselines <- setNames(lapply(names(systems), function(key) {
    if (progress) message("Baseline ", key)
    run_feeding_access(systems[[key]], policy = "experienced", access = "physical",
      final_day = 60L)
  }), names(systems))

  run_one <- function(i) {
    d <- design[i,,drop = FALSE]
    baseline <- baselines[[d$baseline_key]]
    system <- systems[[d$baseline_key]]
    if (!is.na(baseline$stop_day)) {
      return(list(run = NULL, summary = feeding_access_sensitivity_unevaluable_summary(baseline)))
    }
    if (progress) message("Branch ", d$id, " ", d$configuration, " ", d$profile,
      " ", d$water, " ", d$policy, " c=", d$coefficient_m2_h)
    run <- run_feeding_access(system, profile = d$profile, water = d$water,
      policy = d$policy, access = d$access, final_day = 228L, baseline = baseline)
    stopifnot(identical(run$initial_branch_state, baseline$final_state),
      identical(run$hourly[run$hourly$day <= 60L,,drop = FALSE], baseline$hourly))
    list(run = run, summary = feeding_access_sensitivity_summary(run, system, d$profile))
  }
  results <- parallel::mclapply(seq_len(nrow(design)), run_one,
    mc.cores = cores, mc.preschedule = FALSE)
  if (any(vapply(results, inherits, logical(1), "try-error"))) stop("A sensitivity worker failed.")
  runs <- setNames(lapply(results, `[[`, "run"), design$id)
  summary <- cbind(design, do.call(rbind, lapply(results, `[[`, "summary")))
  baseline_summary <- do.call(rbind, lapply(names(baselines), function(key) {
    b <- baselines[[key]]
    system <- systems[[key]]
    feeding_access_sensitivity_validate_run(b, system, "none")
    data.frame(baseline_key = key, baseline_complete = is.na(b$stop_day),
      baseline_exit_day = b$stop_day, baseline_exit_hour = b$stop_hour,
      max_plant_balance_kg_dm = max(abs(b$hourly$plant_balance_kg_dm)),
      max_energy_balance_kj = max(abs(b$hourly$energy_balance_kj)),
      max_water_balance_kg = max(abs(b$hourly$water_balance_kg)))
  }))
  if (check_reference) assert_feeding_access_sensitivity_reference(
    list(design = design, runs = runs), reference_path)
  analytic <- feeding_access_sensitivity_ratios()
  list(design = design, systems = systems, baselines = baselines, runs = runs,
    summary = summary, baseline_summary = baseline_summary, analytic = analytic,
    reference_checked = isTRUE(check_reference),
    provenance = list(generated_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
      R = R.version.string))
}

write_feeding_access_sensitivity_outputs <- function(result, output_dir,
  figure_path = NULL) {
  stopifnot(is.list(result), length(output_dir) == 1L, nzchar(output_dir))
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  saveRDS(result, file.path(output_dir, "sensitivity.rds"))
  utils::write.csv(result$summary, file.path(output_dir, "summary.csv"), row.names = FALSE)
  utils::write.csv(result$baseline_summary, file.path(output_dir, "baseline-summary.csv"), row.names = FALSE)
  utils::write.csv(result$analytic, file.path(output_dir, "analytic.csv"), row.names = FALSE)
  log_path <- file.path(output_dir, "run.log")
  source_files <- c("experiments/feeding-access-sensitivity.R",
    "experiments/feeding-access-fixtures.R", "experiments/feeding-access-policy.R",
    "experiments/feeding-access-study.R")
  lines <- c("Feeding-access sensitivity 063 provenance", capture.output(result$provenance),
    capture.output(sessionInfo()), "Source MD5:",
    paste(source_files, unname(tools::md5sum(source_files)), sep = "  "))
  writeLines(lines, log_path)
  if (!is.null(figure_path)) {
    source("experiments/feeding-access-sensitivity-figures.R")
    plot_feeding_access_sensitivity(result, figure_path)
  }
  invisible(output_dir)
}

if (sys.nframe() == 0L) {
  result <- run_feeding_access_sensitivity(cores = 1L, progress = TRUE)
  print(result$summary, row.names = FALSE, digits = 5)
}
