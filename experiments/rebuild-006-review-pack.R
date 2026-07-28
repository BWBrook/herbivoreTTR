declared_files <- c(
  "figure-1-measured-reference-comparison.png",
  "table-1-input-schedules.csv",
  "table-2-convergence.csv",
  "table-3-daily-summary.csv",
  "table-4-hourly-ledgers.csv"
)
scenario_ids <- c("mathematical_continuous", "ecological_day_resting")
reference_types <- c(
  mathematical_continuous = "mathematical",
  ecological_day_resting = "ecological"
)

convergence_names <- c(
  "burn_in_day", "gut_available_energy_initial_kj",
  "gut_available_energy_final_kj", "cycle_boundary_change_kj",
  "max_abs_previous_day_trajectory_difference_kj",
  "realized_convergence_tolerance_kj", "converged"
)
daily_names <- c(
  "measurement_day", "gut_available_energy_initial_kj",
  "total_prescribed_ingested_available_energy_kj",
  "total_assimilated_energy_kj", "expected_gut_energy_change_kj",
  "observed_gut_energy_change_kj", "gut_available_energy_final_kj",
  "gut_energy_balance_residual_kj", "body_energy_reserve_initial_kj",
  "total_maintenance_expenditure_kj",
  "expected_body_energy_change_kj", "observed_body_energy_change_kj",
  "body_energy_reserve_final_kj", "body_energy_balance_residual_kj",
  "total_system_energy_initial_kj",
  "expected_total_system_energy_change_kj",
  "observed_total_system_energy_change_kj",
  "total_system_energy_final_kj", "system_energy_balance_residual_kj",
  "body_energy_status"
)
hourly_names <- c(
  "measurement_day", "hour_of_day", "time_start_h", "time_end_h",
  "gut_available_energy_start_kj",
  "prescribed_ingested_available_energy_kj_h",
  "gut_release_fraction_h", "assimilated_energy_kj_h",
  "prescribed_ingested_available_energy_kj", "assimilated_energy_kj",
  "gut_energy_change_kj", "gut_available_energy_end_kj",
  "gut_energy_balance_residual_kj", "body_energy_reserve_start_kj",
  "maintenance_expenditure_kj_h", "maintenance_expenditure_kj",
  "body_energy_change_kj", "body_energy_reserve_end_kj",
  "body_energy_balance_residual_kj", "total_system_energy_start_kj",
  "total_system_energy_end_kj", "system_energy_balance_residual_kj"
)

is_link <- function(path) {
  target <- Sys.readlink(path)
  length(target) == 1L && !is.na(target) && nzchar(target)
}

path_exists <- function(path) {
  file.exists(path) || dir.exists(path) || is_link(path)
}

check_file_set <- function(path, exact) {
  if (is_link(path) || !dir.exists(path)) {
    stop("Review-pack path must be a non-symbolic directory.", call. = FALSE)
  }
  entries <- list.files(path, all.files = TRUE, no.. = TRUE)
  unknown <- setdiff(entries, declared_files)
  if (length(unknown)) {
    stop(
      sprintf("Undeclared review-pack path(s): %s.", paste(unknown, collapse = ", ")),
      call. = FALSE
    )
  }
  regular <- vapply(entries, function(entry) {
    file <- file.path(path, entry)
    !is_link(file) && file_test("-f", file) && !isTRUE(file.info(file)$isdir)
  }, logical(1L))
  if (!all(regular)) {
    stop("Every declared review-pack entry must be a regular file.", call. = FALSE)
  }
  if (exact && !identical(sort(entries), sort(declared_files))) {
    stop("Review-pack file set is incomplete.", call. = FALSE)
  }
  invisible(entries)
}

require_that <- function(condition, label) {
  if (length(condition) != 1L || !isTRUE(condition)) {
    stop(sprintf("Analytical assertion failed: %s.", label), call. = FALSE)
  }
  invisible(NULL)
}

require_close <- function(actual, expected, tolerance, label) {
  ok <- length(actual) == length(expected) &&
    length(tolerance) == 1L && is.finite(tolerance) && tolerance >= 0 &&
    all(is.finite(actual)) && all(is.finite(expected)) &&
    all(abs(actual - expected) <= tolerance)
  require_that(ok, label)
}

