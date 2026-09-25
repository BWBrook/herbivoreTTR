# Bounded plant-matched return-expectation repair (064); sourcing is no-write.
source("experiments/feeding-access-sensitivity.R")
source("experiments/feeding-access-recovery-validation.R")

feeding_access_recovery_design <- function() {
  design <- data.frame(
    id = sprintf("recovery_%03d", seq_len(5L)),
    coefficient_m2_h = c(.6, .6, .6, 3, 5),
    configuration = c("continuous", "clustered", "fragmented", "continuous", "continuous"),
    profile = c("none", "none", "none", "sustained", "sustained"),
    water = "near", policy = "experienced", access = "physical",
    subdivisions = 1L, boundary = "bounded", comparison = "repair",
    role = "primary", stringsAsFactors = FALSE
  )
  design$baseline_key <- ifelse(design$coefficient_m2_h == .6,
    paste(design$configuration, design$subdivisions, design$boundary, sep = "_"),
    paste(design$coefficient_m2_h, design$configuration, sep = "_"))
  design
}

.feeding_access_recovery_cache <- function(d, reference, foundation) {
  if (d$coefficient_m2_h == .6 && d$profile == "none") {
    source_name <- "feeding-access-062"
    cached_design <- foundation$design
    i <- which(cached_design$configuration == d$configuration &
      cached_design$profile == d$profile & cached_design$water == d$water &
      cached_design$policy == d$policy & cached_design$access == d$access &
      cached_design$subdivisions == d$subdivisions & cached_design$boundary == d$boundary)
    stopifnot(length(i) == 1L)
    cached_run <- foundation$runs[[cached_design$id[[i]]]]
    baseline_key <- paste(d$configuration, d$subdivisions, d$boundary, sep = "_")
    baseline <- foundation$baselines[[baseline_key]]
  } else {
    source_name <- "feeding-access-063"
    cached_design <- reference$design
    i <- which(cached_design$coefficient_m2_h == d$coefficient_m2_h &
      cached_design$configuration == d$configuration &
      cached_design$profile == d$profile & cached_design$water == d$water &
      cached_design$policy == d$policy & cached_design$access == d$access &
      cached_design$subdivisions == d$subdivisions &
      cached_design$boundary == d$boundary)
    stopifnot(length(i) == 1L)
    cached_run <- reference$runs[[cached_design$id[[i]]]]
    baseline_key <- paste(d$coefficient_m2_h, d$configuration, sep = "_")
    baseline <- reference$baselines[[baseline_key]]
  }
  stopifnot(is.list(cached_run), is.list(baseline), is.na(baseline$stop_day),
    tail(baseline$hourly$day, 1L) == 60L)
  list(source = source_name, run = cached_run, baseline = baseline)
}

.feeding_access_recovery_replay_equal <- function(a, b) {
  identical(a$stop_day, b$stop_day) && identical(a$stop_hour, b$stop_hour) &&
    identical(a$hourly, b$hourly)
}

.feeding_access_recovery_summary <- function(run, system, d, branch) {
  # Reuse the accepted 063 summary and validation bounds.  All three reported
  # branches begin at the cached day-60 prefix, so the helper's bound origin
  # is the matched state rather than the day-1 opening state.
  checked <- feeding_access_sensitivity_summary(run, system, d$profile)
  checked$id <- d$id
  checked$coefficient_m2_h <- d$coefficient_m2_h
  checked$configuration <- d$configuration
  checked$profile <- d$profile
  checked$water <- d$water
  checked$policy <- if (branch == "informed") "informed" else "experienced"
  checked$branch <- branch
  checked
}

.feeding_access_recovery_memory_at_opening <- function(hourly, first_day, n) {
  memory <- new_feeding_memory(n)
  prior_days <- sort(unique(hourly$day[hourly$day < first_day]))
  for (d in prior_days) {
    x <- hourly[hourly$day == d,,drop = FALSE]
    if (nrow(x) != 24L || !identical(sort(x$hour), 0:23)) next
    intake <- numeric(n); feeding_h <- numeric(n)
    for (station in seq_len(n)) {
      intake[station] <- sum(x$intake_kg_dm[x$station == station])
      feeding_h[station] <- sum(x$feeding_h[x$station == station])
    }
    current <- x$station[[nrow(x)]]
    memory <- update_feeding_memory(memory, intake, feeding_h, d, current,
      moved = any(x$forage_departure))
  }
  memory
}

