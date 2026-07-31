declared_files <- c(
  "figure-1-feeding-opportunity-duration.png",
  "table-1-hourly-prescribed-intake-windows.csv",
  "table-2-duration-summary.csv",
  "table-3-daily-accounting.csv"
)

require_that <- function(condition, label) {
  if (length(condition) != 1L || !isTRUE(condition)) {
    stop(sprintf("Goal 010 review-pack validation failed: %s.", label),
      call. = FALSE
    )
  }
  invisible(NULL)
}

is_link <- function(path) {
  target <- Sys.readlink(path)
  length(target) == 1L && !is.na(target) && nzchar(target)
}

path_exists <- function(path) {
  file.exists(path) || dir.exists(path) || is_link(path)
}

absolute_path <- function(path) {
  if (startsWith(path, "/")) path else file.path(getwd(), path)
}

require_no_link_ancestors <- function(path) {
  pieces <- strsplit(
    sub("^/+", "", absolute_path(path)),
    "/",
    fixed = TRUE
  )[[1L]]
  current <- "/"
  for (piece in pieces) {
    if (!nzchar(piece) || piece == ".") next
    current <- if (piece == "..") {
      dirname(current)
    } else {
      file.path(current, piece)
    }
    if (!path_exists(current)) break
    require_that(
      !is_link(current),
      paste("symbolic-link path component:", current)
    )
  }
  invisible(NULL)
}

near <- function(observed, expected) {
  observed <- as.double(observed)
  expected <- as.double(expected)
  length(observed) == length(expected) &&
    all(is.finite(observed)) &&
    all(is.finite(expected)) &&
    all(
      abs(observed - expected) <=
        100 * .Machine$double.eps *
          pmax(1, abs(observed), abs(expected))
    )
}

same_table <- function(left, right) {
  row.names(left) <- NULL
  row.names(right) <- NULL
  identical(names(left), names(right)) &&
    identical(dim(left), dim(right)) &&
    all(vapply(names(left), function(name) {
      x <- left[[name]]
      y <- right[[name]]
      if (is.numeric(x) && is.numeric(y)) return(near(x, y))
      identical(x, y)
    }, logical(1L)))
}

write_csv <- function(value, path) {
  utils::write.csv(
    value,
    path,
    row.names = FALSE,
    quote = TRUE,
    na = ""
  )
}

read_csv <- function(path) {
  utils::read.csv(
    path,
    stringsAsFactors = FALSE,
    check.names = FALSE,
    na.strings = ""
  )
}

check_file_set <- function(directory, exact) {
  require_that(
    dir.exists(directory) && !is_link(directory),
    "review-pack path is a non-symbolic directory"
  )
  entries <- list.files(directory, all.files = TRUE, no.. = TRUE)
  require_that(
    all(entries %in% declared_files),
    "review-pack directory contains no undeclared entries"
  )
  if (isTRUE(exact)) {
    require_that(
      identical(sort(entries), sort(declared_files)),
      "review-pack directory has the exact declared file set"
    )
  }
  for (entry in entries) {
    path <- file.path(directory, entry)
    require_that(
      !is_link(path) &&
        file_test("-f", path) &&
        isFALSE(file.info(path)$isdir) &&
        file.info(path)$size > 0,
      paste(entry, "is a non-empty regular non-symbolic file")
    )
  }
  invisible(NULL)
}

png_dimensions <- function(path) {
  connection <- file(path, open = "rb")
  on.exit(close(connection))
  signature <- readBin(connection, "raw", n = 8L)
  chunk_length <- readBin(
    connection,
    "integer",
    n = 1L,
    size = 4L,
    endian = "big"
  )
  chunk_type <- rawToChar(readBin(connection, "raw", n = 4L))
  width <- readBin(
    connection,
    "integer",
    n = 1L,
    size = 4L,
    endian = "big"
  )
  height <- readBin(
    connection,
    "integer",
    n = 1L,
    size = 4L,
    endian = "big"
  )
  require_that(
    identical(
      signature,
      as.raw(c(137, 80, 78, 71, 13, 10, 26, 10))
    ) &&
      identical(chunk_length, 13L) &&
      identical(chunk_type, "IHDR"),
    "valid PNG header"
  )
  c(width = width, height = height)
}

