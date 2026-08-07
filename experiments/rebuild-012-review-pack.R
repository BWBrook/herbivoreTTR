declared_files <- c(
  "figure-1-prescribed-energy-repayment-pulse.png",
  "table-1-hourly-boundary-contrasts.csv",
  "table-2-daily-sequences.csv",
  "table-3-day-boundary-realignment.csv"
)

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

require_that <- function(condition, label) {
  if (length(condition) != 1L || !isTRUE(condition)) {
    stop(
      sprintf("Goal 012 review-pack validation failed: %s.", label),
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

within_rounding_tolerance <- function(observed, expected, tolerance_kj) {
  observed <- as.double(observed)
  expected <- as.double(expected)
  length(observed) == length(expected) &&
    all(is.finite(observed)) &&
    all(is.finite(expected)) &&
    all(abs(observed - expected) <= tolerance_kj)
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
      "rebuild-012-prescribed-energy-repayment-pulse.R"
    )
    if (file.exists(experiment)) return(candidate)
  }
  stop("Could not locate the Goal 012 experiment.", call. = FALSE)
}

load_evidence <- function(destination) {
  environment <- new.env(parent = globalenv())
  repo_root <- find_repo_root(destination)
  sys.source(
    file.path(
      repo_root,
      "experiments",
      "rebuild-012-prescribed-energy-repayment-pulse.R"
    ),
    envir = environment
  )
  evidence <- environment$goal012_evidence
  require_that(is.list(evidence), "single in-memory evidence object")
  evidence
}

raw_boundary_values <- function(sequence, stock) {
  start_field <- paste0(stock, "_start_kj")
  end_field <- paste0(stock, "_end_kj")
  c(
    sequence$days[[1L]]$hourly[[start_field]][[1L]],
    unlist(
      lapply(sequence$days, function(day) day$hourly[[end_field]]),
      use.names = FALSE
    )
  )
}

assemble_reference_schema <- function(days) {
  hourly <- do.call(rbind, lapply(seq_along(days), function(index) {
    data.frame(
      measurement_day = rep(as.integer(index), 24L),
      days[[index]]$hourly,
      row.names = NULL
    )
  }))
  daily <- do.call(rbind, lapply(seq_along(days), function(index) {
    data.frame(
      measurement_day = as.integer(index),
      days[[index]]$daily,
      row.names = NULL
    )
  }))
  row.names(hourly) <- seq_len(nrow(hourly))
  row.names(daily) <- seq_len(nrow(daily))
  list(hourly = hourly, daily = daily)
}

raw_contrast_context <- function(evidence) {
  control <- evidence$sequences$all_balanced_control
  treatment <- evidence$sequences$shortfall_then_repayment
  balanced_input <- evidence$schedules$balanced_energy$
    prescribed_ingested_available_energy_kj_h
  shortfall_input <- evidence$schedules$shortfall_energy$
    prescribed_ingested_available_energy_kj_h
  repayment_input <- evidence$schedules$repayment_energy$
    prescribed_ingested_available_energy_kj_h
  control_input <- rep(balanced_input, 4L)
  treatment_input <- c(
    shortfall_input,
    repayment_input,
    rep(balanced_input, 2L)
  )
  hourly_input_contrast <- treatment_input - control_input
  cumulative_input_contrast <- c(
    0,
    cumsum(hourly_input_contrast)
  )
  expected_gut_contrast <- numeric(97L)
  for (index in seq_len(96L)) {
    expected_gut_contrast[[index + 1L]] <-
      0.75 * expected_gut_contrast[[index]] +
        hourly_input_contrast[[index]]
  }
  control_gut <- raw_boundary_values(control, "gut_available_energy")
  treatment_gut <- raw_boundary_values(
    treatment,
    "gut_available_energy"
  )
  control_body <- raw_boundary_values(control, "body_energy_reserve")
  treatment_body <- raw_boundary_values(
    treatment,
    "body_energy_reserve"
  )
  control_system <- raw_boundary_values(control, "total_system_energy")
  treatment_system <- raw_boundary_values(
    treatment,
    "total_system_energy"
  )
  gut_contrast <- treatment_gut - control_gut
  body_contrast <- treatment_body - control_body
  combined_contrast <- gut_contrast + body_contrast

  list(
    control = control,
    treatment = treatment,
    control_input = control_input,
    treatment_input = treatment_input,
    hourly_input_contrast = hourly_input_contrast,
    cumulative_input_contrast = cumulative_input_contrast,
    expected_gut_contrast = expected_gut_contrast,
    expected_body_contrast =
      cumulative_input_contrast - expected_gut_contrast,
    gut_contrast = gut_contrast,
    body_contrast = body_contrast,
    combined_contrast = combined_contrast,
    system_contrast = treatment_system - control_system
  )
}

validate_raw_evidence <- function(evidence) {
  require_that(
    is.list(evidence) &&
      is.list(evidence$schedules) &&
      is.list(evidence$sequences) &&
      is.list(evidence$balanced_reference),
    "raw evidence structure"
  )
  expected_forcing_phases <- list(
    all_balanced_control = rep("balanced", 4L),
    shortfall_then_repayment = c(
      "shortfall",
      "prescribed_repayment_pulse",
      rep("return_to_reference", 2L)
    )
  )
  require_that(
    identical(names(evidence$sequences), names(expected_forcing_phases)) &&
      all(vapply(names(expected_forcing_phases), function(sequence_id) {
        sequence <- evidence$sequences[[sequence_id]]
        is.list(sequence) &&
          identical(sequence$sequence_id, sequence_id) &&
          identical(
            sequence$forcing_phases,
            expected_forcing_phases[[sequence_id]]
          ) &&
          is.list(sequence$days) &&
          length(sequence$days) == 4L
      }, logical(1L))),
    "raw sequence identities and forcing phases"
  )
  require_that(
    identical(
      evidence$schedules$balanced_dry_matter$
        prescribed_dry_matter_intake_kg_dm_h,
      c(rep(0.020, 8L), rep(0, 8L), rep(0.020, 8L))
    ) &&
      identical(
        evidence$schedules$shortfall_dry_matter$
          prescribed_dry_matter_intake_kg_dm_h,
        c(rep(0.015, 8L), rep(0, 8L), rep(0.015, 8L))
      ) &&
      identical(
        evidence$schedules$repayment_dry_matter$
          prescribed_dry_matter_intake_kg_dm_h,
        c(rep(0.025, 8L), rep(0, 8L), rep(0.025, 8L))
      ) &&
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
        evidence$schedules$repayment_energy$
          prescribed_ingested_available_energy_kj_h,
        c(rep(250, 8L), rep(0, 8L), rep(250, 8L))
      ) &&
      identical(
        evidence$schedules$routine_activity$
          prescribed_routine_activity_expenditure_kj_h,
        c(rep(50, 8L), rep(0, 8L), rep(50, 8L))
      ),
    "raw exact schedules"
  )

  control <- evidence$sequences$all_balanced_control
  treatment <- evidence$sequences$shortfall_then_repayment
  require_that(
    identical(
      control$days[[1L]]$daily$gut_available_energy_initial_kj,
      treatment$days[[1L]]$daily$gut_available_energy_initial_kj
    ) &&
      identical(
        control$days[[1L]]$daily$body_energy_reserve_initial_kj,
        treatment$days[[1L]]$daily$body_energy_reserve_initial_kj
      ) &&
      identical(
        control$days[[1L]]$daily$body_energy_reserve_initial_kj,
        10000
      ),
    "raw common sequence initialization"
  )
  for (sequence in evidence$sequences) {
    for (sequence_day in seq_along(sequence$days)) {
      result <- sequence$days[[sequence_day]]
      hourly <- result$hourly
      daily <- result$daily
      stocks <- unlist(
        hourly[c(
          "gut_available_energy_start_kj",
          "gut_available_energy_end_kj",
          "body_energy_reserve_start_kj",
          "body_energy_reserve_end_kj"
        )],
        use.names = FALSE
      )
      require_that(
        identical(
          hourly$gut_available_energy_start_kj[-1L],
          head(hourly$gut_available_energy_end_kj, -1L)
        ) &&
          identical(
            hourly$body_energy_reserve_start_kj[-1L],
            head(hourly$body_energy_reserve_end_kj, -1L)
          ) &&
          all(is.finite(stocks)) &&
          all(stocks >= 0),
        paste(sequence$sequence_id, sequence_day, "raw hourly continuity")
      )
      if (sequence_day > 1L) {
        previous <- sequence$days[[sequence_day - 1L]]$daily
        require_that(
          identical(
            daily$gut_available_energy_initial_kj,
            previous$gut_available_energy_final_kj
          ) &&
            identical(
              daily$body_energy_reserve_initial_kj,
              previous$body_energy_reserve_final_kj
            ) &&
            identical(
              daily$total_system_energy_initial_kj,
              previous$total_system_energy_final_kj
            ),
          paste(sequence$sequence_id, sequence_day, "raw day continuity")
        )
      }
    }
  }

  control_goal008_schema <- assemble_reference_schema(control$days[1:2])
  require_that(
    identical(
      control_goal008_schema,
      evidence$balanced_reference[c("hourly", "daily")]
    ),
    "raw first-two-day Goal 008 identity"
  )

  context <- raw_contrast_context(evidence)
  day_indices <- c(1L, 25L, 49L, 73L, 97L)
  expected_gut_fixture <- c(
    0,
    -181.781257888200543,
    181.598860159612849,
    0.182214712297783,
    0.000182832652961
  )
  expected_combined_fixture <- c(0, -800, 0, 0, 0)
  require_that(
    identical(context$hourly_input_contrast[1:24], c(
      rep(-50, 8L),
      rep(0, 8L),
      rep(-50, 8L)
    )) &&
      identical(context$hourly_input_contrast[25:48], c(
        rep(50, 8L),
        rep(0, 8L),
        rep(50, 8L)
      )) &&
      identical(context$hourly_input_contrast[49:96], rep(0, 48L)),
    "raw hourly prescribed-input contrast"
  )
  require_that(
    near(
      context$gut_contrast,
      context$expected_gut_contrast,
      scale = 800
    ) &&
      near(
        context$body_contrast,
        context$expected_body_contrast,
        scale = 10000
      ) &&
      near(
        context$combined_contrast,
        context$cumulative_input_contrast,
        scale = 10000
      ) &&
      near(
        context$system_contrast,
        context$combined_contrast,
        scale = 10000
      ),
    "raw analytical gut, body, and system contrasts"
  )
  require_that(
    near(
      context$gut_contrast[50:97],
      0.75 * context$gut_contrast[49:96],
      scale = 800
    ) &&
      near(
        context$gut_contrast[c(73L, 97L)],
        context$gut_contrast[c(49L, 73L)] * 0.75^24,
        scale = 800
      ),
    "raw post-pulse hourly and daily gut contraction"
  )
  require_that(
    near(
      context$gut_contrast[day_indices],
      expected_gut_fixture,
      scale = 800
    ) &&
      near(
        context$combined_contrast[day_indices],
        expected_combined_fixture,
        scale = 10000
      ) &&
      near(
        context$body_contrast[day_indices],
        expected_combined_fixture - expected_gut_fixture,
        scale = 10000
      ),
    "raw retained day-boundary oracle"
  )
  invisible(NULL)
}