.feeding_access_recovery_revisits <- function(run, system, d, branch) {
  h <- run$hourly
  if (!nrow(h)) return(data.frame())
  daily <- do.call(rbind, lapply(split(h, h$day), function(x) {
    do.call(rbind, lapply(split(x, x$station), function(s) data.frame(
      day = s$day[[1L]], station = s$station[[1L]], intake_kg_dm = sum(s$intake_kg_dm),
      feeding_h = sum(s$feeding_h), forage_travel_h = sum(s$forage_travel_h),
      stringsAsFactors = FALSE)))
  }))
  daily <- daily[daily$feeding_h > 0,,drop = FALSE]
  if (!nrow(daily)) return(data.frame())
  daily <- daily[order(daily$day, daily$station),,drop = FALSE]
  group <- cumsum(c(TRUE, daily$station[-1L] != daily$station[-nrow(daily)]))
  residences <- lapply(split(daily, group), function(x) data.frame(
    station = x$station[[1L]], first_feeding_day = min(x$day),
    last_feeding_day = max(x$day), feeding_days = nrow(x),
    intake_kg_dm = sum(x$intake_kg_dm), feeding_h = sum(x$feeding_h),
    first_day_realized_return_kj_h = 10000 * x$intake_kg_dm[[1L]] / x$feeding_h[[1L]],
    stringsAsFactors = FALSE))
  residences <- do.call(rbind, residences)
  residences$residence_index <- seq_len(nrow(residences))
  residences$revisit <- vapply(seq_len(nrow(residences)), function(i) {
    if (i == 1L) FALSE else residences$station[[i]] %in%
      residences$station[seq_len(i - 1L)]
  }, logical(1))
  residences$previous_station <- c(NA, residences$station[-nrow(residences)])
  residences$previous_last_feeding_day <- vapply(seq_len(nrow(residences)), function(i) {
    prior <- which(residences$station[seq_len(i - 1L)] == residences$station[[i]])
    if (!length(prior)) NA_integer_ else residences$last_feeding_day[[prior[[length(prior)]]]]
  }, integer(1))
  residences$complete_absent_days <- ifelse(is.na(residences$previous_last_feeding_day),
    NA_integer_, residences$first_feeding_day - residences$previous_last_feeding_day - 1L)
  residences$interruption <- c(NA_character_, vapply(seq_len(nrow(residences) - 1L), function(i) {
    gap <- h[h$day > residences$last_feeding_day[[i]] &
      h$day < residences$first_feeding_day[[i + 1L]],,drop = FALSE]
    if (residences$first_feeding_day[[i + 1L]] - residences$last_feeding_day[[i]] <= 1L)
      "station_switch" else if (any(gap$forage_travel_h > 0))
      "travel_or_no_feed" else "no_feed"
  }, character(1)))
  residences$expected_return_opening_kj_h <- NA_real_
  forecast <- switch(branch, repaired = feeding_expected_return,
    old_full = feeding_two_day_expected_return, NULL)
  for (i in which(residences$revisit)) {
    if (!is.null(forecast)) {
      opening <- residences$first_feeding_day[[i]]
      memory <- .feeding_access_recovery_memory_at_opening(h, opening, nrow(system$stations))
      residences$expected_return_opening_kj_h[[i]] <- if (identical(branch, "repaired"))
        forecast(memory, opening, search_area_m2_h = system$search_area_m2_h,
          growth_rate_h = system$growth_rate_h, senescence_rate_h = system$senescence_rate_h,
          production_saturation_biomass_kg_dm_ha =
            sum(system$K * system$cell_area_ha) / sum(system$cell_area_ha),
          residual_kg_dm_ha = 200)[[residences$station[[i]]]] else
        forecast(memory, opening)[[residences$station[[i]]]]
    }
  }
  residences <- residences[residences$revisit & residences$first_feeding_day >= 61L,,drop = FALSE]
  if (!nrow(residences)) return(data.frame())
  residences$id <- d$id; residences$branch <- branch
  residences$expected_return_reference <- "first_day_opening_before_departure"
  residences$realized_return_reference <- "first_feeding_day_daily_aggregate"
  residences[, c("id", "branch", "residence_index", "station", "first_feeding_day",
    "last_feeding_day", "feeding_days", "previous_last_feeding_day",
    "complete_absent_days", "previous_station",
    "interruption", "first_day_realized_return_kj_h", "expected_return_opening_kj_h",
    "expected_return_reference", "realized_return_reference", "intake_kg_dm", "feeding_h")]
}

.feeding_access_recovery_common_horizon <- function(entries, d) {
  runs <- Filter(Negate(is.null), list(old = entries$old_full,
    repaired = entries$repaired, informed = entries$informed))
  last <- vapply(runs, function(x) max(x$hourly$day * 24 + x$hourly$hour), numeric(1))
  horizon <- min(last)
  metric <- function(run, name) {
    x <- run$hourly
    keep <- x$day >= 61L & x$day * 24 + x$hour <= horizon
    sum(x[[name]][keep])
  }
  row <- data.frame(id = d$id, horizon_day = horizon %/% 24L,
    horizon_hour = horizon %% 24L, stringsAsFactors = FALSE)
  for (nm in c("old", "repaired", "informed")) {
    run <- if (nm == "old") entries$old_full else entries[[nm]]
    for (field in c("intake_kg_dm", "forage_expenditure_kj", "water_expenditure_kj",
      "forage_travel_h", "water_travel_h"))
      row[[paste0(nm, "_", field)]] <- if (is.null(run)) NA_real_ else metric(run, field)
    if (is.null(run)) {
      row[[paste0(nm, "_end_energy_kj")]] <- NA_real_
      row[[paste0(nm, "_end_water_kg")]] <- NA_real_
    } else {
      x <- run$hourly
      keep <- x$day >= 61L & x$day * 24 + x$hour <= horizon
      row[[paste0(nm, "_end_energy_kj")]] <- x$body_energy_kj[max(which(keep))]
      row[[paste0(nm, "_end_water_kg")]] <- x$body_water_kg[max(which(keep))]
    }
  }
  row
}