find_repo_root <- function(destination) {
  candidates <- character()
  script_argument <- grep("^--file=", commandArgs(), value = TRUE)
  if (length(script_argument) == 1L) {
    script_path <- sub("^--file=", "", script_argument)
    if (nzchar(script_path) && script_path != "-") {
      candidates <- c(
        candidates,
        dirname(dirname(absolute_path(script_path)))
      )
    }
  }
  candidates <- c(
    candidates,
    file.path(dirname(absolute_path(destination)), ".."),
    getwd()
  )
  candidates <- unique(vapply(
    candidates,
    normalizePath,
    character(1L),
    mustWork = FALSE
  ))
  for (candidate in candidates) {
    experiment <- file.path(
      candidate,
      "experiments",
      "rebuild-010-feeding-opportunity-duration.R"
    )
    if (file.exists(experiment)) return(candidate)
  }
  stop("Could not locate the Goal 010 experiment.", call. = FALSE)
}

load_evidence <- function(destination) {
  environment <- new.env(parent = globalenv())
  repo_root <- find_repo_root(destination)
  sys.source(
    file.path(
      repo_root,
      "experiments",
      "rebuild-010-feeding-opportunity-duration.R"
    ),
    envir = environment
  )
  evidence <- environment$goal010_evidence
  require_that(is.list(evidence), "single in-memory evidence object")
  evidence
}

