declared_files <- c(
  "figure-1-burn-in-convergence.png",
  "figure-2-measured-reference-cycles.png",
  "table-1-convergence.csv",
  "table-2-daily-summary.csv",
  "table-3-hourly-ledgers.csv"
)

is_symbolic_link <- function(path) {
  target <- Sys.readlink(path)
  length(target) == 1L && !is.na(target) && nzchar(target)
}

path_exists <- function(path) {
  file.exists(path) || dir.exists(path) || is_symbolic_link(path)
}

validate_destination <- function(destination, require_exact = FALSE) {
  if (is_symbolic_link(destination)) {
    stop("The review-pack destination must not be a symbolic link.", call. = FALSE)
  }
  if (!dir.exists(destination)) {
    stop("The review-pack destination is not a directory.", call. = FALSE)
  }

  entries <- list.files(
    destination,
    all.files = TRUE,
    full.names = FALSE,
    no.. = TRUE
  )
  unknown <- setdiff(entries, declared_files)
  if (length(unknown) != 0L) {
    stop(
      sprintf(
        "The review-pack destination contains undeclared path(s): %s.",
        paste(unknown, collapse = ", ")
      ),
      call. = FALSE
    )
  }
  for (entry in entries) {
    path <- file.path(destination, entry)
    if (
      is_symbolic_link(path) ||
        !file_test("-f", path) ||
        isTRUE(file.info(path)$isdir)
    ) {
      stop(
        sprintf("Declared destination entry `%s` is not a regular file.", entry),
        call. = FALSE
      )
    }
  }
  if (
    require_exact &&
      !identical(
        sort(entries, method = "radix"),
        sort(declared_files, method = "radix")
      )
  ) {
    stop("The generated review-pack file set is incomplete.", call. = FALSE)
  }

  invisible(entries)
}

new_fixture <- function(scenario_id, intake_rates_kg_dm_h) {
  food_parameters <- herbivoreTTR::new_food_energy_parameters(10000)
  dry_matter_schedule <- herbivoreTTR::new_dry_matter_intake_schedule(
    hour_of_day = 0:23,
    prescribed_dry_matter_intake_kg_dm_h = intake_rates_kg_dm_h
  )
  energy_schedule <-
    herbivoreTTR::derive_ingested_available_energy_schedule(
      food_parameters,
      dry_matter_schedule
    )
  result <- herbivoreTTR::run_gut_body_energy_reference_cycle(
    initial_gut_state = herbivoreTTR::new_gut_energy_state(0),
    measurement_body_state = herbivoreTTR::new_body_energy_state(10000),
    gut_parameters = herbivoreTTR::new_gut_energy_parameters(0.25),
    body_parameters = herbivoreTTR::new_body_energy_parameters(100),
    schedule = energy_schedule,
    gut_convergence_relative_tolerance = 100 * .Machine$double.eps,
    max_burn_in_days = 100L
  )

  list(
    scenario_id = scenario_id,
    dry_matter_schedule = dry_matter_schedule,
    energy_schedule = energy_schedule,
    result = result
  )
}

day_hourly <- function(result, measurement_day) {
  result$hourly[
    result$hourly$measurement_day == measurement_day,
    ,
    drop = FALSE
  ]
}

day_daily <- function(result, measurement_day) {
  result$daily[
    result$daily$measurement_day == measurement_day,
    ,
    drop = FALSE
  ]
}

gut_boundaries_kj <- function(hourly) {
  c(
    hourly$gut_available_energy_start_kj[[1L]],
    hourly$gut_available_energy_end_kj
  )
}

body_boundaries_kj <- function(hourly) {
  c(
    hourly$body_energy_reserve_start_kj[[1L]],
    hourly$body_energy_reserve_end_kj
  )
}