reconstruct_hourly_table <- function(evidence) {
  context <- raw_contrast_context(evidence)
  data.frame(
    elapsed_time_h = 0:96,
    boundary_phase = c(
      "initial",
      rep("shortfall_day", 24L),
      rep("prescribed_repayment_pulse_day", 24L),
      rep("return_to_reference_day_1", 24L),
      rep("return_to_reference_day_2", 24L)
    ),
    cumulative_prescribed_input_contrast_kj =
      context$cumulative_input_contrast,
    gut_available_energy_contrast_kj = context$gut_contrast,
    body_energy_reserve_contrast_kj = context$body_contrast,
    combined_system_energy_contrast_kj = context$combined_contrast,
    contrast_closure_residual_kj =
      context$combined_contrast - context$cumulative_input_contrast,
    row.names = NULL
  )
}

reconstruct_daily_table <- function(evidence) {
  sequence_ids <- c(
    "all_balanced_control",
    "shortfall_then_repayment"
  )
  declared_forcing_phases <- list(
    all_balanced_control = rep("balanced", 4L),
    shortfall_then_repayment = c(
      "shortfall",
      "prescribed_repayment_pulse",
      rep("return_to_reference", 2L)
    )
  )
  dry_matter_totals <- c(
    balanced = sum(
      evidence$schedules$balanced_dry_matter$
        prescribed_dry_matter_intake_kg_dm_h
    ),
    shortfall = sum(
      evidence$schedules$shortfall_dry_matter$
        prescribed_dry_matter_intake_kg_dm_h
    ),
    prescribed_repayment_pulse = sum(
      evidence$schedules$repayment_dry_matter$
        prescribed_dry_matter_intake_kg_dm_h
    ),
    return_to_reference = sum(
      evidence$schedules$balanced_dry_matter$
        prescribed_dry_matter_intake_kg_dm_h
    )
  )

  expected <- do.call(rbind, lapply(sequence_ids, function(sequence_id) {
    sequence <- evidence$sequences[[sequence_id]]
    phases <- declared_forcing_phases[[sequence_id]]
    do.call(rbind, lapply(seq_along(sequence$days), function(sequence_day) {
      result <- sequence$days[[sequence_day]]$daily
      phase <- phases[[sequence_day]]
      data.frame(
        sequence_id = sequence_id,
        sequence_day = as.integer(sequence_day),
        forcing_phase = phase,
        daily_prescribed_dry_matter_intake_kg_dm =
          dry_matter_totals[[phase]],
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
  row.names(expected) <- NULL
  expected
}

reconstruct_boundary_table <- function(evidence) {
  context <- raw_contrast_context(evidence)
  selected <- c(1L, 25L, 49L, 73L, 97L)
  data.frame(
    elapsed_time_h = c(0L, 24L, 48L, 72L, 96L),
    boundary_label = c(
      "initial",
      "shortfall_day_close",
      "prescribed_repayment_pulse_day_close",
      "return_to_reference_day_1_close",
      "return_to_reference_day_2_close"
    ),
    cumulative_prescribed_input_contrast_kj =
      context$cumulative_input_contrast[selected],
    gut_available_energy_contrast_kj =
      context$gut_contrast[selected],
    expected_gut_contrast_kj =
      context$expected_gut_contrast[selected],
    gut_contraction_factor_from_previous_boundary = c(
      NA_real_,
      NA_real_,
      NA_real_,
      rep(0.75^24, 2L)
    ),
    body_energy_reserve_contrast_kj =
      context$body_contrast[selected],
    expected_body_complement_kj =
      context$expected_body_contrast[selected],
    combined_system_energy_contrast_kj =
      context$combined_contrast[selected],
    contrast_closure_residual_kj =
      context$combined_contrast[selected] -
        context$cumulative_input_contrast[selected],
    row.names = NULL
  )
}

validate_evidence <- function(evidence, tables) {
  validate_raw_evidence(evidence)
  require_that(
    is.list(tables) &&
      identical(names(tables), c("hourly", "daily", "boundaries")),
    "three named evidence tables"
  )
  hourly <- tables$hourly
  daily <- tables$daily
  boundaries <- tables$boundaries
  require_that(
    identical(names(hourly), hourly_names) &&
      identical(dim(hourly), c(97L, 7L)),
    "table 1 schema and dimensions"
  )
  require_that(
    identical(names(daily), daily_names) &&
      identical(dim(daily), c(8L, 16L)),
    "table 2 schema and dimensions"
  )
  require_that(
    identical(names(boundaries), boundary_names) &&
      identical(dim(boundaries), c(5L, 10L)),
    "table 3 schema and dimensions"
  )

  expected_hourly <- reconstruct_hourly_table(evidence)
  expected_daily <- reconstruct_daily_table(evidence)
  expected_boundaries <- reconstruct_boundary_table(evidence)
  require_that(
    same_table(hourly, expected_hourly),
    "table 1 complete reconstruction from raw sequences and schedules"
  )
  require_that(
    same_table(daily, expected_daily),
    "table 2 complete reconstruction from raw daily results and schedules"
  )
  require_that(
    same_table(boundaries, expected_boundaries),
    "table 3 complete reconstruction from raw sequences and recurrence"
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
    within_rounding_tolerance(
      daily$expected_body_energy_change_kj,
      daily$total_assimilated_energy_kj -
        daily$total_maintenance_expenditure_kj -
        daily$total_routine_activity_expenditure_kj,
      2
    ) &&
      within_rounding_tolerance(
        daily$observed_body_energy_change_kj,
        daily$body_energy_reserve_final_kj -
          daily$body_energy_reserve_initial_kj,
        2
      ) &&
      within_rounding_tolerance(
        daily$gut_available_energy_final_kj -
          daily$gut_available_energy_initial_kj,
        daily$total_prescribed_energy_input_kj -
          daily$total_assimilated_energy_kj,
        2
      ),
    "table 2 rounded gut and body accounting"
  )
  require_that(
    within_rounding_tolerance(
      daily$total_system_energy_initial_kj,
      daily$gut_available_energy_initial_kj +
        daily$body_energy_reserve_initial_kj,
      2
    ) &&
      within_rounding_tolerance(
        daily$total_system_energy_final_kj,
        daily$gut_available_energy_final_kj +
          daily$body_energy_reserve_final_kj,
        2
      ) &&
      within_rounding_tolerance(
        daily$total_system_energy_final_kj -
          daily$total_system_energy_initial_kj,
        daily$total_prescribed_energy_input_kj -
          daily$total_maintenance_expenditure_kj -
          daily$total_routine_activity_expenditure_kj,
        3
      ),
    "table 2 rounded whole-system accounting"
  )
  carry_indices <- list(1:4, 5:8)
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
  invisible(NULL)
}

mutate_column <- function(table, column_name) {
  mutated <- table
  value <- mutated[[column_name]]
  missing_index <- which(is.na(value))
  if (is.numeric(value)) {
    if (length(missing_index) > 0L) {
      value[[missing_index[[1L]]]] <- 0
    } else if (is.integer(value)) {
      value[[1L]] <- value[[1L]] + 1L
    } else {
      value[[1L]] <- value[[1L]] + 1
    }
  } else if (is.character(value)) {
    value[[1L]] <- paste0(value[[1L]], "_mutation")
  } else if (is.logical(value)) {
    value[[1L]] <- !value[[1L]]
  } else {
    stop("Unsupported table column type for mutation probe.", call. = FALSE)
  }
  mutated[[column_name]] <- value
  mutated
}

mutation_probe_tables <- function(evidence, tables, context_label) {
  mutation_count <- 0L
  for (table_name in names(tables)) {
    for (column_name in names(tables[[table_name]])) {
      mutated_tables <- tables
      mutated_tables[[table_name]] <- mutate_column(
        tables[[table_name]],
        column_name
      )
      require_that(
        !identical(
          mutated_tables[[table_name]][[column_name]],
          tables[[table_name]][[column_name]]
        ),
        paste(context_label, table_name, column_name, "probe changed value")
      )
      rejected <- tryCatch(
        {
          validate_evidence(evidence, mutated_tables)
          FALSE
        },
        error = function(error) TRUE
      )
      require_that(
        rejected,
        paste(context_label, table_name, column_name, "mutation rejected")
      )
      mutation_count <- mutation_count + 1L
    }
  }
  mutation_count
}

write_figure <- function(evidence, path) {
  hourly <- reconstruct_hourly_table(evidence)
  context <- raw_contrast_context(evidence)
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
      c(0, 24, 48, 72),
      y_bottom,
      c(24, 48, 72, 96),
      y_top,
      col = c("#F2F2F2", "#E8F1F5", "#F7F7F7", "#EDF4EC"),
      border = NA
    )
  }

  input_time <- 0:96
  control_input <- c(
    context$control_input,
    tail(context$control_input, 1L)
  )
  treatment_input <- c(
    context$treatment_input,
    tail(context$treatment_input, 1L)
  )
  graphics::plot(
    NA,
    NA,
    xlim = c(0, 96),
    ylim = c(0, 285),
    xaxs = "i",
    yaxs = "i",
    xlab = "Elapsed time (h)",
    ylab = "Prescribed energy input (kJ/h)",
    main = "Prescribed forcing"
  )
  phase_rectangles(0, 285)
  graphics::lines(
    input_time,
    control_input,
    type = "s",
    lwd = 2.4,
    col = "#0072B2"
  )
  graphics::lines(
    input_time,
    treatment_input,
    type = "s",
    lwd = 2.2,
    lty = 2,
    col = "#D55E00"
  )
  graphics::abline(v = c(24, 48, 72), lty = 3, col = "#777777")
  graphics::text(
    c(12, 36, 60, 84),
    274,
    c(
      "Shortfall day",
      "Prescribed\nrepayment pulse",
      "Return-to-reference\nforcing",
      "Return-to-reference\nforcing"
    ),
    cex = 0.57
  )
  graphics::legend(
    "bottomleft",
    legend = c("All-balanced control", "Shortfall then repayment"),
    col = c("#0072B2", "#D55E00"),
    lty = c(1, 2),
    lwd = 2.3,
    bty = "n",
    cex = 0.75
  )

  partition_values <- c(
    hourly$gut_available_energy_contrast_kj,
    hourly$body_energy_reserve_contrast_kj
  )
  partition_range <- range(partition_values)
  partition_padding <- max(25, 0.08 * diff(partition_range))
  partition_limits <- c(
    floor((partition_range[[1L]] - partition_padding) / 50) * 50,
    ceiling((partition_range[[2L]] + partition_padding) / 50) * 50
  )
  graphics::plot(
    NA,
    NA,
    xlim = c(0, 96),
    ylim = partition_limits,
    xaxs = "i",
    yaxs = "i",
    xlab = "Elapsed boundary time (h)",
    ylab = "Treatment - control contrast (kJ)",
    main = "Gut and body partition"
  )
  phase_rectangles(partition_limits[[1L]], partition_limits[[2L]])
  graphics::abline(
    h = 0,
    v = c(24, 48, 72),
    lty = 3,
    col = "#777777"
  )
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
    "bottomright",
    legend = c("Gut stock", "Body reserve"),
    col = c("#009E73", "#D55E00"),
    lty = c(1, 2),
    lwd = 2.4,
    bty = "n",
    cex = 0.75
  )

  system_limits <- c(-850, 100)
  graphics::plot(
    NA,
    NA,
    xlim = c(0, 96),
    ylim = system_limits,
    xaxs = "i",
    yaxs = "i",
    xlab = "Elapsed boundary time (h)",
    ylab = "Treatment - control contrast (kJ)",
    main = "Whole-system contrast"
  )
  phase_rectangles(system_limits[[1L]], system_limits[[2L]])
  graphics::abline(
    h = 0,
    v = c(24, 48, 72),
    lty = 3,
    col = "#777777"
  )
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
    c(24, 48, 72, 96),
    c(-800, 0, 0, 0),
    pch = 19,
    col = "#222222"
  )
  graphics::text(24, -770, "-800 kJ", pos = 4, cex = 0.76)
  graphics::text(51, 42, "0 kJ from 48 h", pos = 4, cex = 0.76)
  graphics::legend(
    "bottomright",
    legend = c(
      "Cumulative prescribed input",
      "Combined system"
    ),
    col = c("#0072B2", "#222222"),
    lty = c(1, 2),
    lwd = c(4.0, 2.2),
    bty = "n",
    cex = 0.72
  )

  graphics::mtext(
    "Prescribed energy-repayment pulse",
    side = 3,
    outer = TRUE,
    line = 2.3,
    font = 2,
    cex = 1.15
  )
  graphics::mtext(
    paste0(
      "Direct exogenous pulse on day 2; days 3-4 use return-to-reference ",
      "forcing; contrasts are treatment minus control"
    ),
    side = 1,
    outer = TRUE,
    line = 1.3,
    cex = 0.74
  )
  grDevices::dev.off(device)
  on.exit(NULL)
}

validate_staged_pack <- function(evidence, source_tables, stage) {
  check_file_set(stage, exact = TRUE)
  csv_paths <- c(
    hourly = file.path(stage, declared_files[[2L]]),
    daily = file.path(stage, declared_files[[3L]]),
    boundaries = file.path(stage, declared_files[[4L]])
  )
  read_back <- lapply(csv_paths, read_csv)
  validate_evidence(evidence, read_back)
  require_that(
    all(vapply(names(source_tables), function(name) {
      same_table(read_back[[name]], source_tables[[name]])
    }, logical(1L))),
    "staged CSV read-back identity"
  )
  mutation_count <- mutation_probe_tables(
    evidence,
    read_back,
    "staged CSV read-back"
  )
  require_that(
    identical(
      png_dimensions(file.path(stage, declared_files[[1L]])),
      c(width = 1800L, height = 900L)
    ),
    "1800 x 900 staged figure"
  )
  list(tables = read_back, mutation_count = mutation_count)
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
  in_memory_mutations <- mutation_probe_tables(
    evidence,
    tables,
    "in-memory"
  )

  stage <- tempfile("rebuild012-review-pack-")
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
  write_figure(evidence, file.path(stage, declared_files[[1L]]))

  # All staged semantics and geometry pass before publication can replace an
  # existing destination.
  staged <- validate_staged_pack(evidence, tables, stage)
  publish_pack(stage, destination)
  check_file_set(destination, exact = TRUE)

  retained <- list(
    hourly = read_csv(file.path(destination, declared_files[[2L]])),
    daily = read_csv(file.path(destination, declared_files[[3L]])),
    boundaries = read_csv(file.path(destination, declared_files[[4L]]))
  )
  validate_evidence(evidence, retained)
  require_that(
    all(vapply(names(tables), function(name) {
      same_table(retained[[name]], tables[[name]])
    }, logical(1L))) &&
      identical(
        png_dimensions(file.path(destination, declared_files[[1L]])),
        c(width = 1800L, height = 900L)
      ),
    "retained read-back identity and figure dimensions"
  )
  retained_mutations <- mutation_probe_tables(
    evidence,
    retained,
    "retained CSV read-back"
  )
  require_that(
    identical(
      c(
        in_memory_mutations,
        staged$mutation_count,
        retained_mutations
      ),
      rep(33L, 3L)
    ),
    "all 99 declared column mutations rejected"
  )
  cat(sprintf(
    paste0(
      "Generated Goal 012 review pack at %s (exactly four files; ",
      "99 column mutations rejected).\n"
    ),
    destination
  ))
}

main()