validate_evidence <- function(evidence, tables) {
  hourly <- tables$hourly
  duration <- tables$duration
  daily <- tables$daily
  scenario_ids <- c(
    "prescribed_intake_window_24h",
    "prescribed_intake_window_16h",
    "prescribed_intake_window_12h",
    "prescribed_intake_window_8h"
  )
  durations <- c(24L, 16L, 12L, 8L)
  open_hours <- list(
    0:23,
    c(0:7, 16:23),
    c(2:7, 16:21),
    c(4:7, 16:19)
  )
  open <- unlist(lapply(
    open_hours,
    function(hours) 0:23 %in% hours
  ), use.names = FALSE)
  activity <- rep(
    c(rep(50, 8L), rep(0, 8L), rep(50, 8L)),
    4L
  )
  hourly_names <- c(
    "scenario_id",
    "prescribed_intake_window_duration_h_d",
    "hour_of_day",
    "prescribed_intake_window_open",
    "prescribed_dry_matter_intake_kg_dm_h",
    "prescribed_ingested_available_energy_kj_h",
    "prescribed_routine_activity_expenditure_kj_h"
  )
  duration_names <- c(
    "scenario_id",
    "prescribed_intake_window_duration_h_d",
    "closed_prescribed_intake_duration_h_d",
    "prescribed_intake_activity_overlap_h_d",
    "activity_without_prescribed_intake_h_d",
    "prescribed_intake_without_activity_h_d",
    "threshold_relation",
    "daily_prescribed_dry_matter_intake_kg_dm",
    "daily_prescribed_energy_kj",
    "daily_maintenance_expenditure_kj",
    "daily_routine_activity_expenditure_kj",
    "expected_body_energy_change_kj",
    "day_1_body_energy_reserve_final_kj",
    "day_2_body_energy_reserve_final_kj",
    "matched_goal008_scenario_id",
    "daily_input_and_body_change_match",
    "within_day_body_trajectory_identical",
    "full_result_identical"
  )
  daily_names <- c(
    "scenario_id",
    "measurement_day",
    "prescribed_intake_window_duration_h_d",
    "daily_prescribed_dry_matter_intake_kg_dm",
    "total_prescribed_energy_input_kj",
    "total_assimilated_energy_kj",
    "total_maintenance_expenditure_kj",
    "total_routine_activity_expenditure_kj",
    "expected_body_energy_change_kj",
    "observed_body_energy_change_kj",
    "body_energy_reserve_initial_kj",
    "body_energy_reserve_final_kj",
    "body_energy_status"
  )

  require_that(
    identical(names(hourly), hourly_names) &&
      identical(dim(hourly), c(96L, 7L)),
    "table 1 schema and dimensions"
  )
  require_that(
    identical(names(duration), duration_names) &&
      identical(dim(duration), c(4L, 18L)),
    "table 2 schema and dimensions"
  )
  require_that(
    identical(names(daily), daily_names) &&
      identical(dim(daily), c(8L, 13L)),
    "table 3 schema and dimensions"
  )
  require_that(
    identical(hourly$scenario_id, rep(scenario_ids, each = 24L)) &&
      identical(hourly$hour_of_day, rep(0:23, 4L)) &&
      identical(
        hourly$prescribed_intake_window_duration_h_d,
        rep(durations, each = 24L)
      ) &&
      identical(hourly$prescribed_intake_window_open, open),
    "hourly scenario order and declared windows"
  )
  require_that(
    near(
      hourly$prescribed_dry_matter_intake_kg_dm_h,
      as.double(open) * 0.020
    ) &&
      near(
        hourly$prescribed_ingested_available_energy_kj_h,
        as.double(open) * 200
      ) &&
      near(
        hourly$prescribed_routine_activity_expenditure_kj_h,
        activity
      ),
    "hourly fixed intake and activity schedules"
  )
  require_that(
    identical(duration$scenario_id, scenario_ids) &&
      identical(
        duration$prescribed_intake_window_duration_h_d,
        durations
      ) &&
      identical(
        duration$closed_prescribed_intake_duration_h_d,
        c(0L, 8L, 12L, 16L)
      ) &&
      identical(
        duration$prescribed_intake_activity_overlap_h_d,
        c(16L, 16L, 12L, 8L)
      ) &&
      identical(
        duration$activity_without_prescribed_intake_h_d,
        c(0L, 0L, 4L, 8L)
      ) &&
      identical(
        duration$prescribed_intake_without_activity_h_d,
        c(8L, 0L, 0L, 0L)
      ) &&
      identical(
        duration$threshold_relation,
        c("above", "at", "below", "below")
      ),
    "duration order, overlap, and threshold relation"
  )
  require_that(
    near(
      duration$daily_prescribed_dry_matter_intake_kg_dm,
      c(0.48, 0.32, 0.24, 0.16)
    ) &&
      near(duration$daily_prescribed_energy_kj, c(4800, 3200, 2400, 1600)) &&
      near(duration$daily_maintenance_expenditure_kj, rep(2400, 4L)) &&
      near(
        duration$daily_routine_activity_expenditure_kj,
        rep(800, 4L)
      ) &&
      near(
        duration$expected_body_energy_change_kj,
        c(1600, 0, -800, -1600)
      ) &&
      near(
        duration$day_1_body_energy_reserve_final_kj,
        c(11600, 10000, 9200, 8400)
      ) &&
      near(
        duration$day_2_body_energy_reserve_final_kj,
        c(13200, 10000, 8400, 6800)
      ),
    "duration accounting and body closes"
  )
  require_that(
    identical(
      duration$matched_goal008_scenario_id,
      c(
        NA_character_,
        "ecological_activity_prescribed_balance",
        "ecological_activity_uncompensated",
        NA_character_
      )
    ) &&
      identical(
        duration$daily_input_and_body_change_match,
        c(NA, TRUE, TRUE, NA)
      ) &&
      identical(
        duration$within_day_body_trajectory_identical,
        c(NA, TRUE, FALSE, NA)
      ) &&
      identical(
        duration$full_result_identical,
        c(NA, TRUE, FALSE, NA)
      ),
    "Goal 008 comparison flags"
  )

  expected_changes <- rep(c(1600, 0, -800, -1600), each = 2L)
  expected_initial <- c(10000, 11600, 10000, 10000, 10000, 9200, 10000, 8400)
  expected_final <- c(11600, 13200, 10000, 10000, 9200, 8400, 8400, 6800)
  require_that(
    identical(daily$scenario_id, rep(scenario_ids, each = 2L)) &&
      identical(daily$measurement_day, rep(1:2, 4L)) &&
      near(daily$total_prescribed_energy_input_kj, rep(c(4800, 3200, 2400, 1600), each = 2L)) &&
      near(daily$total_assimilated_energy_kj, rep(c(4800, 3200, 2400, 1600), each = 2L)) &&
      near(daily$total_maintenance_expenditure_kj, rep(2400, 8L)) &&
      near(daily$total_routine_activity_expenditure_kj, rep(800, 8L)) &&
      near(daily$expected_body_energy_change_kj, expected_changes) &&
      near(daily$observed_body_energy_change_kj, expected_changes) &&
      near(daily$body_energy_reserve_initial_kj, expected_initial) &&
      near(daily$body_energy_reserve_final_kj, expected_final) &&
      identical(
        daily$body_energy_status,
        rep(c("surplus", "neutral", "deficit", "deficit"), each = 2L)
      ),
    "daily accounting order and values"
  )
  require_that(
    identical(
      evidence$fixtures$prescribed_intake_window_16h$model$result,
      evidence$oracle_balanced$result
    ) &&
      !identical(
        evidence$fixtures$prescribed_intake_window_12h$model$result,
        evidence$oracle_uncompensated$result
      ),
    "full-result oracle boundaries"
  )
  for (table in tables) {
    columns <- grep("_kj$", names(table), value = TRUE)
    require_that(
      all(vapply(
        table[columns],
        function(value) all(value == round(value)),
        logical(1L)
      )),
      "whole-kilojoule human-facing values"
    )
  }
  invisible(NULL)
}