expected_dm <- function(scenario_id) {
  switch(
    scenario_id,
    mathematical_continuous = rep(0.010, 24L),
    ecological_day_resting = c(rep(0.015, 8L), rep(0, 8L), rep(0.015, 8L)),
    stop("Unknown scenario.", call. = FALSE)
  )
}

make_fixture <- function(scenario_id) {
  dry_matter <- herbivoreTTR::new_dry_matter_intake_schedule(
    hour_of_day = 0:23,
    prescribed_dry_matter_intake_kg_dm_h = expected_dm(scenario_id)
  )
  energy <- herbivoreTTR::derive_ingested_available_energy_schedule(
    herbivoreTTR::new_food_energy_parameters(10000),
    dry_matter
  )
  result <- herbivoreTTR::run_gut_body_energy_reference_cycle(
    herbivoreTTR::new_gut_energy_state(0),
    herbivoreTTR::new_body_energy_state(10000),
    herbivoreTTR::new_gut_energy_parameters(0.25),
    herbivoreTTR::new_body_energy_parameters(100),
    energy,
    herbivoreTTR::new_routine_activity_expenditure_schedule(
      0:23,
      rep(0, 24L)
    ),
    100 * .Machine$double.eps,
    100L
  )
  list(
    scenario_id = scenario_id,
    reference_type = unname(reference_types[[scenario_id]]),
    dry_matter = dry_matter,
    energy = energy,
    result = result
  )
}

day_rows <- function(table, day) {
  table[table$measurement_day == day, , drop = FALSE]
}
gut_boundaries <- function(hourly) {
  c(hourly$gut_available_energy_start_kj[[1L]],
    hourly$gut_available_energy_end_kj)
}
body_boundaries <- function(hourly) {
  c(hourly$body_energy_reserve_start_kj[[1L]],
    hourly$body_energy_reserve_end_kj)
}

daily_tolerances <- function(result, day) {
  hourly <- day_rows(result$hourly, day)
  daily <- day_rows(result$daily, day)
  cycle <- tail(result$convergence$realized_convergence_tolerance_kj, 1L)
  gut <- 100 * .Machine$double.eps * max(
    1, abs(daily$gut_available_energy_initial_kj),
    abs(daily$gut_available_energy_final_kj),
    sum(abs(hourly$prescribed_ingested_available_energy_kj)),
    sum(abs(hourly$assimilated_energy_kj))
  )
  body <- 100 * .Machine$double.eps * max(
    1, abs(daily$body_energy_reserve_initial_kj),
    abs(daily$body_energy_reserve_final_kj),
    sum(abs(hourly$assimilated_energy_kj)),
    sum(abs(hourly$maintenance_expenditure_kj))
  )
  c(cycle = cycle, assimilation = cycle + gut, body = cycle + gut + body)
}