run_feeding_access_recovery_repair <- function(cores = 1L, progress = interactive(),
  reference_path = "outputs/feeding-access-063/sensitivity.rds",
  foundation_path = "outputs/feeding-access-062/study.rds") {
  stopifnot(length(cores) == 1L, cores == as.integer(cores), cores >= 1L, cores <= 3L,
    file.exists(reference_path), file.exists(foundation_path))
  validate_feeding_access_recovery()
  reference <- readRDS(reference_path); foundation <- readRDS(foundation_path)
  design <- feeding_access_recovery_design()
  systems <- setNames(lapply(seq_len(nrow(design)), function(i)
    new_feeding_access_sensitivity_system(design$configuration[[i]], design$coefficient_m2_h[[i]])), design$id)
  run_one <- function(i) {
    d <- design[i,,drop = FALSE]; system <- systems[[d$id]]
    cache <- .feeding_access_recovery_cache(d, reference, foundation)
    if (progress) message("Recovery ", d$id, " ", d$configuration, " q=", d$coefficient_m2_h)
    old_full <- run_feeding_access(system, profile = d$profile, water = d$water,
      policy = d$policy, access = d$access, final_day = 228L,
      baseline = cache$baseline,
      return_forecast = feeding_two_day_expected_return)
    stopifnot(.feeding_access_recovery_replay_equal(old_full, cache$run))
    repaired <- run_feeding_access(system, profile = d$profile, water = d$water,
      policy = d$policy, access = d$access, final_day = 228L,
      baseline = cache$baseline, return_forecast = feeding_expected_return)
    stopifnot(identical(repaired$initial_branch_state, cache$baseline$final_state),
      identical(repaired$hourly[repaired$hourly$day <= 60L,,drop = FALSE], cache$baseline$hourly))
    informed <- NULL
    if ((d$coefficient_m2_h == .6 && d$profile == "none" &&
      d$configuration %in% c("clustered", "fragmented")) || d$coefficient_m2_h %in% c(3, 5)) {
      x <- reference$design
      j <- which(x$coefficient_m2_h == d$coefficient_m2_h & x$configuration == d$configuration &
        x$profile == d$profile & x$water == d$water & x$policy == "informed" &
        x$access == d$access & x$subdivisions == d$subdivisions & x$boundary == d$boundary)
      if (length(j) == 1L) {
        informed <- reference$runs[[x$id[[j]]]]
        stopifnot(identical(informed$initial_branch_state, cache$baseline$final_state),
          identical(informed$hourly[informed$hourly$day <= 60L,,drop = FALSE],
            cache$baseline$hourly))
      }
    }
    entries <- list(old_full = old_full, repaired = repaired, informed = informed)
    list(system = system, baseline = cache$baseline, cache_source = cache$source,
      cached_old = cache$run, old_full = old_full, repaired = repaired, informed = informed,
      replay = data.frame(id = d$id, cached_source = cache$source,
        old_replay_identical = TRUE, repaired_prefix_identical = TRUE),
      summary = do.call(rbind, lapply(names(entries), function(nm)
        if (is.null(entries[[nm]])) NULL else .feeding_access_recovery_summary(entries[[nm]], system, d, nm))),
      revisits = do.call(rbind, lapply(names(entries), function(nm)
        if (is.null(entries[[nm]])) NULL else .feeding_access_recovery_revisits(entries[[nm]], system, d, nm))),
      common_horizon = .feeding_access_recovery_common_horizon(entries, d))
  }
  results <- parallel::mclapply(seq_len(nrow(design)), run_one,
    mc.cores = cores, mc.preschedule = FALSE)
  if (any(vapply(results, inherits, logical(1), "try-error"))) stop("A recovery worker failed.")
  names(results) <- design$id
  summary <- do.call(rbind, lapply(results, `[[`, "summary"))
  revisits <- do.call(rbind, lapply(results, `[[`, "revisits"))
  common_horizon <- do.call(rbind, lapply(results, `[[`, "common_horizon"))
  list(design = design, systems = lapply(results, `[[`, "system"),
    baselines = lapply(results, `[[`, "baseline"), runs = results,
    summary = summary, revisits = revisits, common_horizon = common_horizon,
    provenance = list(generated_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
      R = R.version.string, reference_path = reference_path, foundation_path = foundation_path))
}

if (sys.nframe() == 0L) {
  result <- run_feeding_access_recovery_repair(cores = 1L, progress = TRUE)
  print(result$summary[, c("branch", "id", "completed", "exit_day", "end_day",
    "energy_end_kj", "energy_day60_kj")], row.names = FALSE, digits = 5)
}