write_figure <- function(evidence, path) {
  colors <- c(
    prescribed_intake_window_24h = "#0072B2",
    prescribed_intake_window_16h = "#009E73",
    prescribed_intake_window_12h = "#E69F00",
    prescribed_intake_window_8h = "#D55E00"
  )
  labels <- c("24 h null", "16 h", "12 h", "8 h")
  grDevices::png(
    path,
    width = 1800,
    height = 900,
    units = "px",
    pointsize = 14,
    bg = "white",
    res = 150
  )
  device <- grDevices::dev.cur()
  on.exit(
    if (device %in% grDevices::dev.list()) grDevices::dev.off(device)
  )
  old_par <- graphics::par(
    mfrow = c(1, 3),
    mar = c(5.0, 4.8, 4.0, 1.0),
    oma = c(3.2, 0, 4.2, 0),
    las = 1
  )
  on.exit(graphics::par(old_par), add = TRUE)

  graphics::plot(
    NA,
    NA,
    xlim = c(0, 24),
    ylim = c(0.4, 4.6),
    xaxs = "i",
    yaxs = "i",
    axes = FALSE,
    xlab = "Hour of day",
    ylab = "",
    main = "Prescribed windows and fixed activity"
  )
  y <- 4:1
  for (index in seq_along(evidence$scenario_ids)) {
    scenario_id <- evidence$scenario_ids[[index]]
    open <- 0:23 %in% evidence$open_hours[[scenario_id]]
    for (hour in 0:23) {
      graphics::rect(
        hour,
        y[[index]] - 0.27,
        hour + 1,
        y[[index]] + 0.27,
        col = if (open[[hour + 1L]]) colors[[scenario_id]] else "#E8E8E8",
        border = "white"
      )
    }
    graphics::segments(0, y[[index]] - 0.34, 8, y[[index]] - 0.34, lwd = 3)
    graphics::segments(16, y[[index]] - 0.34, 24, y[[index]] - 0.34, lwd = 3)
  }
  graphics::axis(1, at = seq(0, 24, 4))
  graphics::axis(2, at = y, labels = labels, tick = FALSE)
  graphics::box()
  graphics::legend(
    "bottom",
    inset = 0.01,
    legend = c("Intake open", "Intake closed", "Activity 50 kJ/h"),
    fill = c("#777777", "#E8E8E8", NA),
    border = c("#777777", "#BBBBBB", NA),
    lty = c(NA, NA, 1),
    lwd = c(NA, NA, 3),
    bty = "n",
    cex = 0.64,
    horiz = TRUE
  )

  duration_grid <- seq(8, 24, length.out = 161L)
  graphics::plot(
    duration_grid,
    200 * duration_grid - 3200,
    type = "l",
    lwd = 2.4,
    col = "#333333",
    xlim = c(8, 24),
    ylim = c(-1800, 1800),
    xlab = "Prescribed-intake-window duration (h/d)",
    ylab = "Daily body-energy change (kJ/d)",
    main = "Fixed-rate daily accounting"
  )
  graphics::abline(h = 0, v = 16, lty = 2, col = "#666666")
  durations <- c(24, 16, 12, 8)
  changes <- c(1600, 0, -800, -1600)
  graphics::points(
    durations,
    changes,
    pch = 19,
    cex = 1.15,
    col = colors
  )
  graphics::text(
    durations,
    changes,
    labels = sprintf("%+d kJ", changes),
    pos = c(2, 3, 4, 4),
    cex = 0.72,
    col = colors
  )
  graphics::text(
    16,
    1700,
    "16 h neutrality",
    pos = 2,
    cex = 0.72,
    col = "#555555"
  )

  boundaries <- lapply(evidence$fixtures, function(fixture) {
    c(
      fixture$model$result$hourly$body_energy_reserve_start_kj[[1L]],
      fixture$model$result$hourly$body_energy_reserve_end_kj
    )
  })
  limits <- range(unlist(boundaries, use.names = FALSE))
  padding <- max(200, 0.06 * diff(limits))
  graphics::plot(
    0:48,
    boundaries[[1L]],
    type = "l",
    lwd = 2.2,
    col = colors[[1L]],
    ylim = limits + c(-padding, padding),
    xlab = "Elapsed measurement time (h)",
    ylab = "Body-energy reserve (kJ)",
    main = "Clock-specific reserve trajectories"
  )
  for (index in 2:4) {
    graphics::lines(
      0:48,
      boundaries[[index]],
      lwd = 2.2,
      lty = index,
      col = colors[[index]]
    )
  }
  graphics::abline(h = 10000, v = 24, lty = 3, col = "#666666")
  graphics::legend(
    "topleft",
    legend = labels,
    col = colors,
    lty = 1:4,
    lwd = 2.2,
    bty = "n",
    cex = 0.72
  )

  graphics::mtext(
    "Prescribed-intake-window duration screen",
    side = 3,
    outer = TRUE,
    line = 2.3,
    font = 2,
    cex = 1.15
  )
  graphics::mtext(
    paste0(
      "Fixed 0.020 kg DM/h in open intervals; fixed activity; ",
      "trajectories conditional on declared clock placement"
    ),
    side = 1,
    outer = TRUE,
    line = 1.3,
    cex = 0.78
  )
  grDevices::dev.off(device)
  on.exit(NULL)
}