check_fixture <- function(fixture) {
  scenario_id <- fixture$scenario_id
  result <- fixture$result
  dm <- expected_dm(scenario_id)
  energy <- dm * 10000

  require_that(
    identical(fixture$reference_type, unname(reference_types[[scenario_id]])) &&
      identical(fixture$dry_matter$hour_of_day, 0:23) &&
      identical(fixture$dry_matter$prescribed_dry_matter_intake_kg_dm_h, dm) &&
      identical(fixture$energy$hour_of_day, 0:23) &&
      all(
        fixture$energy$prescribed_ingested_available_energy_kj_h == energy
      ),
    paste(scenario_id, "input schedule")
  )
  require_close(
    sum(dm), 0.24, 100 * .Machine$double.eps,
    paste(scenario_id, "dry-matter total")
  )
  require_that(sum(energy) == 2400, paste(scenario_id, "energy total"))
  require_that(
    identical(names(result$convergence), convergence_names) &&
      identical(names(result$daily), daily_names) &&
      identical(names(result$hourly), hourly_names),
    paste(scenario_id, "accepted ledger schemas")
  )

  tolerance <- tail(result$convergence$realized_convergence_tolerance_kj, 1L)
  require_that(
    tail(result$convergence$burn_in_day, 1L) == 7L &&
      isTRUE(tail(result$convergence$converged, 1L)) &&
      is.finite(tolerance) && tolerance > 0,
    paste(scenario_id, "day-7 convergence")
  )
  require_close(
    tail(result$convergence$cycle_boundary_change_kj, 1L), 0, tolerance,
    paste(scenario_id, "cycle closure")
  )
  require_close(
    tail(result$convergence$max_abs_previous_day_trajectory_difference_kj, 1L),
    0, tolerance, paste(scenario_id, "trajectory convergence")
  )

  day_1 <- day_rows(result$hourly, 1L)
  day_2 <- day_rows(result$hourly, 2L)
  require_close(
    gut_boundaries(day_2), gut_boundaries(day_1), tolerance,
    paste(scenario_id, "measured-cycle repetition")
  )
  require_that(
    day_1$gut_available_energy_end_kj[[24L]] ==
      day_2$gut_available_energy_start_kj[[1L]] &&
      day_1$body_energy_reserve_end_kj[[24L]] ==
        day_2$body_energy_reserve_start_kj[[1L]],
    paste(scenario_id, "day carry-over")
  )
  body <- c(
    day_1$body_energy_reserve_start_kj, day_1$body_energy_reserve_end_kj,
    day_2$body_energy_reserve_start_kj, day_2$body_energy_reserve_end_kj
  )
  require_that(
    all(is.finite(body)) && all(body >= 0),
    paste(scenario_id, "feasible body path")
  )

  for (day in 1:2) {
    daily <- day_rows(result$daily, day)
    tol <- daily_tolerances(result, day)
    require_that(
      daily$total_prescribed_ingested_available_energy_kj == 2400 &&
        daily$total_maintenance_expenditure_kj == 2400,
      paste(scenario_id, "daily forcing")
    )
    require_close(
      daily$gut_available_energy_final_kj,
      daily$gut_available_energy_initial_kj, tol[["cycle"]],
      paste(scenario_id, "daily gut closure")
    )
    require_close(
      daily$total_assimilated_energy_kj,
      daily$total_prescribed_ingested_available_energy_kj,
      tol[["assimilation"]], paste(scenario_id, "daily assimilation")
    )
    require_close(
      daily$observed_body_energy_change_kj, 0, tol[["body"]],
      paste(scenario_id, "body neutrality")
    )
  }
  invisible(NULL)
}

check_comparison <- function(fixtures) {
  mathematical <- fixtures$mathematical_continuous$result
  ecological <- fixtures$ecological_day_resting$result
  for (day in 1:2) {
    m_daily <- day_rows(mathematical$daily, day)
    e_daily <- day_rows(ecological$daily, day)
    m_tol <- daily_tolerances(mathematical, day)
    e_tol <- daily_tolerances(ecological, day)
    require_that(
      m_daily$total_prescribed_ingested_available_energy_kj ==
        e_daily$total_prescribed_ingested_available_energy_kj &&
        m_daily$total_maintenance_expenditure_kj ==
          e_daily$total_maintenance_expenditure_kj,
      paste("day", day, "equal prescribed totals")
    )
    require_close(
      m_daily$total_assimilated_energy_kj,
      e_daily$total_assimilated_energy_kj,
      m_tol[["assimilation"]] + e_tol[["assimilation"]],
      paste("day", day, "assimilation equivalence")
    )
    require_close(
      m_daily$observed_gut_energy_change_kj,
      e_daily$observed_gut_energy_change_kj,
      m_tol[["cycle"]] + e_tol[["cycle"]],
      paste("day", day, "gut-change equivalence")
    )
    require_close(
      m_daily$observed_body_energy_change_kj,
      e_daily$observed_body_energy_change_kj,
      m_tol[["body"]] + e_tol[["body"]],
      paste("day", day, "body-change equivalence")
    )

    m_hourly <- day_rows(mathematical$hourly, day)
    e_hourly <- day_rows(ecological$hourly, day)
    m_gut <- gut_boundaries(m_hourly)
    e_gut <- gut_boundaries(e_hourly)
    m_body <- body_boundaries(m_hourly)
    e_body <- body_boundaries(e_hourly)
    contrasts <- c(
      gut = max(abs(m_gut - e_gut)),
      assimilation = max(abs(
        m_hourly$assimilated_energy_kj - e_hourly$assimilated_energy_kj
      )),
      body = max(abs(m_body - e_body))
    )
    require_that(
      contrasts[["gut"]] > m_tol[["cycle"]] + e_tol[["cycle"]] &&
        contrasts[["assimilation"]] >
          m_tol[["assimilation"]] + e_tol[["assimilation"]] &&
        contrasts[["body"]] > m_tol[["body"]] + e_tol[["body"]],
      paste("day", day, "distinct trajectories")
    )
    require_that(
      contrasts[["gut"]] >= 340 && contrasts[["gut"]] <= 341 &&
        contrasts[["assimilation"]] >= 85 &&
        contrasts[["assimilation"]] <= 86 &&
        contrasts[["body"]] >= 411 && contrasts[["body"]] <= 412,
      paste("day", day, "trajectory magnitude bands")
    )
    require_that(
      which.max(e_gut) == 9L && which.min(e_gut) == 17L &&
        which.max(e_hourly$assimilated_energy_kj) == 9L &&
        which.min(e_hourly$assimilated_energy_kj) == 17L &&
        which.max(e_body) == 11L && which.min(e_body) == 21L,
      paste("day", day, "ecological phase landmarks")
    )
  }
  invisible(NULL)
}

