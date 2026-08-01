declared_files <- c(
  "figure-1-one-day-prescribed-input-shortfall.png",
  "table-1-hourly-boundary-contrasts.csv",
  "table-2-daily-sequences.csv",
  "table-3-day-boundary-realignment.csv"
)

require_that <- function(condition, label) {
  if (length(condition) != 1L || !isTRUE(condition)) {
    stop(
      sprintf("Goal 011 review-pack validation failed: %s.", label),
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

near <- function(observed, expected, scale = NULL) {
  observed <- as.double(observed)
  expected <- as.double(expected)
  if (length(expected) == 1L && length(observed) > 1L) {
    expected <- rep(expected, length(observed))
  }
  if (is.null(scale)) {
    scale <- pmax(1, abs(observed), abs(expected))
  } else {
    scale <- pmax(1, as.double(scale))
  }
  length(observed) == length(expected) &&
    length(scale) %in% c(1L, length(observed)) &&
    all(is.finite(observed)) &&
    all(is.finite(expected)) &&
    all(is.finite(scale)) &&
    all(
      abs(observed - expected) <=
        100 * .Machine$double.eps * scale
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
      if (is.numeric(x) && is.numeric(y)) {
        missing <- is.na(x) | is.na(y)
        return(
          identical(is.na(x), is.na(y)) &&
            near(x[!missing], y[!missing])
        )
      }
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
  entries <- list.files(
    directory,
    all.files = TRUE,
    no.. = TRUE
  )
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
      "rebuild-011-one-day-prescribed-input-shortfall.R"
    )
    if (file.exists(experiment)) return(candidate)
  }
  stop("Could not locate the Goal 011 experiment.", call. = FALSE)
}

load_evidence <- function(destination) {
  environment <- new.env(parent = globalenv())
  repo_root <- find_repo_root(destination)
  sys.source(
    file.path(
      repo_root,
      "experiments",
      "rebuild-011-one-day-prescribed-input-shortfall.R"
    ),
    envir = environment
  )
  evidence <- environment$goal011_evidence
  require_that(is.list(evidence), "single in-memory evidence object")
  evidence
}

validate_evidence <- function(evidence, tables) {
  hourly <- tables$hourly
  daily <- tables$daily
  boundaries <- tables$boundaries
  hourly_names <- c(
    "elapsed_time_h",
    "boundary_phase",
    "cumulative_prescribed_input_contrast_kj",
    "gut_available_energy_contrast_kj",
    "body_energy_reserve_contrast_kj",
    "combined_system_energy_contrast_kj",
    "contrast_closure_residual_kj"
  )
  daily_names <- c(
    "sequence_id",
    "sequence_day",
    "forcing_phase",
    "daily_prescribed_dry_matter_intake_kg_dm",
    "total_prescribed_energy_input_kj",
    "total_assimilated_energy_kj",
    "total_maintenance_expenditure_kj",
    "total_routine_activity_expenditure_kj",
    "expected_body_energy_change_kj",
    "observed_body_energy_change_kj",
    "gut_available_energy_initial_kj",
    "gut_available_energy_final_kj",
    "body_energy_reserve_initial_kj",
    "body_energy_reserve_final_kj",
    "total_system_energy_initial_kj",
    "total_system_energy_final_kj"
  )
  boundary_names <- c(
    "elapsed_time_h",
    "boundary_label",
    "cumulative_prescribed_input_contrast_kj",
    "gut_available_energy_contrast_kj",
    "expected_gut_contrast_kj",
    "gut_contraction_factor_from_previous_boundary",
    "body_energy_reserve_contrast_kj",
    "expected_body_complement_kj",
    "combined_system_energy_contrast_kj",
    "contrast_closure_residual_kj"
  )

  require_that(
    identical(names(hourly), hourly_names) &&
      identical(dim(hourly), c(73L, 7L)),
    "table 1 schema and dimensions"
  )
  require_that(
    identical(names(daily), daily_names) &&
      identical(dim(daily), c(6L, 16L)),
    "table 2 schema and dimensions"
  )
  require_that(
    identical(names(boundaries), boundary_names) &&
      identical(dim(boundaries), c(4L, 10L)),
    "table 3 schema and dimensions"
  )

  expected_phases <- c(
    "initial",
    rep("shortfall_day", 24L),
    rep("return_to_reference_day_1", 24L),
    rep("return_to_reference_day_2", 24L)
  )
  expected_hourly_input_contrast <- c(
    rep(-50, 8L),
    rep(0, 8L),
    rep(-50, 8L),
    rep(0, 48L)
  )
  expected_cumulative_input <- c(
    0,
    cumsum(expected_hourly_input_contrast)
  )
  expected_gut <- numeric(73L)
  for (index in seq_len(72L)) {
    expected_gut[[index + 1L]] <-
      0.75 * expected_gut[[index]] +
        expected_hourly_input_contrast[[index]]
  }

  require_that(
    identical(hourly$elapsed_time_h, 0:72) &&
      identical(hourly$boundary_phase, expected_phases) &&
      near(
        hourly$cumulative_prescribed_input_contrast_kj,
        expected_cumulative_input
      ),
    "table 1 order, phases, and cumulative prescribed input"
  )
  require_that(
    near(
      hourly$gut_available_energy_contrast_kj,
      expected_gut,
      scale = 800
    ) &&
      near(
        hourly$gut_available_energy_contrast_kj[26:73],
        0.75 *
          hourly$gut_available_energy_contrast_kj[25:72],
        scale = 800
      ),
    "table 1 analytical and hourly gut contraction"
  )
  require_that(
    near(
      hourly$combined_system_energy_contrast_kj,
      expected_cumulative_input,
      scale = 10000
    ) &&
      near(
        hourly$combined_system_energy_contrast_kj[25:73],
        -800,
        scale = 10000
      ) &&
      near(
        hourly$body_energy_reserve_contrast_kj,
        expected_cumulative_input -
          hourly$gut_available_energy_contrast_kj,
        scale = 10000
      ) &&
      near(
        hourly$contrast_closure_residual_kj,
        0,
        scale = 10000
      ),
    "table 1 system invariant, body complement, and closure"
  )

  expected_sequence_ids <- c(
    rep("all_balanced_control", 3L),
    rep("one_day_rate_shortfall", 3L)
  )
  expected_forcing_phases <- c(
    rep("balanced", 3L),
    "shortfall",
    "return_to_reference",
    "return_to_reference"
  )
  sequence_ids <- c(
    "all_balanced_control",
    "one_day_rate_shortfall"
  )
  declared_forcing_phases <- list(
    all_balanced_control = rep("balanced", 3L),
    one_day_rate_shortfall = c(
      "shortfall",
      "return_to_reference",
      "return_to_reference"
    )
  )
  sequence_results <- list(
    all_balanced_control =
      evidence$sequences$all_balanced_control,
    one_day_rate_shortfall =
      evidence$sequences$one_day_rate_shortfall
  )
  require_that(
    all(vapply(sequence_ids, function(sequence_id) {
      sequence <- sequence_results[[sequence_id]]
      is.list(sequence) &&
        identical(sequence$sequence_id, sequence_id) &&
        identical(
          sequence$forcing_phases,
          declared_forcing_phases[[sequence_id]]
        ) &&
        is.list(sequence$days) &&
        length(sequence$days) == 3L
    }, logical(1L))),
    "evidence sequence metadata and three-day results"
  )
  require_that(
    identical(daily$sequence_id, expected_sequence_ids) &&
      identical(daily$sequence_day, rep(1:3, 2L)) &&
      identical(daily$forcing_phase, expected_forcing_phases),
    "table 2 sequence and forcing order"
  )

  balanced_dry_matter_total <- sum(
    evidence$schedules$balanced_dry_matter$
      prescribed_dry_matter_intake_kg_dm_h
  )
  shortfall_dry_matter_total <- sum(
    evidence$schedules$shortfall_dry_matter$
      prescribed_dry_matter_intake_kg_dm_h
  )
  dry_matter_totals_by_phase <- c(
    balanced = balanced_dry_matter_total,
    shortfall = shortfall_dry_matter_total,
    return_to_reference = balanced_dry_matter_total
  )
  expected_daily <- do.call(rbind, lapply(sequence_ids, function(sequence_id) {
    sequence <- sequence_results[[sequence_id]]
    phases <- declared_forcing_phases[[sequence_id]]
    do.call(rbind, lapply(seq_along(sequence$days), function(sequence_day) {
      result <- sequence$days[[sequence_day]]$daily
      phase <- phases[[sequence_day]]
      data.frame(
        sequence_id = sequence_id,
        sequence_day = as.integer(sequence_day),
        forcing_phase = phase,
        daily_prescribed_dry_matter_intake_kg_dm =
          dry_matter_totals_by_phase[[phase]],
        total_prescribed_energy_input_kj =
          round(
            result$total_prescribed_ingested_available_energy_kj
          ),
        total_assimilated_energy_kj =
          round(result$total_assimilated_energy_kj),
        total_maintenance_expenditure_kj =
          round(result$total_maintenance_expenditure_kj),
        total_routine_activity_expenditure_kj =
          round(
            result$
              total_prescribed_routine_activity_expenditure_kj
          ),
        expected_body_energy_change_kj =
          round(result$expected_body_energy_change_kj),
        observed_body_energy_change_kj =
          round(result$observed_body_energy_change_kj),
        gut_available_energy_initial_kj =
          round(result$gut_available_energy_initial_kj),
        gut_available_energy_final_kj =
          round(result$gut_available_energy_final_kj),
        body_energy_reserve_initial_kj =
          round(result$body_energy_reserve_initial_kj),
        body_energy_reserve_final_kj =
          round(result$body_energy_reserve_final_kj),
        total_system_energy_initial_kj =
          round(result$total_system_energy_initial_kj),
        total_system_energy_final_kj =
          round(result$total_system_energy_final_kj),
        row.names = NULL
      )
    }))
  }))
  row.names(expected_daily) <- NULL

  require_that(
    same_table(daily, expected_daily),
    "table 2 complete reconstruction from sequence results"
  )
  amount_columns <- grep("_kj$", names(daily), value = TRUE)
  require_that(
    all(vapply(
      daily[amount_columns],
      function(value) {
        all(is.finite(value)) && all(value == round(value))
      },
      logical(1L)
    )),
    "table 2 finite whole-kilojoule amounts and stocks"
  )
  require_that(
    near(
      daily$expected_body_energy_change_kj,
      daily$total_assimilated_energy_kj -
        daily$total_maintenance_expenditure_kj -
        daily$total_routine_activity_expenditure_kj
    ) &&
      near(
        daily$observed_body_energy_change_kj,
        daily$body_energy_reserve_final_kj -
          daily$body_energy_reserve_initial_kj
      ) &&
      near(
        daily$expected_body_energy_change_kj,
        daily$observed_body_energy_change_kj
      ) &&
      near(
        daily$gut_available_energy_final_kj -
          daily$gut_available_energy_initial_kj,
        daily$total_prescribed_energy_input_kj -
          daily$total_assimilated_energy_kj
      ),
    "table 2 rounded gut and body accounting identities"
  )
  require_that(
    near(
      daily$total_system_energy_initial_kj,
      daily$gut_available_energy_initial_kj +
        daily$body_energy_reserve_initial_kj
    ) &&
      near(
        daily$total_system_energy_final_kj,
        daily$gut_available_energy_final_kj +
          daily$body_energy_reserve_final_kj
      ) &&
      near(
        daily$total_system_energy_final_kj -
          daily$total_system_energy_initial_kj,
        daily$total_prescribed_energy_input_kj -
          daily$total_maintenance_expenditure_kj -
          daily$total_routine_activity_expenditure_kj
      ),
    "table 2 rounded whole-system accounting identities"
  )
  carry_indices <- list(1:3, 4:6)
  require_that(
    all(vapply(carry_indices, function(indices) {
      next_rows <- indices[-1L]
      previous_rows <- head(indices, -1L)
      identical(
        daily$gut_available_energy_initial_kj[next_rows],
        daily$gut_available_energy_final_kj[previous_rows]
      ) &&
        identical(
          daily$body_energy_reserve_initial_kj[next_rows],
          daily$body_energy_reserve_final_kj[previous_rows]
        ) &&
        identical(
          daily$total_system_energy_initial_kj[next_rows],
          daily$total_system_energy_final_kj[previous_rows]
        )
    }, logical(1L))),
    "table 2 exact rounded within-sequence carry-over"
  )

  require_that(
    identical(boundaries$elapsed_time_h, c(0L, 24L, 48L, 72L)) &&
      identical(
        boundaries$boundary_label,
        c(
          "initial",
          "shortfall_day_close",
          "return_to_reference_day_1_close",
          "return_to_reference_day_2_close"
        )
      ),
    "table 3 boundary order and labels"
  )
  selected <- c(1L, 25L, 49L, 73L)
  require_that(
    near(
      boundaries$cumulative_prescribed_input_contrast_kj,
      hourly$
        cumulative_prescribed_input_contrast_kj[selected]
    ) &&
      near(
        boundaries$gut_available_energy_contrast_kj,
        hourly$gut_available_energy_contrast_kj[selected]
      ) &&
      near(
        boundaries$body_energy_reserve_contrast_kj,
        hourly$body_energy_reserve_contrast_kj[selected]
      ) &&
      near(
        boundaries$combined_system_energy_contrast_kj,
        hourly$combined_system_energy_contrast_kj[selected]
      ) &&
      near(
        boundaries$contrast_closure_residual_kj,
        hourly$contrast_closure_residual_kj[selected]
      ),
    "table 3 reconstruction from table 1"
  )
  require_that(
    identical(
      is.na(
        boundaries$
          gut_contraction_factor_from_previous_boundary
      ),
      c(TRUE, TRUE, FALSE, FALSE)
    ) &&
      near(
        boundaries$
          gut_contraction_factor_from_previous_boundary[3:4],
        rep(0.75^24, 2L)
      ) &&
      near(
        boundaries$expected_gut_contrast_kj,
        expected_gut[selected],
        scale = 800
      ) &&
      near(
        boundaries$expected_body_complement_kj,
        expected_cumulative_input[selected] -
          expected_gut[selected],
        scale = 10000
      ),
    "table 3 daily contraction and analytical complements"
  )

  control <- sequence_results$all_balanced_control
  shortfall <- sequence_results$one_day_rate_shortfall
  require_that(
    identical(
      control$days[[1L]]$daily$gut_available_energy_initial_kj,
      shortfall$days[[1L]]$daily$gut_available_energy_initial_kj
    ) &&
      identical(
        control$days[[1L]]$daily$body_energy_reserve_initial_kj,
        shortfall$days[[1L]]$daily$body_energy_reserve_initial_kj
      ),
    "common sequence initialization"
  )
  require_that(
    identical(
      evidence$schedules$balanced_energy$
        prescribed_ingested_available_energy_kj_h,
      c(rep(200, 8L), rep(0, 8L), rep(200, 8L))
    ) &&
      identical(
        evidence$schedules$shortfall_energy$
          prescribed_ingested_available_energy_kj_h,
        c(rep(150, 8L), rep(0, 8L), rep(150, 8L))
      ) &&
      identical(
        evidence$schedules$routine_activity$
          prescribed_routine_activity_expenditure_kj_h,
        c(rep(50, 8L), rep(0, 8L), rep(50, 8L))
      ),
    "evidence object exact schedules"
  )
  invisible(NULL)
}

write_figure <- function(evidence, path) {
  hourly <- evidence$hourly_boundary_contrasts
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
    las = 1,
    mgp = c(2.8, 0.8, 0)
  )
  on.exit(graphics::par(old_par), add = TRUE)

  phase_rectangles <- function(y_bottom, y_top) {
    graphics::rect(
      c(0, 24, 48),
      y_bottom,
      c(24, 48, 72),
      y_top,
      col = c("#F2F2F2", "#EAF2F8", "#F7F7F7"),
      border = NA
    )
  }

  input_time <- 0:72
  balanced_input <- c(
    evidence$balanced_hourly_input_kj,
    tail(evidence$balanced_hourly_input_kj, 1L)
  )
  shortfall_input <- c(
    evidence$shortfall_hourly_input_kj,
    tail(evidence$shortfall_hourly_input_kj, 1L)
  )
  graphics::plot(
    NA,
    NA,
    xlim = c(0, 72),
    ylim = c(0, 235),
    xaxs = "i",
    yaxs = "i",
    xlab = "Elapsed time (h)",
    ylab = "Prescribed energy input (kJ/h)",
    main = "Prescribed forcing"
  )
  phase_rectangles(0, 235)
  graphics::lines(
    input_time,
    balanced_input,
    type = "s",
    lwd = 2.4,
    col = "#0072B2"
  )
  graphics::lines(
    input_time,
    shortfall_input,
    type = "s",
    lwd = 2.2,
    lty = 2,
    col = "#D55E00"
  )
  graphics::abline(v = c(24, 48), lty = 3, col = "#777777")
  graphics::text(
    c(12, 36, 60),
    224,
    c(
      "Shortfall day",
      "Return-to-reference forcing",
      "Return-to-reference forcing"
    ),
    cex = 0.64
  )
  graphics::legend(
    "bottomleft",
    legend = c("All-balanced control", "One-day rate shortfall"),
    col = c("#0072B2", "#D55E00"),
    lty = c(1, 2),
    lwd = 2.3,
    bty = "n",
    cex = 0.78
  )

  contrast_limits <- c(-850, 50)
  graphics::plot(
    NA,
    NA,
    xlim = c(0, 72),
    ylim = contrast_limits,
    xaxs = "i",
    yaxs = "i",
    xlab = "Elapsed boundary time (h)",
    ylab = "Treatment - control contrast (kJ)",
    main = "Gut and body partition"
  )
  phase_rectangles(contrast_limits[[1L]], contrast_limits[[2L]])
  graphics::abline(h = 0, v = c(24, 48), lty = 3, col = "#777777")
  graphics::lines(
    hourly$elapsed_time_h,
    hourly$gut_available_energy_contrast_kj,
    lwd = 2.4,
    col = "#009E73"
  )
  graphics::lines(
    hourly$elapsed_time_h,
    hourly$body_energy_reserve_contrast_kj,
    lwd = 2.4,
    lty = 2,
    col = "#D55E00"
  )
  graphics::legend(
    "bottomleft",
    legend = c("Gut stock", "Body reserve"),
    col = c("#009E73", "#D55E00"),
    lty = c(1, 2),
    lwd = 2.4,
    bty = "n",
    cex = 0.78
  )

  graphics::plot(
    NA,
    NA,
    xlim = c(0, 72),
    ylim = contrast_limits,
    xaxs = "i",
    yaxs = "i",
    xlab = "Elapsed boundary time (h)",
    ylab = "Treatment - control contrast (kJ)",
    main = "Whole-system debt"
  )
  phase_rectangles(contrast_limits[[1L]], contrast_limits[[2L]])
  graphics::abline(h = 0, v = c(24, 48), lty = 3, col = "#777777")
  graphics::lines(
    hourly$elapsed_time_h,
    hourly$cumulative_prescribed_input_contrast_kj,
    lwd = 4.5,
    col = "#0072B2"
  )
  graphics::lines(
    hourly$elapsed_time_h,
    hourly$combined_system_energy_contrast_kj,
    lwd = 2.2,
    lty = 2,
    col = "#222222"
  )
  graphics::points(
    c(24, 48, 72),
    rep(-800, 3L),
    pch = 19,
    col = "#222222"
  )
  graphics::text(
    70,
    -770,
    "-800 kJ retained",
    pos = 2,
    cex = 0.78
  )
  graphics::legend(
    "topright",
    legend = c(
      "Cumulative prescribed input",
      "Combined system"
    ),
    col = c("#0072B2", "#222222"),
    lty = c(1, 2),
    lwd = c(4.0, 2.2),
    bty = "n",
    cex = 0.76
  )

  graphics::mtext(
    "One-day prescribed-input shortfall",
    side = 3,
    outer = TRUE,
    line = 2.3,
    font = 2,
    cex = 1.15
  )
  graphics::mtext(
    paste0(
      "Day 1 shortfall; days 2-3 return-to-reference forcing; ",
      "contrasts are one-day rate shortfall minus all-balanced control"
    ),
    side = 1,
    outer = TRUE,
    line = 1.3,
    cex = 0.76
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
    hourly = evidence$hourly_boundary_contrasts,
    daily = evidence$daily_sequences,
    boundaries = evidence$day_boundary_realignment
  )
  validate_evidence(evidence, tables)

  stage <- tempfile("rebuild011-review-pack-")
  require_that(dir.create(stage), "create staging directory")
  on.exit(unlink(stage, recursive = TRUE, force = TRUE), add = TRUE)
  csv_paths <- c(
    hourly = file.path(stage, declared_files[[2L]]),
    daily = file.path(stage, declared_files[[3L]]),
    boundaries = file.path(stage, declared_files[[4L]])
  )
  for (name in names(csv_paths)) {
    write_csv(tables[[name]], csv_paths[[name]])
  }
  read_back <- lapply(csv_paths, read_csv)
  validate_evidence(evidence, read_back)
  require_that(
    all(vapply(
      names(tables),
      function(name) {
        same_table(read_back[[name]], tables[[name]])
      },
      logical(1L)
    )),
    "staged CSV read-back identity"
  )

  figure_path <- file.path(stage, declared_files[[1L]])
  write_figure(evidence, figure_path)
  require_that(
    identical(
      png_dimensions(figure_path),
      c(width = 1800L, height = 900L)
    ),
    "1800 x 900 staged figure"
  )
  check_file_set(stage, exact = TRUE)
  publish_pack(stage, destination)
  check_file_set(destination, exact = TRUE)

  retained <- list(
    hourly = read_csv(
      file.path(destination, declared_files[[2L]])
    ),
    daily = read_csv(
      file.path(destination, declared_files[[3L]])
    ),
    boundaries = read_csv(
      file.path(destination, declared_files[[4L]])
    )
  )
  validate_evidence(evidence, retained)
  require_that(
    all(vapply(
      names(tables),
      function(name) {
        same_table(retained[[name]], tables[[name]])
      },
      logical(1L)
    )) &&
      identical(
        png_dimensions(
          file.path(destination, declared_files[[1L]])
        ),
        c(width = 1800L, height = 900L)
      ),
    "retained read-back identity and figure dimensions"
  )
  cat(sprintf(
    "Generated Goal 011 review pack at %s (exactly four files).\n",
    destination
  ))
}

main()
