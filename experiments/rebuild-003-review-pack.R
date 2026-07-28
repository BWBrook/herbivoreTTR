declared_files <- c(
  "artifact-manifest.sha256",
  "figure-1-equilibrium-and-initialization.png",
  "figure-2-pulse-response.png",
  "generation-metadata.txt",
  "source-manifest.sha256",
  "table-1-daily-summary.csv",
  "table-2-hourly-checkpoints.csv",
  "table-3-full-hourly-ledgers.csv"
)

hourly_schema <- c(
  "hour_of_day",
  "time_start_h",
  "time_end_h",
  "gut_available_energy_start_kj",
  "prescribed_ingested_available_energy_kj_h",
  "gut_release_fraction_h",
  "assimilated_energy_kj_h",
  "prescribed_ingested_available_energy_kj",
  "assimilated_energy_kj",
  "gut_energy_change_kj",
  "gut_available_energy_end_kj",
  "gut_energy_balance_residual_kj",
  "body_energy_reserve_start_kj",
  "maintenance_expenditure_kj_h",
  "maintenance_expenditure_kj",
  "body_energy_change_kj",
  "body_energy_reserve_end_kj",
  "body_energy_balance_residual_kj",
  "total_system_energy_start_kj",
  "total_system_energy_end_kj",
  "system_energy_balance_residual_kj"
)

daily_schema <- c(
  "gut_available_energy_initial_kj",
  "total_prescribed_ingested_available_energy_kj",
  "total_assimilated_energy_kj",
  "expected_gut_energy_change_kj",
  "observed_gut_energy_change_kj",
  "gut_available_energy_final_kj",
  "gut_energy_balance_residual_kj",
  "body_energy_reserve_initial_kj",
  "total_maintenance_expenditure_kj",
  "expected_body_energy_change_kj",
  "observed_body_energy_change_kj",
  "body_energy_reserve_final_kj",
  "body_energy_balance_residual_kj",
  "total_system_energy_initial_kj",
  "expected_total_system_energy_change_kj",
  "observed_total_system_energy_change_kj",
  "total_system_energy_final_kj",
  "system_energy_balance_residual_kj",
  "body_energy_status"
)