daily_tolerances <- function(result, measurement_day) {
  hourly <- day_hourly(result, measurement_day)
  daily <- day_daily(result, measurement_day)
  cycle_tolerance_kj <- tail(
    result$convergence$realized_convergence_tolerance_kj,
    1L
  )
  gut_ledger_tolerance_kj <- 100 * .Machine$double.eps * max(
    1,
    abs(daily$gut_available_energy_initial_kj),
    abs(daily$gut_available_energy_final_kj),
    sum(abs(hourly$prescribed_ingested_available_energy_kj)),
    sum(abs(hourly$assimilated_energy_kj))
  )
  body_ledger_tolerance_kj <- 100 * .Machine$double.eps * max(
    1,
    abs(daily$body_energy_reserve_initial_kj),
    abs(daily$body_energy_reserve_final_kj),
    sum(abs(hourly$assimilated_energy_kj)),
    sum(abs(hourly$maintenance_expenditure_kj))
  )

  c(
    cycle_tolerance_kj = cycle_tolerance_kj,
    gut_ledger_tolerance_kj = gut_ledger_tolerance_kj,
    assimilation_total_tolerance_kj =
      cycle_tolerance_kj + gut_ledger_tolerance_kj,
    body_ledger_tolerance_kj = body_ledger_tolerance_kj,
    body_neutrality_tolerance_kj =
      cycle_tolerance_kj +
        gut_ledger_tolerance_kj +
        body_ledger_tolerance_kj
  )
}

assert_close <- function(actual, expected, tolerance, label) {
  if (
    length(actual) != length(expected) ||
      length(tolerance) != 1L ||
      !is.finite(tolerance) ||
      tolerance < 0 ||
      any(!is.finite(actual)) ||
      any(!is.finite(expected)) ||
      any(abs(actual - expected) > tolerance)
  ) {
    stop(sprintf("Analytical assertion failed: %s.", label), call. = FALSE)
  }
  invisible(NULL)
}

assert_result_contract <- function(fixture) {
  result <- fixture$result
  expected_convergence_names <- c(
    "burn_in_day",
    "gut_available_energy_initial_kj",
    "gut_available_energy_final_kj",
    "cycle_boundary_change_kj",
    "max_abs_previous_day_trajectory_difference_kj",
    "realized_convergence_tolerance_kj",
    "converged"
  )
  if (
    !identical(names(result), c("convergence", "hourly", "daily")) ||
      !identical(names(result$convergence), expected_convergence_names) ||
      nrow(result$convergence) < 2L ||
      !identical(tail(result$convergence$converged, 1L), TRUE) ||
      any(head(result$convergence$converged, -1L)) ||
      !identical(dim(result$hourly), c(48L, 22L)) ||
      !identical(result$hourly$measurement_day, rep(1:2, each = 24L)) ||
      !identical(dim(result$daily), c(2L, 20L)) ||
      !identical(result$daily$measurement_day, 1:2)
  ) {
    stop(
      sprintf("Result contract failed for `%s`.", fixture$scenario_id),
      call. = FALSE
    )
  }

  cycle_tolerance_kj <- tail(
    result$convergence$realized_convergence_tolerance_kj,
    1L
  )
  final_cycle_change_kj <- tail(
    result$convergence$cycle_boundary_change_kj,
    1L
  )
  final_trajectory_difference_kj <- tail(
    result$convergence$
      max_abs_previous_day_trajectory_difference_kj,
    1L
  )
  if (
    !is.finite(cycle_tolerance_kj) ||
      cycle_tolerance_kj <= 0 ||
      !is.finite(final_cycle_change_kj) ||
      !is.finite(final_trajectory_difference_kj) ||
      abs(final_cycle_change_kj) > cycle_tolerance_kj ||
      final_trajectory_difference_kj > cycle_tolerance_kj
  ) {
    stop(
      sprintf("Convergence assertion failed for `%s`.", fixture$scenario_id),
      call. = FALSE
    )
  }

  day_1 <- day_hourly(result, 1L)
  day_2 <- day_hourly(result, 2L)
  assert_close(
    gut_boundaries_kj(day_2),
    gut_boundaries_kj(day_1),
    cycle_tolerance_kj,
    paste(fixture$scenario_id, "measured gut-cycle repetition")
  )
  if (
    !identical(
      day_1$gut_available_energy_end_kj[[24L]],
      day_2$gut_available_energy_start_kj[[1L]]
    ) ||
      !identical(
        day_1$body_energy_reserve_end_kj[[24L]],
        day_2$body_energy_reserve_start_kj[[1L]]
      ) ||
      any(day_1$body_energy_reserve_start_kj < 0) ||
      any(day_1$body_energy_reserve_end_kj < 0) ||
      any(day_2$body_energy_reserve_start_kj < 0) ||
      any(day_2$body_energy_reserve_end_kj < 0)
  ) {
    stop(
      sprintf(
        "Carry-over or body-path feasibility failed for `%s`.",
        fixture$scenario_id
      ),
      call. = FALSE
    )
  }

  invisible(NULL)
}