make_tables <- function(fixtures) {
  bind <- function(make) {
    value <- do.call(rbind, lapply(fixtures, make))
    row.names(value) <- NULL
    value
  }
  list(
    input = bind(function(x) data.frame(
      scenario_id = x$scenario_id,
      reference_type = x$reference_type,
      hour_of_day = x$dry_matter$hour_of_day,
      prescribed_dry_matter_intake_kg_dm_h =
        x$dry_matter$prescribed_dry_matter_intake_kg_dm_h,
      prescribed_ingested_available_energy_kj_h =
        x$energy$prescribed_ingested_available_energy_kj_h,
      check.names = FALSE
    )),
    convergence = bind(function(x) data.frame(
      scenario_id = x$scenario_id, reference_type = x$reference_type,
      x$result$convergence, check.names = FALSE
    )),
    daily = bind(function(x) data.frame(
      scenario_id = x$scenario_id, reference_type = x$reference_type,
      x$result$daily, check.names = FALSE
    )),
    hourly = bind(function(x) data.frame(
      scenario_id = x$scenario_id, reference_type = x$reference_type,
      prescribed_dry_matter_intake_kg_dm_h = rep(
        x$dry_matter$prescribed_dry_matter_intake_kg_dm_h, 2L
      ),
      x$result$hourly, check.names = FALSE
    ))
  )
}

check_tables <- function(tables) {
  expected_names <- list(
    input = c(
      "scenario_id", "reference_type", "hour_of_day",
      "prescribed_dry_matter_intake_kg_dm_h",
      "prescribed_ingested_available_energy_kj_h"
    ),
    convergence = c("scenario_id", "reference_type", convergence_names),
    daily = c("scenario_id", "reference_type", daily_names),
    hourly = c(
      "scenario_id", "reference_type",
      "prescribed_dry_matter_intake_kg_dm_h", hourly_names
    )
  )
  expected_rows <- c(input = 48L, convergence = 14L, daily = 4L, hourly = 96L)
  require_that(
    identical(names(tables), names(expected_names)) &&
      all(vapply(names(tables), function(name) {
        identical(names(tables[[name]]), expected_names[[name]]) &&
          nrow(tables[[name]]) == expected_rows[[name]]
      }, logical(1L))),
    "exact table schemas"
  )
  require_that(
    identical(tables$input$scenario_id, rep(scenario_ids, each = 24L)) &&
      identical(tables$daily$scenario_id, rep(scenario_ids, each = 2L)) &&
      identical(tables$hourly$scenario_id, rep(scenario_ids, each = 48L)),
    "table scenario keys"
  )
  for (scenario_id in scenario_ids) {
    input <- tables$input$scenario_id == scenario_id
    hourly <- tables$hourly$scenario_id == scenario_id
    require_that(
      identical(tables$input$hour_of_day[input], 0:23) &&
        identical(
          tables$input$prescribed_dry_matter_intake_kg_dm_h[input],
          expected_dm(scenario_id)
        ) &&
        identical(
          tables$hourly$prescribed_dry_matter_intake_kg_dm_h[hourly],
          rep(expected_dm(scenario_id), 2L)
        ),
      paste(scenario_id, "serialized input identity")
    )
  }
  invisible(NULL)
}