checkpoint_schema <- c(
  "scenario_id",
  "hour_of_day",
  "time_start_h",
  "time_end_h",
  "prescribed_ingested_available_energy_kj_h",
  "assimilated_energy_kj_h",
  "gut_available_energy_start_kj",
  "gut_available_energy_end_kj",
  "body_energy_reserve_start_kj",
  "body_energy_reserve_end_kj",
  "system_energy_balance_residual_kj"
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
    entry_path <- file.path(destination, entry)
    if (
      is_symbolic_link(entry_path) ||
        !file_test("-f", entry_path) ||
        isTRUE(file.info(entry_path)$isdir)
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

git_output <- function(repository, arguments, allow_empty = FALSE) {
  output <- suppressWarnings(
    system2(
      "git",
      args = c("-C", repository, arguments),
      stdout = TRUE,
      stderr = TRUE
    )
  )
  exit_status <- attr(output, "status", exact = TRUE)
  if (!is.null(exit_status) && exit_status != 0L) {
    stop(
      sprintf(
        "Read-only git command failed: git -C %s %s\n%s",
        repository,
        paste(arguments, collapse = " "),
        paste(output, collapse = "\n")
      ),
      call. = FALSE
    )
  }
  if (!allow_empty && length(output) == 0L) {
    stop("A read-only git command returned no output.", call. = FALSE)
  }
  output
}

sha256_value <- function(path) {
  if (
    is_symbolic_link(path) ||
      !file_test("-f", path) ||
      isTRUE(file.info(path)$isdir)
  ) {
    stop(sprintf("Cannot hash non-regular file `%s`.", path), call. = FALSE)
  }

  output <- suppressWarnings(
    system2(
      "shasum",
      args = c("-a", "256", path),
      stdout = TRUE,
      stderr = TRUE
    )
  )
  exit_status <- attr(output, "status", exact = TRUE)
  if (
    (!is.null(exit_status) && exit_status != 0L) ||
      length(output) != 1L ||
      !grepl("^[0-9a-f]{64}[[:space:]]", output)
  ) {
    stop(sprintf("SHA-256 calculation failed for `%s`.", path), call. = FALSE)
  }

  substring(output, 1L, 64L)
}

manifest_lines <- function(actual_paths, displayed_paths) {
  if (
    length(actual_paths) != length(displayed_paths) ||
      anyDuplicated(displayed_paths)
  ) {
    stop("Manifest path vectors are invalid.", call. = FALSE)
  }

  vapply(
    seq_along(actual_paths),
    function(index) {
      sprintf(
        "%s  %s",
        sha256_value(actual_paths[[index]]),
        displayed_paths[[index]]
      )
    },
    character(1L),
    USE.NAMES = FALSE
  )
}

accounting_tolerance <- function(...) {
  values <- unlist(list(...), use.names = FALSE)
  100 * .Machine$double.eps * max(1, abs(values))
}

assert_close <- function(actual, expected, label) {
  tolerance <- accounting_tolerance(actual, expected)
  if (
    length(actual) != length(expected) ||
      any(!is.finite(actual)) ||
      any(!is.finite(expected)) ||
      any(abs(actual - expected) > tolerance)
  ) {
    stop(sprintf("Analytical assertion failed: %s.", label), call. = FALSE)
  }
  invisible(NULL)
}

assert_result_contract <- function(result, scenario_id) {
  if (
    !identical(names(result), c("hourly", "daily")) ||
      !identical(dim(result$hourly), c(24L, length(hourly_schema))) ||
      !identical(names(result$hourly), hourly_schema) ||
      !identical(dim(result$daily), c(1L, length(daily_schema))) ||
      !identical(names(result$daily), daily_schema)
  ) {
    stop(
      sprintf("Output schema assertion failed for `%s`.", scenario_id),
      call. = FALSE
    )
  }

  hourly <- result$hourly
  daily <- result$daily
  hourly_gut_tolerance <- 100 * .Machine$double.eps * pmax(
    1,
    abs(hourly$gut_available_energy_start_kj),
    abs(hourly$gut_available_energy_end_kj),
    abs(hourly$prescribed_ingested_available_energy_kj),
    abs(hourly$assimilated_energy_kj)
  )
  hourly_body_tolerance <- 100 * .Machine$double.eps * pmax(
    1,
    abs(hourly$body_energy_reserve_start_kj),
    abs(hourly$body_energy_reserve_end_kj),
    abs(hourly$assimilated_energy_kj),
    abs(hourly$maintenance_expenditure_kj)
  )
  hourly_system_tolerance <- 100 * .Machine$double.eps * pmax(
    1,
    abs(hourly$gut_available_energy_start_kj),
    abs(hourly$gut_available_energy_end_kj),
    abs(hourly$body_energy_reserve_start_kj),
    abs(hourly$body_energy_reserve_end_kj),
    abs(hourly$prescribed_ingested_available_energy_kj),
    abs(hourly$assimilated_energy_kj),
    abs(hourly$maintenance_expenditure_kj)
  )
  if (
    any(abs(hourly$gut_energy_balance_residual_kj) > hourly_gut_tolerance) ||
      any(
        abs(hourly$body_energy_balance_residual_kj) >
          hourly_body_tolerance
      ) ||
      any(
        abs(hourly$system_energy_balance_residual_kj) >
          hourly_system_tolerance
      )
  ) {
    stop(
      sprintf("Hourly accounting assertion failed for `%s`.", scenario_id),
      call. = FALSE
    )
  }

  daily_gut_tolerance <- 100 * .Machine$double.eps * max(
    1,
    abs(daily$gut_available_energy_initial_kj),
    abs(daily$gut_available_energy_final_kj),
    sum(abs(hourly$prescribed_ingested_available_energy_kj)),
    sum(abs(hourly$assimilated_energy_kj))
  )
  daily_body_tolerance <- 100 * .Machine$double.eps * max(
    1,
    abs(daily$body_energy_reserve_initial_kj),
    abs(daily$body_energy_reserve_final_kj),
    sum(abs(hourly$assimilated_energy_kj)),
    sum(abs(hourly$maintenance_expenditure_kj))
  )
  daily_system_tolerance <- 100 * .Machine$double.eps * max(
    1,
    abs(daily$gut_available_energy_initial_kj),
    abs(daily$gut_available_energy_final_kj),
    abs(daily$body_energy_reserve_initial_kj),
    abs(daily$body_energy_reserve_final_kj),
    sum(abs(hourly$prescribed_ingested_available_energy_kj)),
    sum(abs(hourly$assimilated_energy_kj)),
    sum(abs(hourly$maintenance_expenditure_kj))
  )
  if (
    abs(daily$gut_energy_balance_residual_kj) > daily_gut_tolerance ||
      abs(daily$body_energy_balance_residual_kj) > daily_body_tolerance ||
      abs(daily$system_energy_balance_residual_kj) >
        daily_system_tolerance
  ) {
    stop(
      sprintf("Daily accounting assertion failed for `%s`.", scenario_id),
      call. = FALSE
    )
  }

  invisible(NULL)
}

run_fixture <- function(initial_gut_energy_kj, ingestion_kj_h, maintenance_kj_h) {
  herbivoreTTR::run_gut_body_energy_day(
    initial_gut_state = herbivoreTTR::new_gut_energy_state(
      initial_gut_energy_kj
    ),
    initial_body_state = herbivoreTTR::new_body_energy_state(5000),
    gut_parameters = herbivoreTTR::new_gut_energy_parameters(0.25),
    body_parameters = herbivoreTTR::new_body_energy_parameters(
      maintenance_kj_h
    ),
    schedule = herbivoreTTR::new_ingested_available_energy_schedule(
      hour_of_day = 0:23,
      prescribed_ingested_available_energy_kj_h = ingestion_kj_h
    ),
    routine_activity_schedule =
      herbivoreTTR::new_routine_activity_expenditure_schedule(
        0:23,
        rep(0, 24L)
      )
  )
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

main <- function() {
  arguments <- commandArgs(trailingOnly = TRUE)
  expected_repository <- "/Users/bwbrook/git/herbivoreTTR"
  expected_destination <-
    "/Users/bwbrook/work/herbivoreTTR-review/goal-003"

  if (
    length(arguments) != 1L ||
      !identical(arguments[[1L]], expected_destination)
  ) {
    stop(
      sprintf(
        "Supply exactly one destination argument: %s",
        expected_destination
      ),
      call. = FALSE
    )
  }
  destination <- arguments[[1L]]

  repository <- normalizePath(getwd(), mustWork = TRUE)
  if (!identical(repository, expected_repository)) {
    stop(
      sprintf("Run this script from repository root `%s`.", expected_repository),
      call. = FALSE
    )
  }
  if (
    !file_test("-f", file.path(repository, "DESCRIPTION")) ||
      !dir.exists(file.path(repository, ".git"))
  ) {
    stop("The expected source repository is incomplete.", call. = FALSE)
  }
  description_fields <- read.dcf(
    file.path(repository, "DESCRIPTION"),
    fields = "Package"
  )
  if (!identical(unname(description_fields[[1L]]), "herbivoreTTR")) {
    stop("The working directory is not the herbivoreTTR package root.", call. = FALSE)
  }

  if (path_exists(destination)) {
    validate_destination(destination, require_exact = FALSE)
  }

  required_exports <- c(
    "new_body_energy_parameters",
    "new_body_energy_state",
    "new_gut_energy_parameters",
    "new_gut_energy_state",
    "new_ingested_available_energy_schedule",
    "run_gut_body_energy_day"
  )
  installed_exports <- getNamespaceExports("herbivoreTTR")
  missing_exports <- setdiff(required_exports, installed_exports)
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
    equilibrium = run_fixture(
      initial_gut_energy_kj = 400,
      ingestion_kj_h = rep(100, 24L),
      maintenance_kj_h = 100
    ),
    empty_start = run_fixture(
      initial_gut_energy_kj = 0,
      ingestion_kj_h = rep(100, 24L),
      maintenance_kj_h = 100
    ),
    pulse = run_fixture(
      initial_gut_energy_kj = 0,
      ingestion_kj_h = c(400, rep(0, 23L)),
      maintenance_kj_h = 0
    )
  )
  invisible(Map(assert_result_contract, fixtures, names(fixtures)))

  equilibrium <- fixtures$equilibrium
  assert_close(
    equilibrium$hourly$gut_available_energy_end_kj,
    rep(400, 24L),
    "equilibrium gut stock"
  )
  assert_close(
    equilibrium$hourly$assimilated_energy_kj_h,
    rep(100, 24L),
    "equilibrium assimilation"
  )
  assert_close(
    equilibrium$hourly$body_energy_reserve_end_kj,
    rep(5000, 24L),
    "equilibrium body reserve"
  )

  empty_start <- fixtures$empty_start
  expected_empty_start_kj <-
    400 * (1 - 0.75^empty_start$hourly$time_start_h)
  expected_empty_end_kj <-
    400 * (1 - 0.75^empty_start$hourly$time_end_h)
  assert_close(
    empty_start$hourly$gut_available_energy_start_kj,
    expected_empty_start_kj,
    "empty-start opening recurrence"
  )
  assert_close(
    empty_start$hourly$gut_available_energy_end_kj,
    expected_empty_end_kj,
    "empty-start closing recurrence"
  )
  assert_close(
    empty_start$hourly$body_energy_reserve_end_kj,
    5000 - expected_empty_end_kj,
    "empty-start body-gut complement"
  )
  assert_close(
    empty_start$daily$total_system_energy_final_kj,
    5000,
    "empty-start combined energy"
  )

  pulse <- fixtures$pulse
  assert_close(
    pulse$hourly$assimilated_energy_kj_h[1:4],
    c(0, 100, 75, 56.25),
    "pulse delay checkpoints"
  )
  assert_close(
    pulse$hourly$gut_available_energy_end_kj,
    400 * 0.75^c(0, 1:23),
    "pulse gut-stock decay"
  )
  assert_close(
    pulse$hourly$total_system_energy_end_kj,
    rep(5400, 24L),
    "pulse combined energy"
  )

  daily_summary <- do.call(
    rbind,
    lapply(names(fixtures), function(scenario_id) {
      data.frame(
        scenario_id = scenario_id,
        fixtures[[scenario_id]]$daily,
        stringsAsFactors = FALSE,
        check.names = FALSE
      )
    })
  )
  row.names(daily_summary) <- NULL

  full_hourly_ledgers <- do.call(
    rbind,
    lapply(names(fixtures), function(scenario_id) {
      data.frame(
        scenario_id = scenario_id,
        fixtures[[scenario_id]]$hourly,
        stringsAsFactors = FALSE,
        check.names = FALSE
      )
    })
  )
  row.names(full_hourly_ledgers) <- NULL

  checkpoint_hours <- c(0L, 1L, 2L, 3L, 6L, 12L, 18L, 23L)
  hourly_checkpoints <- full_hourly_ledgers[
    full_hourly_ledgers$hour_of_day %in% checkpoint_hours,
    checkpoint_schema,
    drop = FALSE
  ]
  row.names(hourly_checkpoints) <- NULL

  expected_scenario_rows <- rep(names(fixtures), each = 24L)
  if (
    !identical(names(daily_summary), c("scenario_id", daily_schema)) ||
      !identical(dim(daily_summary), c(3L, length(daily_schema) + 1L)) ||
      !identical(daily_summary$scenario_id, names(fixtures)) ||
      !identical(
        names(full_hourly_ledgers),
        c("scenario_id", hourly_schema)
      ) ||
      !identical(
        dim(full_hourly_ledgers),
        c(72L, length(hourly_schema) + 1L)
      ) ||
      !identical(full_hourly_ledgers$scenario_id, expected_scenario_rows) ||
      !identical(names(hourly_checkpoints), checkpoint_schema) ||
      !identical(dim(hourly_checkpoints), c(24L, length(checkpoint_schema))) ||
      !identical(
        hourly_checkpoints$scenario_id,
        rep(names(fixtures), each = length(checkpoint_hours))
      ) ||
      !identical(
        hourly_checkpoints$hour_of_day,
        rep(checkpoint_hours, times = length(fixtures))
      )
  ) {
    stop("The review-pack table contract is not satisfied.", call. = FALSE)
  }

  stage <- tempfile(pattern = "rebuild003-review-pack-")
  if (!dir.create(stage, recursive = FALSE, showWarnings = FALSE)) {
    stop("Could not create the review-pack staging directory.", call. = FALSE)
  }
  on.exit(unlink(stage, recursive = TRUE, force = TRUE), add = TRUE)

  write.csv(
    daily_summary,
    file = file.path(stage, "table-1-daily-summary.csv"),
    row.names = FALSE,
    na = ""
  )
  write.csv(
    hourly_checkpoints,
    file = file.path(stage, "table-2-hourly-checkpoints.csv"),
    row.names = FALSE,
    na = ""
  )
  write.csv(
    full_hourly_ledgers,
    file = file.path(stage, "table-3-full-hourly-ledgers.csv"),
    row.names = FALSE,
    na = ""
  )

  time_h <- 0:24
  equilibrium_gut_kj <- c(
    equilibrium$daily$gut_available_energy_initial_kj,
    equilibrium$hourly$gut_available_energy_end_kj
  )
  empty_gut_kj <- c(
    empty_start$daily$gut_available_energy_initial_kj,
    empty_start$hourly$gut_available_energy_end_kj
  )
  equilibrium_body_kj <- c(
    equilibrium$daily$body_energy_reserve_initial_kj,
    equilibrium$hourly$body_energy_reserve_end_kj
  )
  empty_body_kj <- c(
    empty_start$daily$body_energy_reserve_initial_kj,
    empty_start$hourly$body_energy_reserve_end_kj
  )

  write_png(
    file.path(stage, "figure-1-equilibrium-and-initialization.png"),
    width = 1800,
    height = 1200,
    draw = function() {
      old_par <- graphics::par(
        mfrow = c(2, 1),
        mar = c(4.5, 5, 2.5, 1),
        oma = c(0, 0, 3, 0),
        las = 1
      )
      on.exit(graphics::par(old_par), add = TRUE)
      colors <- c("#0072B2", "#D55E00")

      graphics::matplot(
        time_h,
        cbind(equilibrium_gut_kj, empty_gut_kj),
        type = "l",
        lty = c(1, 2),
        lwd = 3,
        col = colors,
        xlab = "Elapsed time (h)",
        ylab = "Gut available energy (kJ)",
        main = "Gut-energy stock"
      )
      graphics::legend(
        "bottomright",
        legend = c("Equilibrium start", "Empty-gut start"),
        col = colors,
        lty = c(1, 2),
        lwd = 3,
        bty = "n"
      )

      graphics::matplot(
        time_h,
        cbind(equilibrium_body_kj, empty_body_kj),
        type = "l",
        lty = c(1, 2),
        lwd = 3,
        col = colors,
        xlab = "Elapsed time (h)",
        ylab = "Body energy reserve (kJ)",
        main = "Body-energy reserve"
      )
      graphics::legend(
        "topright",
        legend = c("Equilibrium start", "Empty-gut start"),
        col = colors,
        lty = c(1, 2),
        lwd = 3,
        bty = "n"
      )
      graphics::mtext(
        "Synthetic Goal 003 fixtures: equilibrium and initialization transient",
        side = 3,
        outer = TRUE,
        line = 1,
        font = 2,
        cex = 1.15
      )
    }
  )

  pulse_gut_kj <- c(
    pulse$daily$gut_available_energy_initial_kj,
    pulse$hourly$gut_available_energy_end_kj
  )
  pulse_body_kj <- c(
    pulse$daily$body_energy_reserve_initial_kj,
    pulse$hourly$body_energy_reserve_end_kj
  )
  write_png(
    file.path(stage, "figure-2-pulse-response.png"),
    width = 1800,
    height = 1300,
    draw = function() {
      old_par <- graphics::par(
        mfrow = c(2, 2),
        mar = c(4.5, 5, 2.5, 1),
        oma = c(0, 0, 3, 0),
        las = 1
      )
      on.exit(graphics::par(old_par), add = TRUE)
      input_color <- "#009E73"
      transfer_color <- "#CC79A7"
      stock_color <- "#0072B2"
      body_color <- "#D55E00"

      graphics::plot(
        pulse$hourly$hour_of_day,
        pulse$hourly$prescribed_ingested_available_energy_kj_h,
        type = "h",
        lwd = 5,
        col = input_color,
        xlab = "Hour of day (h)",
        ylab = "Prescribed input (kJ h^-1)",
        main = "Prescribed ingestion",
        xlim = c(0, 23)
      )
      graphics::legend(
        "topright",
        legend = "Ingested available energy",
        col = input_color,
        lty = 1,
        lwd = 4,
        bty = "n"
      )

      graphics::plot(
        pulse$hourly$hour_of_day,
        pulse$hourly$assimilated_energy_kj_h,
        type = "o",
        pch = 16,
        lwd = 2.5,
        col = transfer_color,
        xlab = "Hour of day (h)",
        ylab = "Assimilation (kJ h^-1)",
        main = "Delayed release to body",
        xlim = c(0, 23)
      )
      graphics::legend(
        "topright",
        legend = "Assimilated energy",
        col = transfer_color,
        lty = 1,
        pch = 16,
        lwd = 2.5,
        bty = "n"
      )

      graphics::plot(
        time_h,
        pulse_gut_kj,
        type = "o",
        pch = 16,
        lwd = 2.5,
        col = stock_color,
        xlab = "Elapsed time (h)",
        ylab = "Gut available energy (kJ)",
        main = "Gut-energy stock"
      )
      graphics::legend(
        "topright",
        legend = "Gut stock",
        col = stock_color,
        lty = 1,
        pch = 16,
        lwd = 2.5,
        bty = "n"
      )

      graphics::plot(
        time_h,
        pulse_body_kj,
        type = "o",
        pch = 16,
        lwd = 2.5,
        col = body_color,
        xlab = "Elapsed time (h)",
        ylab = "Body energy reserve (kJ)",
        main = "Body-energy reserve"
      )
      graphics::legend(
        "bottomright",
        legend = "Body reserve",
        col = body_color,
        lty = 1,
        pch = 16,
        lwd = 2.5,
        bty = "n"
      )
      graphics::mtext(
        "Synthetic Goal 003 fixture: 400 kJ pulse enters gut in hour 0",
        side = 3,
        outer = TRUE,
        line = 1,
        font = 2,
        cex = 1.15
      )
    }
  )

  generation_time <- Sys.time()
  time_zone <- Sys.timezone()
  if (is.na(time_zone) || !nzchar(time_zone)) {
    time_zone <- format(generation_time, "%Z")
  }
  branch <- git_output(repository, c("branch", "--show-current"))
  head <- git_output(repository, c("rev-parse", "HEAD"))
  short_status <- git_output(
    repository,
    c("status", "--short", "--untracked-files=all"),
    allow_empty = TRUE
  )
  metadata <- c(
    "review_pack=Herbivore TTR Rebuild Goal 003",
    "fixture_scope=synthetic analytical diagnostics",
    sprintf(
      "generated_at=%s",
      format(
        generation_time,
        "%Y-%m-%dT%H:%M:%S%z",
        tz = time_zone
      )
    ),
    sprintf("time_zone=%s", time_zone),
    sprintf("repository_path=%s", repository),
    sprintf("git_branch=%s", branch[[1L]]),
    sprintf("git_head=%s", head[[1L]]),
    "git_status_short_begin",
    if (length(short_status) == 0L) "(clean)" else short_status,
    "git_status_short_end",
    "transition_duration_h=1",
    "gut_release_fraction_h=0.25",
    "initial_body_energy_reserve_kj=5000",
    "equilibrium_initial_gut_available_energy_kj=400",
    "equilibrium_prescribed_ingested_available_energy_kj_h=100",
    "equilibrium_maintenance_expenditure_kj_h=100",
    "empty_start_initial_gut_available_energy_kj=0",
    "empty_start_prescribed_ingested_available_energy_kj_h=100",
    "empty_start_maintenance_expenditure_kj_h=100",
    "pulse_initial_gut_available_energy_kj=0",
    "pulse_hour_0_prescribed_ingested_available_energy_kj_h=400",
    "pulse_hours_1_to_23_prescribed_ingested_available_energy_kj_h=0",
    "pulse_maintenance_expenditure_kj_h=0",
    paste0(
      "release_order=opening gut stock releases before current-hour ",
      "ingestion enters the stock"
    ),
    paste0(
      "interpretation_boundary=synthetic arithmetic fixtures only; values do ",
      "not estimate macropod physiology, intake, gut residence time, ",
      "maintenance, viability, food mass, or digestive efficiency"
    )
  )
  writeLines(
    metadata,
    con = file.path(stage, "generation-metadata.txt"),
    useBytes = TRUE
  )

  r_source_paths <- list.files(
    "R",
    pattern = "\\.R$",
    full.names = TRUE,
    recursive = FALSE
  )
  if (
    length(r_source_paths) == 0L ||
      any(!grepl("^[ -~]+$", r_source_paths))
  ) {
    stop("The package R source inventory is empty or not byte-sortable.", call. = FALSE)
  }
  r_source_paths <- sort(r_source_paths, method = "radix")
  source_paths <- c(
    "DESCRIPTION",
    "NAMESPACE",
    r_source_paths,
    "experiments/rebuild-003-review-pack.R"
  )
  if (
    anyDuplicated(source_paths) ||
      any(!file.exists(source_paths)) ||
      any(vapply(source_paths, is_symbolic_link, logical(1L))) ||
      any(!file_test("-f", source_paths))
  ) {
    stop("The source-manifest inventory is unsafe or incomplete.", call. = FALSE)
  }
  source_manifest <- manifest_lines(source_paths, source_paths)
  writeLines(
    source_manifest,
    con = file.path(stage, "source-manifest.sha256"),
    useBytes = TRUE
  )

  artifact_names <- setdiff(declared_files, "artifact-manifest.sha256")
  artifact_manifest <- manifest_lines(
    file.path(stage, artifact_names),
    artifact_names
  )
  writeLines(
    artifact_manifest,
    con = file.path(stage, "artifact-manifest.sha256"),
    useBytes = TRUE
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
      any(vapply(file.path(stage, staged_entries), is_symbolic_link, logical(1L))) ||
      any(!file_test("-f", file.path(stage, staged_entries)))
  ) {
    stop("The staged review-pack file set is unsafe or incomplete.", call. = FALSE)
  }
  if (
    any(
      file.info(
        file.path(
          stage,
          c(
            "figure-1-equilibrium-and-initialization.png",
            "figure-2-pulse-response.png"
          )
        )
      )$size < 10000
    )
  ) {
    stop("A staged diagnostic figure appears blank or incomplete.", call. = FALSE)
  }

  daily_read <- read.csv(
    file.path(stage, "table-1-daily-summary.csv"),
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  checkpoints_read <- read.csv(
    file.path(stage, "table-2-hourly-checkpoints.csv"),
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  full_read <- read.csv(
    file.path(stage, "table-3-full-hourly-ledgers.csv"),
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  if (
    !identical(names(daily_read), c("scenario_id", daily_schema)) ||
      !identical(dim(daily_read), c(3L, length(daily_schema) + 1L)) ||
      !identical(daily_read$scenario_id, names(fixtures)) ||
      !identical(names(checkpoints_read), checkpoint_schema) ||
      !identical(dim(checkpoints_read), c(24L, length(checkpoint_schema))) ||
      !identical(names(full_read), c("scenario_id", hourly_schema)) ||
      !identical(dim(full_read), c(72L, length(hourly_schema) + 1L))
  ) {
    stop("A staged CSV failed its exact schema or row-count check.", call. = FALSE)
  }
  assert_close(
    full_read$gut_available_energy_end_kj,
    full_hourly_ledgers$gut_available_energy_end_kj,
    "serialized gut stock"
  )
  assert_close(
    full_read$body_energy_reserve_end_kj,
    full_hourly_ledgers$body_energy_reserve_end_kj,
    "serialized body reserve"
  )
  assert_close(
    full_read$system_energy_balance_residual_kj,
    full_hourly_ledgers$system_energy_balance_residual_kj,
    "serialized whole-system residual"
  )
  if (
    !identical(
      readLines(
        file.path(stage, "source-manifest.sha256"),
        warn = FALSE
      ),
      source_manifest
    ) ||
      !identical(
        readLines(
          file.path(stage, "artifact-manifest.sha256"),
          warn = FALSE
        ),
        artifact_manifest
      )
  ) {
    stop("A staged manifest failed its self-check.", call. = FALSE)
  }

  if (!path_exists(destination)) {
    if (!dir.create(destination, recursive = TRUE, showWarnings = FALSE)) {
      stop("Could not create the exact review-pack destination.", call. = FALSE)
    }
  }
  validate_destination(destination, require_exact = FALSE)
  if (file.access(destination, mode = 2L) != 0L) {
    stop("The review-pack destination is not writable.", call. = FALSE)
  }

  copy_order <- c(
    setdiff(declared_files, "artifact-manifest.sha256"),
    "artifact-manifest.sha256"
  )
  for (entry in copy_order) {
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
  if (
    !identical(
      readLines(
        file.path(destination, "source-manifest.sha256"),
        warn = FALSE
      ),
      manifest_lines(source_paths, source_paths)
    ) ||
      !identical(
        readLines(
          file.path(destination, "artifact-manifest.sha256"),
          warn = FALSE
        ),
        manifest_lines(
          file.path(destination, artifact_names),
          artifact_names
        )
      )
  ) {
    stop("The published review pack failed its checksum self-check.", call. = FALSE)
  }

  cat(
    sprintf(
      "Generated synthetic Goal 003 review pack at %s\n",
      destination
    )
  )
  cat(sprintf("Files: %d (exact declared set)\n", length(declared_files)))
  invisible(NULL)
}

main()