assert_neutral_fixture <- function(fixture) {
  result <- fixture$result
  if (
    !identical(
      result$daily$total_prescribed_ingested_available_energy_kj,
      rep(2400, 2L)
    ) ||
      !identical(
        result$daily$total_maintenance_expenditure_kj,
        rep(2400, 2L)
      )
  ) {
    stop(
      sprintf("Exact daily forcing failed for `%s`.", fixture$scenario_id),
      call. = FALSE
    )
  }

  for (measurement_day in 1:2) {
    daily <- day_daily(result, measurement_day)
    tolerance <- daily_tolerances(result, measurement_day)
    assert_close(
      daily$gut_available_energy_final_kj,
      daily$gut_available_energy_initial_kj,
      tolerance[["cycle_tolerance_kj"]],
      paste(fixture$scenario_id, "daily gut-cycle closure")
    )
    assert_close(
      daily$total_assimilated_energy_kj,
      daily$total_prescribed_ingested_available_energy_kj,
      tolerance[["assimilation_total_tolerance_kj"]],
      paste(fixture$scenario_id, "daily assimilation")
    )
    assert_close(
      daily$observed_body_energy_change_kj,
      0,
      tolerance[["body_neutrality_tolerance_kj"]],
      paste(fixture$scenario_id, "daily body neutrality")
    )
  }

  invisible(NULL)
}

write_png <- function(path, width, height, draw) {
  grDevices::png(
    filename = path,
    width = width,
    height = height,
    units = "px",
    pointsize = 14,
    bg = "white",
    res = 150
  )
  device_number <- grDevices::dev.cur()
  on.exit(
    if (device_number %in% grDevices::dev.list()) {
      grDevices::dev.off(device_number)
    },
    add = TRUE
  )
  draw()
  grDevices::dev.off(device_number)
  on.exit(NULL)
  invisible(path)
}

csv_column_class <- function(value) {
  switch(
    typeof(value),
    double = "numeric",
    integer = "integer",
    logical = "logical",
    character = "character",
    stop("The review table contains an unsupported column type.", call. = FALSE)
  )
}

encode_csv_double <- function(value) {
  if (is.na(value)) {
    return("")
  }
  if (!is.finite(value)) {
    stop("A review-table double is not finite.", call. = FALSE)
  }
  for (precision in c(17L, 18L, 16L, 19L, 20L, 21L, 22L, 15L)) {
    encoded <- sprintf(paste0("%.", precision, "g"), value)
    if (identical(as.double(encoded), value)) {
      return(encoded)
    }
  }
  encoded <- sprintf("%a", value)
  if (identical(as.double(encoded), value)) {
    return(encoded)
  }
  stop("A review-table double cannot be encoded bit-exactly.", call. = FALSE)
}