fixtures_from_tables <- function(tables) {
  fixtures <- lapply(scenario_ids, function(scenario_id) {
    input <- tables$input[tables$input$scenario_id == scenario_id, ]
    select <- function(table, names) {
      table[table$scenario_id == scenario_id, names, drop = FALSE]
    }
    list(
      scenario_id = scenario_id,
      reference_type = unique(input$reference_type),
      dry_matter = input[c(
        "hour_of_day", "prescribed_dry_matter_intake_kg_dm_h"
      )],
      energy = input[c(
        "hour_of_day", "prescribed_ingested_available_energy_kj_h"
      )],
      result = list(
        convergence = select(tables$convergence, convergence_names),
        hourly = select(tables$hourly, hourly_names),
        daily = select(tables$daily, daily_names)
      )
    )
  })
  names(fixtures) <- scenario_ids
  fixtures
}

write_csv <- function(value, path) {
  utils::write.csv(value, path, row.names = FALSE, na = "")
}
read_csv <- function(path) {
  utils::read.csv(
    path, stringsAsFactors = FALSE, check.names = FALSE, na.strings = ""
  )
}

write_figure <- function(fixtures, path) {
  elapsed <- 0:48
  matrix_from <- function(extract, boundary = FALSE) {
    value <- do.call(cbind, lapply(fixtures, function(x) {
      hourly <- x$result$hourly
      if (boundary) extract(hourly) else {
        rates <- extract(hourly)
        c(rates, tail(rates, 1L))
      }
    }))
    colnames(value) <- scenario_ids
    value
  }
  panels <- list(
    ingestion = matrix_from(function(x) {
      x$prescribed_ingested_available_energy_kj_h
    }),
    assimilation = matrix_from(function(x) x$assimilated_energy_kj_h),
    gut = matrix_from(gut_boundaries, boundary = TRUE),
    body = matrix_from(body_boundaries, boundary = TRUE)
  )
  colors <- c(mathematical_continuous = "#0072B2",
              ecological_day_resting = "#D55E00")
  line_types <- c(mathematical_continuous = 1,
                  ecological_day_resting = 2)

  draw_panel <- function(values, ylab, title, step = FALSE) {
    limits <- range(values, finite = TRUE)
    pad <- max(diff(limits) * 0.06, 1)
    graphics::plot(
      NA, NA, xlim = c(0, 48), ylim = limits + c(-pad, pad),
      xlab = "Elapsed measurement time (h)", ylab = ylab, main = title,
      xaxs = "i", yaxs = "i"
    )
    usr <- graphics::par("usr")
    graphics::rect(
      c(8, 32), usr[[3L]], c(16, 40), usr[[4L]],
      col = "#E8E8E8", border = NA
    )
    graphics::abline(v = 24, col = "#666666", lty = 3, lwd = 1.5)
    graphics::matlines(
      elapsed, values, type = if (step) "s" else "l",
      col = colors[colnames(values)], lty = line_types[colnames(values)],
      lwd = 2.8
    )
    graphics::box()
  }

  grDevices::png(
    path, width = 2200, height = 1600, units = "px",
    pointsize = 14, bg = "white", res = 150
  )
  device <- grDevices::dev.cur()
  on.exit(if (device %in% grDevices::dev.list()) grDevices::dev.off(device))
  old_par <- graphics::par(
    mfrow = c(2, 2), mar = c(4.8, 5.4, 3.1, 1.2),
    oma = c(2.4, 0, 5.5, 0), las = 1
  )
  on.exit(graphics::par(old_par), add = TRUE)
  draw_panel(
    panels$ingestion, "Prescribed gut input (kJ h^-1)",
    "Prescribed ingestion", step = TRUE
  )
  draw_panel(
    panels$assimilation, "Gut release to body (kJ h^-1)",
    "Assimilation", step = TRUE
  )
  draw_panel(panels$gut, "Gut available energy (kJ)", "Gut boundary stock")
  draw_panel(
    panels$body, "Body energy reserve (kJ)", "Body-reserve boundary stock"
  )
  graphics::mtext(
    "Synthetic energy-matched daily references",
    side = 3, outer = TRUE, line = 3.1, font = 2, cex = 1.18
  )
  graphics::mtext(
    "Grey: ecological rest-closed intervals; dotted line: day boundary",
    side = 3, outer = TRUE, line = 1.8, cex = 0.84
  )
  graphics::mtext(
    "Each reference prescribes 2400 kJ and 0.24 kg DM per day",
    side = 1, outer = TRUE, line = 0.7, cex = 0.82
  )
  graphics::par(
    fig = c(0, 1, 0, 1), mar = rep(0, 4L), oma = rep(0, 4L), new = TRUE
  )
  graphics::plot.new()
  graphics::legend(
    "top", inset = 0.085, horiz = TRUE,
    legend = c("Mathematical: continuous", "Ecological: day-resting"),
    col = colors, lty = line_types, lwd = 2.8, bty = "n", cex = 0.82
  )
  grDevices::dev.off(device)
  on.exit(NULL)
}