publish_pack <- function(stage, destination) {
  require_no_link_ancestors(destination)
  parent <- dirname(destination)
  if (!dir.exists(parent) &&
      !dir.create(parent, recursive = TRUE, showWarnings = FALSE)) {
    stop("Could not create review-pack parent.", call. = FALSE)
  }
  require_no_link_ancestors(parent)
  require_that(
    dir.exists(parent) &&
      !is_link(parent) &&
      file.access(parent, 2L) == 0L,
    "writable non-symbolic review-pack parent"
  )

  candidate <- tempfile(
    paste0(".", basename(destination), "-"),
    tmpdir = parent
  )
  require_that(dir.create(candidate), "create publication candidate")
  on.exit(unlink(candidate, recursive = TRUE, force = TRUE), add = TRUE)
  copied <- file.copy(
    file.path(stage, declared_files),
    candidate,
    overwrite = FALSE,
    copy.date = FALSE
  )
  require_that(all(copied), "copy complete publication candidate")
  check_file_set(candidate, exact = TRUE)

  if (!path_exists(destination)) {
    require_that(
      file.rename(candidate, destination),
      "publish review pack"
    )
    return(invisible(NULL))
  }

  check_file_set(destination, exact = FALSE)
  backup <- tempfile(
    paste0(".", basename(destination), "-old-"),
    tmpdir = parent
  )
  require_that(
    file.rename(destination, backup),
    "move previous review pack aside"
  )
  if (!file.rename(candidate, destination)) {
    restored <- file.rename(backup, destination)
    if (!restored) {
      stop(
        "Publication failed and the previous pack could not be restored.",
        call. = FALSE
      )
    }
    stop("Could not replace the review pack.", call. = FALSE)
  }
  require_that(
    unlink(backup, recursive = TRUE, force = TRUE) == 0L,
    "remove superseded review pack"
  )
  invisible(NULL)
}