encode_csv_column <- function(value) {
  encoded <- if (is.double(value)) {
    vapply(
      value,
      encode_csv_double,
      character(1L),
      USE.NAMES = FALSE
    )
  } else {
    ifelse(is.na(value), "", as.character(value))
  }
  if (any(grepl("[,\"\r\n]", encoded))) {
    stop("A review-table field requires unsupported CSV quoting.", call. = FALSE)
  }
  encoded
}

write_full_precision_csv <- function(value, path) {
  if (
    !identical(class(value), "data.frame") ||
      any(grepl("[,\"\r\n]", names(value)))
  ) {
    stop("The review table cannot be serialized safely.", call. = FALSE)
  }
  encoded <- as.data.frame(
    lapply(value, encode_csv_column),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  write.table(
    encoded,
    file = path,
    sep = ",",
    row.names = FALSE,
    col.names = TRUE,
    quote = FALSE,
    na = ""
  )
  invisible(path)
}

assert_round_trip <- function(path, expected) {
  observed <- read.csv(
    path,
    stringsAsFactors = FALSE,
    check.names = FALSE,
    na.strings = "",
    quote = "",
    comment.char = "",
    colClasses = vapply(
      expected,
      csv_column_class,
      character(1L),
      USE.NAMES = FALSE
    )
  )
  if (!identical(observed, expected)) {
    stop(
      sprintf("Full-precision CSV round trip failed for `%s`.", basename(path)),
      call. = FALSE
    )
  }
  invisible(NULL)
}

main <- function() {
  arguments <- commandArgs(trailingOnly = TRUE)
  if (
    length(arguments) != 1L ||
      is.na(arguments[[1L]]) ||
      !nzchar(arguments[[1L]])
  ) {
    stop("Supply exactly one non-empty output-directory argument.", call. = FALSE)
  }
  destination <- arguments[[1L]]

  if (path_exists(destination)) {
    validate_destination(destination, require_exact = FALSE)
  }

  required_exports <- c(
    "derive_ingested_available_energy_schedule",
    "new_body_energy_parameters",
    "new_body_energy_state",
    "new_dry_matter_intake_schedule",
    "new_food_energy_parameters",
    "new_gut_energy_parameters",
    "new_gut_energy_state",
    "run_gut_body_energy_reference_cycle"
  )
  missing_exports <- setdiff(
    required_exports,
    getNamespaceExports("herbivoreTTR")
  )
  if (length(missing_exports) != 0L) {
    stop(
      sprintf(
        "The installed package lacks required export(s): %s.",
        paste(missing_exports, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  old_options <- options(digits = 17)
  on.exit(options(old_options), add = TRUE)

  fixtures <- list(
    zero = new_fixture("zero", rep(0, 24L)),
    constant = new_fixture("constant", rep(0.010, 24L)),
    concentrated_late = new_fixture(
      "concentrated_late",
      c(rep(0, 18L), rep(0.040, 6L))
    )
  )
  invisible(lapply(fixtures, assert_result_contract))

  dry_matter_total_tolerance <- 100 * .Machine$double.eps
  assert_close(
    sum(
      fixtures$constant$dry_matter_schedule$
        prescribed_dry_matter_intake_kg_dm_h
    ),
    0.24,
    dry_matter_total_tolerance,
    "constant daily dry-matter intake"
  )
  assert_close(
    sum(
      fixtures$concentrated_late$dry_matter_schedule$
        prescribed_dry_matter_intake_kg_dm_h
    ),
    0.24,
    dry_matter_total_tolerance,
    "concentrated daily dry-matter intake"
  )

  zero_daily <- fixtures$zero$result$daily
  if (
    !identical(
      zero_daily$total_prescribed_ingested_available_energy_kj,
      rep(0, 2L)
    ) ||
      !identical(zero_daily$total_assimilated_energy_kj, rep(0, 2L)) ||
      !identical(
        zero_daily$total_maintenance_expenditure_kj,
        rep(2400, 2L)
      ) ||
      !identical(
        zero_daily$observed_body_energy_change_kj,
        rep(-2400, 2L)
      )
  ) {
    stop("The zero-intake deficit fixture failed.", call. = FALSE)
  }
  assert_neutral_fixture(fixtures$constant)
  assert_neutral_fixture(fixtures$concentrated_late)

  constant_result <- fixtures$constant$result
  concentrated_result <- fixtures$concentrated_late$result
  for (measurement_day in 1:2) {
    constant_daily <- day_daily(constant_result, measurement_day)
    concentrated_daily <- day_daily(concentrated_result, measurement_day)
    constant_tolerance <- daily_tolerances(
      constant_result,
      measurement_day
    )
    concentrated_tolerance <- daily_tolerances(
      concentrated_result,
      measurement_day
    )
    if (
      !identical(
        constant_daily$total_prescribed_ingested_available_energy_kj,
        concentrated_daily$total_prescribed_ingested_available_energy_kj
      ) ||
        !identical(
          constant_daily$total_maintenance_expenditure_kj,
          concentrated_daily$total_maintenance_expenditure_kj
        )
    ) {
      stop("Timing-equivalent prescribed daily totals differ.", call. = FALSE)
    }
    assert_close(
      constant_daily$total_assimilated_energy_kj,
      concentrated_daily$total_assimilated_energy_kj,
      constant_tolerance[["assimilation_total_tolerance_kj"]] +
        concentrated_tolerance[["assimilation_total_tolerance_kj"]],
      "timing-equivalent daily assimilation"
    )
    assert_close(
      constant_daily$observed_gut_energy_change_kj,
      concentrated_daily$observed_gut_energy_change_kj,
      constant_tolerance[["cycle_tolerance_kj"]] +
        concentrated_tolerance[["cycle_tolerance_kj"]],
      "timing-equivalent daily gut change"
    )
    assert_close(
      constant_daily$observed_body_energy_change_kj,
      concentrated_daily$observed_body_energy_change_kj,
      constant_tolerance[["body_neutrality_tolerance_kj"]] +
        concentrated_tolerance[["body_neutrality_tolerance_kj"]],
      "timing-equivalent daily body change"
    )
  }
  constant_hourly <- day_hourly(constant_result, 1L)
  concentrated_hourly <- day_hourly(concentrated_result, 1L)
  if (
    max(abs(
      constant_hourly$gut_available_energy_start_kj -
        concentrated_hourly$gut_available_energy_start_kj
    )) <= tail(
      constant_result$convergence$realized_convergence_tolerance_kj,
      1L
    ) +
      tail(
        concentrated_result$convergence$
          realized_convergence_tolerance_kj,
        1L
      ) ||
      identical(
        constant_hourly$assimilated_energy_kj_h,
        concentrated_hourly$assimilated_energy_kj_h
      ) ||
      identical(
        constant_hourly$body_energy_reserve_end_kj,
        concentrated_hourly$body_energy_reserve_end_kj
      )
  ) {
    stop("The timing fixtures do not have distinct hourly paths.", call. = FALSE)
  }

  convergence_table <- do.call(
    rbind,
    lapply(fixtures, function(fixture) {
      data.frame(
        scenario_id = fixture$scenario_id,
        fixture$result$convergence,
        stringsAsFactors = FALSE,
        check.names = FALSE
      )
    })
  )
  row.names(convergence_table) <- NULL
  daily_table <- do.call(
    rbind,
    lapply(fixtures, function(fixture) {
      data.frame(
        scenario_id = fixture$scenario_id,
        fixture$result$daily,
        stringsAsFactors = FALSE,
        check.names = FALSE
      )
    })
  )
  row.names(daily_table) <- NULL
  hourly_table <- do.call(
    rbind,
    lapply(fixtures, function(fixture) {
      data.frame(
        scenario_id = fixture$scenario_id,
        fixture$result$hourly,
        stringsAsFactors = FALSE,
        check.names = FALSE
      )
    })
  )
  row.names(hourly_table) <- NULL

  if (
    !identical(convergence_table$scenario_id, rep(
      names(fixtures),
      lengths(lapply(fixtures, function(x) x$result$convergence$burn_in_day))
    )) ||
      !identical(daily_table$scenario_id, rep(names(fixtures), each = 2L)) ||
      !identical(hourly_table$scenario_id, rep(names(fixtures), each = 48L))
  ) {
    stop("The review-table scenario keys are incomplete.", call. = FALSE)
  }

  stage <- tempfile(pattern = "rebuild005-review-pack-")
  if (!dir.create(stage, recursive = FALSE, showWarnings = FALSE)) {
    stop("Could not create the review-pack staging directory.", call. = FALSE)
  }
  on.exit(unlink(stage, recursive = TRUE, force = TRUE), add = TRUE)

  write_full_precision_csv(
    convergence_table,
    file.path(stage, "table-1-convergence.csv")
  )
  write_full_precision_csv(
    daily_table,
    file.path(stage, "table-2-daily-summary.csv")
  )
  write_full_precision_csv(
    hourly_table,
    file.path(stage, "table-3-hourly-ledgers.csv")
  )
  assert_round_trip(
    file.path(stage, "table-1-convergence.csv"),
    convergence_table
  )
  assert_round_trip(
    file.path(stage, "table-2-daily-summary.csv"),
    daily_table
  )
  assert_round_trip(
    file.path(stage, "table-3-hourly-ledgers.csv"),
    hourly_table
  )

  scenario_colors <- c(
    zero = "#000000",
    constant = "#0072B2",
    concentrated_late = "#D55E00"
  )
  scenario_labels <- c(
    zero = "Zero intake",
    constant = "Constant intake",
    concentrated_late = "Concentrated late feeding"
  )

  write_png(
    file.path(stage, "figure-1-burn-in-convergence.png"),
    width = 2100,
    height = 900,
    draw = function() {
      old_par <- graphics::par(
        mfrow = c(1, 3),
        mar = c(4.7, 5.2, 3.2, 1.2),
        oma = c(2.5, 0, 3.5, 0),
        las = 1
      )
      on.exit(graphics::par(old_par), add = TRUE)

      for (scenario_id in names(fixtures)) {
        convergence <- fixtures[[scenario_id]]$result$convergence
        trajectory_difference <-
          convergence$max_abs_previous_day_trajectory_difference_kj
        cycle_boundary_change <- abs(
          convergence$cycle_boundary_change_kj
        )
        tolerance <- convergence$realized_convergence_tolerance_kj
        positive_values <- c(
          trajectory_difference[
            is.finite(trajectory_difference) & trajectory_difference > 0
          ],
          cycle_boundary_change[
            is.finite(cycle_boundary_change) & cycle_boundary_change > 0
          ],
          tolerance[is.finite(tolerance) & tolerance > 0]
        )
        plot_floor <- min(positive_values) / 10
        plotted_trajectory_difference <- trajectory_difference
        plotted_trajectory_difference[
          is.finite(plotted_trajectory_difference) &
            plotted_trajectory_difference == 0
        ] <- plot_floor
        plotted_cycle_boundary_change <- cycle_boundary_change
        plotted_cycle_boundary_change[
          is.finite(plotted_cycle_boundary_change) &
            plotted_cycle_boundary_change == 0
        ] <- plot_floor
        plotted_tolerance <- tolerance
        plotted_tolerance[
          is.finite(plotted_tolerance) & plotted_tolerance == 0
        ] <- plot_floor
        y_limits <- range(
          c(
            plotted_trajectory_difference,
            plotted_cycle_boundary_change,
            plotted_tolerance
          ),
          finite = TRUE
        )

        graphics::plot(
          convergence$burn_in_day,
          plotted_trajectory_difference,
          type = "n",
          log = "y",
          ylim = y_limits,
          xlab = "Burn-in day",
          ylab = "Criterion value or tolerance (kJ; log scale)",
          main = scenario_labels[[scenario_id]],
          xaxt = "n"
        )
        graphics::axis(
          1,
          at = convergence$burn_in_day,
          labels = convergence$burn_in_day
        )
        graphics::lines(
          convergence$burn_in_day,
          plotted_cycle_boundary_change,
          col = scenario_colors[[scenario_id]],
          lty = 3,
          lwd = 2.5
        )
        graphics::points(
          convergence$burn_in_day,
          plotted_cycle_boundary_change,
          col = scenario_colors[[scenario_id]],
          pch = ifelse(
            !is.na(cycle_boundary_change) & cycle_boundary_change == 0,
            2,
            17
          ),
          cex = 1.25
        )
        graphics::lines(
          convergence$burn_in_day,
          plotted_trajectory_difference,
          col = scenario_colors[[scenario_id]],
          lwd = 2.5
        )
        graphics::points(
          convergence$burn_in_day,
          plotted_trajectory_difference,
          col = scenario_colors[[scenario_id]],
          pch = ifelse(
            !is.na(trajectory_difference) & trajectory_difference == 0,
            1,
            16
          ),
          cex = 1.0
        )
        graphics::lines(
          convergence$burn_in_day,
          plotted_tolerance,
          col = "#666666",
          lty = 2,
          lwd = 2.5
        )
        graphics::points(
          convergence$burn_in_day,
          plotted_tolerance,
          col = "#666666",
          pch = ifelse(
            !is.na(tolerance) & tolerance == 0,
            0,
            15
          ),
          cex = 0.9
        )
        graphics::legend(
          if (identical(scenario_id, "zero")) "topleft" else "topright",
          legend = c(
            "Successive-day 25-boundary maximum",
            "Absolute cycle-boundary change",
            "Realized convergence tolerance",
            "Open series marker at floor = exact zero"
          ),
          col = c(
            scenario_colors[[scenario_id]],
            scenario_colors[[scenario_id]],
            "#666666",
            "#000000"
          ),
          lty = c(1, 3, 2, 0),
          pch = c(16, 17, 15, NA),
          lwd = c(2.5, 2.5, 2.5, NA),
          bty = "n",
          cex = 0.72
        )
      }
      graphics::mtext(
        "Synthetic Goal 005 gut-only burn-in convergence",
        side = 3,
        outer = TRUE,
        line = 1.2,
        font = 2,
        cex = 1.15
      )
      graphics::mtext(
        paste(
          "Successive-day criterion is NA on day 1;",
          "exact zeros use open series markers at the panel floor"
        ),
        side = 1,
        outer = TRUE,
        line = 0.6,
        cex = 0.82
      )
    }
  )

  elapsed_rate_time_h <- 0:48
  elapsed_boundary_time_h <- 0:48
  ingestion_matrix <- do.call(
    cbind,
    lapply(fixtures, function(fixture) {
      rates <- fixture$result$hourly$
        prescribed_ingested_available_energy_kj_h
      c(rates, tail(rates, 1L))
    })
  )
  assimilation_matrix <- do.call(
    cbind,
    lapply(fixtures, function(fixture) {
      rates <- fixture$result$hourly$assimilated_energy_kj_h
      c(rates, tail(rates, 1L))
    })
  )
  gut_matrix <- do.call(
    cbind,
    lapply(fixtures, function(fixture) {
      gut_boundaries_kj(fixture$result$hourly)
    })
  )
  body_matrix <- do.call(
    cbind,
    lapply(fixtures, function(fixture) {
      body_boundaries_kj(fixture$result$hourly)
    })
  )
  colnames(ingestion_matrix) <- names(fixtures)
  colnames(assimilation_matrix) <- names(fixtures)
  colnames(gut_matrix) <- names(fixtures)
  colnames(body_matrix) <- names(fixtures)

  draw_series <- function(
    x,
    values,
    x_label,
    y_label,
    title,
    step = FALSE,
    include_legend = FALSE
  ) {
    graphics::matplot(
      x,
      values,
      type = if (step) "s" else "l",
      lty = c(1, 2, 3),
      lwd = 2.7,
      col = scenario_colors[colnames(values)],
      xlim = c(0, 48),
      xlab = x_label,
      ylab = y_label,
      main = title
    )
    graphics::abline(v = 24, col = "#888888", lty = 3)
    if (include_legend) {
      graphics::legend(
        "topleft",
        legend = scenario_labels[colnames(values)],
        col = scenario_colors[colnames(values)],
        lty = c(1, 2, 3),
        lwd = 2.7,
        bty = "n",
        cex = 0.84
      )
    }
  }

  write_png(
    file.path(stage, "figure-2-measured-reference-cycles.png"),
    width = 2100,
    height = 1500,
    draw = function() {
      old_par <- graphics::par(
        mfrow = c(2, 2),
        mar = c(4.8, 5.4, 3.0, 1.2),
        oma = c(0, 0, 3.5, 0),
        las = 1
      )
      on.exit(graphics::par(old_par), add = TRUE)
      draw_series(
        elapsed_rate_time_h,
        ingestion_matrix,
        "Elapsed measurement time (h)",
        "Prescribed ingestion (kJ h^-1)",
        "Prescribed gut input",
        step = TRUE,
        include_legend = TRUE
      )
      draw_series(
        elapsed_rate_time_h,
        assimilation_matrix,
        "Elapsed measurement time (h)",
        "Assimilation (kJ h^-1)",
        "Gut release to body"
      )
      draw_series(
        elapsed_boundary_time_h,
        gut_matrix,
        "Elapsed measurement time (h)",
        "Gut available energy (kJ)",
        "Gut boundary stock"
      )
      draw_series(
        elapsed_boundary_time_h,
        body_matrix,
        "Elapsed measurement time (h)",
        "Body energy reserve (kJ)",
        "Body boundary stock"
      )
      graphics::mtext(
        "Synthetic Goal 005 measured reference cycles; day boundary at 24 h",
        side = 3,
        outer = TRUE,
        line = 1.2,
        font = 2,
        cex = 1.15
      )
    }
  )

  staged_entries <- list.files(
    stage,
    all.files = TRUE,
    full.names = FALSE,
    no.. = TRUE
  )
  if (
    !identical(
      sort(staged_entries, method = "radix"),
      sort(declared_files, method = "radix")
    ) ||
      any(file.info(file.path(stage, staged_entries))$isdir)
  ) {
    stop("The staged review-pack file set is invalid.", call. = FALSE)
  }

  if (!path_exists(destination)) {
    if (!dir.create(destination, recursive = TRUE, showWarnings = FALSE)) {
      stop("Could not create the review-pack destination.", call. = FALSE)
    }
  }
  validate_destination(destination, require_exact = FALSE)
  if (file.access(destination, mode = 2L) != 0L) {
    stop("The review-pack destination is not writable.", call. = FALSE)
  }
  for (entry in declared_files) {
    copied <- file.copy(
      from = file.path(stage, entry),
      to = file.path(destination, entry),
      overwrite = TRUE,
      copy.mode = TRUE,
      copy.date = FALSE
    )
    if (!isTRUE(copied)) {
      stop(sprintf("Failed to publish declared file `%s`.", entry), call. = FALSE)
    }
  }
  validate_destination(destination, require_exact = TRUE)

  cat(sprintf("Generated synthetic Goal 005 review pack at %s\n", destination))
  cat(sprintf("Files: %d (exact declared set)\n", length(declared_files)))
  invisible(NULL)
}

main()