publish_pack <- function(stage, destination) {
  parent <- dirname(destination)
  if (!dir.exists(parent) &&
      !dir.create(parent, recursive = TRUE, showWarnings = FALSE)) {
    stop("Could not create review-pack parent.", call. = FALSE)
  }
  if (is_link(parent) || file.access(parent, 2L) != 0L) {
    stop("Review-pack parent must be a writable directory.", call. = FALSE)
  }
  candidate <- tempfile(paste0(".", basename(destination), "-"), tmpdir = parent)
  if (!dir.create(candidate)) {
    stop("Could not create publication candidate.", call. = FALSE)
  }
  on.exit(unlink(candidate, recursive = TRUE, force = TRUE))
  copied <- file.copy(
    file.path(stage, declared_files), candidate,
    overwrite = FALSE, copy.date = FALSE
  )
  if (!all(copied)) {
    stop("Could not copy the complete publication candidate.", call. = FALSE)
  }
  check_file_set(candidate, exact = TRUE)

  if (!path_exists(destination)) {
    if (!file.rename(candidate, destination)) {
      stop("Could not publish review pack.", call. = FALSE)
    }
    return(invisible(NULL))
  }
  check_file_set(destination, exact = FALSE)
  backup <- tempfile(paste0(".", basename(destination), "-old-"), tmpdir = parent)
  if (!file.rename(destination, backup)) {
    stop("Could not move previous review pack aside.", call. = FALSE)
  }
  if (!file.rename(candidate, destination)) {
    file.rename(backup, destination)
    stop("Could not replace review pack.", call. = FALSE)
  }
  if (unlink(backup, recursive = TRUE, force = TRUE) != 0L) {
    stop("Could not remove superseded review pack.", call. = FALSE)
  }
  invisible(NULL)
}

main <- function() {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) != 1L || is.na(args[[1L]]) || !nzchar(args[[1L]])) {
    stop("Supply exactly one non-empty output-directory argument.", call. = FALSE)
  }
  destination <- sub("/+$", "", args[[1L]])
  if (!nzchar(destination) || destination == "." || is_link(destination)) {
    stop("Supply a dedicated non-symbolic output directory.", call. = FALSE)
  }
  if (path_exists(destination)) {
    check_file_set(destination, exact = FALSE)
  }

  old_options <- options(digits = 17)
  on.exit(options(old_options), add = TRUE)
  fixtures <- lapply(scenario_ids, make_fixture)
  names(fixtures) <- scenario_ids
  invisible(lapply(fixtures, check_fixture))
  check_comparison(fixtures)
  tables <- make_tables(fixtures)
  check_tables(tables)

  stage <- tempfile("rebuild006-review-pack-")
  if (!dir.create(stage)) {
    stop("Could not create staging directory.", call. = FALSE)
  }
  on.exit(unlink(stage, recursive = TRUE, force = TRUE), add = TRUE)
  paths <- c(
    input = file.path(stage, "table-1-input-schedules.csv"),
    convergence = file.path(stage, "table-2-convergence.csv"),
    daily = file.path(stage, "table-3-daily-summary.csv"),
    hourly = file.path(stage, "table-4-hourly-ledgers.csv")
  )
  for (name in names(paths)) {
    write_csv(tables[[name]], paths[[name]])
  }
  read_back <- lapply(paths, read_csv)
  check_tables(read_back)
  read_back_fixtures <- fixtures_from_tables(read_back)
  invisible(lapply(read_back_fixtures, check_fixture))
  check_comparison(read_back_fixtures)

  write_figure(
    fixtures,
    file.path(stage, "figure-1-measured-reference-comparison.png")
  )
  check_file_set(stage, exact = TRUE)
  publish_pack(stage, destination)
  check_file_set(destination, exact = TRUE)

  cat(sprintf("Generated Goal 006 review pack at %s\n", destination))
  cat("Files: 5 (exact declared set; staged and read-back validated)\n")
}

main()