main <- function() {
  arguments <- commandArgs(trailingOnly = TRUE)
  if (
    length(arguments) != 1L ||
      is.na(arguments[[1L]]) ||
      !nzchar(arguments[[1L]]) ||
      grepl("[\r\n]", arguments[[1L]])
  ) {
    stop(
      "Supply exactly one non-empty output-directory argument.",
      call. = FALSE
    )
  }
  destination <- sub("/+$", "", arguments[[1L]])
  if (
    !nzchar(destination) ||
      destination %in% c(".", "..") ||
      is_link(destination)
  ) {
    stop(
      "Supply a dedicated non-symbolic output directory.",
      call. = FALSE
    )
  }
  require_no_link_ancestors(destination)
  if (path_exists(destination)) check_file_set(destination, exact = FALSE)

  old_options <- options(digits = 17)
  on.exit(options(old_options), add = TRUE)
  evidence <- load_evidence(destination)
  tables <- list(
    hourly = evidence$hourly_prescribed_intake_windows,
    duration = evidence$duration_summary,
    daily = evidence$daily_accounting
  )
  validate_evidence(evidence, tables)

  stage <- tempfile("rebuild010-review-pack-")
  require_that(dir.create(stage), "create staging directory")
  on.exit(unlink(stage, recursive = TRUE, force = TRUE), add = TRUE)
  csv_paths <- c(
    hourly = file.path(stage, declared_files[[2L]]),
    duration = file.path(stage, declared_files[[3L]]),
    daily = file.path(stage, declared_files[[4L]])
  )
  for (name in names(csv_paths)) {
    write_csv(tables[[name]], csv_paths[[name]])
  }
  read_back <- lapply(csv_paths, read_csv)
  validate_evidence(evidence, read_back)
  require_that(
    all(vapply(
      names(tables),
      function(name) same_table(read_back[[name]], tables[[name]]),
      logical(1L)
    )),
    "staged CSV read-back identity"
  )

  figure_path <- file.path(stage, declared_files[[1L]])
  write_figure(evidence, figure_path)
  require_that(
    identical(png_dimensions(figure_path), c(width = 1800L, height = 900L)),
    "1800 x 900 staged figure"
  )
  check_file_set(stage, exact = TRUE)
  publish_pack(stage, destination)
  check_file_set(destination, exact = TRUE)

  retained <- list(
    hourly = read_csv(file.path(destination, declared_files[[2L]])),
    duration = read_csv(file.path(destination, declared_files[[3L]])),
    daily = read_csv(file.path(destination, declared_files[[4L]]))
  )
  validate_evidence(evidence, retained)
  require_that(
    all(vapply(
      names(tables),
      function(name) same_table(retained[[name]], tables[[name]]),
      logical(1L)
    )) &&
      identical(
        png_dimensions(file.path(destination, declared_files[[1L]])),
        c(width = 1800L, height = 900L)
      ),
    "retained read-back identity and figure dimensions"
  )
  cat(sprintf(
    "Generated Goal 010 review pack at %s (exactly four files).\n",
    destination
  ))
}

main()
