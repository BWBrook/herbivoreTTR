arguments <- commandArgs(trailingOnly = TRUE)
if (length(arguments) != 1L || !nzchar(arguments[[1L]])) {
  stop("Review pack requires exactly one non-empty output directory argument.", call. = FALSE)
}

output_directory <- arguments[[1L]]
declared_files <- c(
  "figure-1-synthetic-intake-ceiling-threshold.png",
  "table-1-hourly-ceiling-screen.csv",
  "table-2-threshold-summary.csv",
  "table-3-daily-accounting.csv"
)

require_that <- function(condition, label) {
  if (length(condition) != 1L || !isTRUE(condition)) {
    stop(sprintf("Review-pack validation failed: %s.", label), call. = FALSE)
  }
  invisible(NULL)
}

is_link <- function(path) {
  target <- Sys.readlink(path)
  length(target) == 1L && !is.na(target) && nzchar(target)
}

path_exists <- function(path) file.exists(path) || dir.exists(path) || is_link(path)

absolute_path <- function(path) {
  if (startsWith(path, "/")) path else file.path(getwd(), path)
}

require_no_link_ancestors <- function(path) {
  pieces <- strsplit(sub("^/+", "", absolute_path(path)), "/", fixed = TRUE)[[1L]]
  current <- "/"
  for (piece in pieces) {
    if (!nzchar(piece) || piece == ".") next
    current <- if (piece == "..") dirname(current) else file.path(current, piece)
    if (path_exists(current)) {
      require_that(!is_link(current), paste("symbolic-link path component:", current))
    } else break
  }
  invisible(NULL)
}

near <- function(observed, expected) {
  observed <- as.double(observed)
  expected <- as.double(expected)
  length(observed) == length(expected) &&
    all(is.finite(observed)) && all(is.finite(expected)) &&
    all(abs(observed - expected) <= 100 * .Machine$double.eps * pmax(1, abs(observed), abs(expected)))
}

same_table <- function(left, right) {
  row.names(left) <- NULL
  row.names(right) <- NULL
  identical(names(left), names(right)) && identical(dim(left), dim(right)) &&
    all(vapply(names(left), function(name) {
      x <- left[[name]]
      y <- right[[name]]
      if (is.numeric(x) && is.numeric(y)) return(near(x, y))
      identical(x, y)
    }, logical(1L)))
}

# Source the no-write experiment into an isolated environment and reuse its
# in-memory evidence object. The experiment itself remains the sole model
# execution client; this wrapper only validates and serializes its outputs.
evidence_environment <- new.env(parent = globalenv())
script_argument <- grep("^--file=", commandArgs(), value = TRUE)
repo_root <- if (length(script_argument) == 1L) {
  dirname(dirname(sub("^--file=", "", script_argument)))
} else {
  output_candidate <- normalizePath(file.path(dirname(absolute_path(output_directory)), ".."), mustWork = FALSE)
  if (file.exists(file.path(output_candidate, "experiments", "rebuild-009-synthetic-intake-ceiling-threshold.R"))) output_candidate else getwd()
}
sys.source(file.path(repo_root, "experiments", "rebuild-009-synthetic-intake-ceiling-threshold.R"), envir = evidence_environment)
evidence <- evidence_environment$goal009_evidence
require_that(is.list(evidence), "in-memory evidence object")

hourly <- evidence$hourly_screen
threshold <- evidence$threshold_summary
daily <- evidence$daily_accounting
hourly_names <- c(
  "scenario_id", "hour_of_day", "candidate_prescribed_dry_matter_intake_kg_dm_h",
  "synthetic_intake_ceiling_kg_dm_h", "constrained_prescribed_dry_matter_intake_kg_dm_h",
  "curtailed_prescribed_dry_matter_intake_kg_dm_h", "ceiling_exceeded"
)
threshold_names <- c(
  "scenario_id", "active_ceiling_kg_dm_h", "active_ceiling_energy_equivalent_kj_h",
  "threshold_multiple", "threshold_relation", "curtailed_active_intervals",
  "touching_active_intervals", "daily_candidate_intake_kg_dm", "daily_ceiling_capacity_kg_dm",
  "daily_constrained_intake_kg_dm", "daily_curtailed_intake_kg_dm",
  "daily_constrained_energy_kj", "daily_energy_shortfall_kj",
  "daily_unused_ceiling_headroom_kg_dm", "daily_unused_ceiling_headroom_kj"
)
daily_names <- c(
  "scenario_id", "measurement_day", "daily_candidate_intake_kg_dm",
  "daily_constrained_intake_kg_dm", "daily_curtailed_intake_kg_dm",
  "total_constrained_energy_input_kj", "total_assimilated_energy_kj",
  "total_maintenance_expenditure_kj", "total_routine_activity_expenditure_kj",
  "observed_body_energy_change_kj", "body_energy_reserve_final_kj",
  "body_energy_status", "goal008_oracle_scenario_id", "exact_oracle_identity"
)
require_that(identical(names(hourly), hourly_names) && identical(dim(hourly), c(72L, 7L)), "table 1 schema and dimensions")
require_that(identical(names(threshold), threshold_names) && identical(dim(threshold), c(3L, 15L)), "table 2 schema and dimensions")
require_that(identical(names(daily), daily_names) && identical(dim(daily), c(6L, 14L)), "table 3 schema and dimensions")
require_that(identical(as.character(threshold$threshold_relation), c("below", "at", "above")), "scenario order and relation")
require_that(identical(threshold$curtailed_active_intervals, c(16L, 0L, 0L)) && identical(threshold$touching_active_intervals, c(0L, 16L, 0L)), "interval counts")
require_that(near(threshold$daily_constrained_energy_kj, c(2400, 3200, 3200)) && near(threshold$daily_energy_shortfall_kj, c(800, 0, 0)), "threshold accounting")
require_that(near(threshold$daily_unused_ceiling_headroom_kj, c(0, 0, 800)), "headroom accounting")
require_that(identical(daily$exact_oracle_identity, rep(TRUE, 6L)), "Goal 008 identities")
require_that(near(daily$body_energy_reserve_final_kj, c(9200, 8400, 10000, 10000, 10000, 10000)), "body closes")

require_no_link_ancestors(output_directory)
if (path_exists(output_directory)) {
  require_that(!is_link(output_directory) && dir.exists(output_directory), "output directory is a regular directory")
  existing <- list.files(output_directory, all.files = TRUE, no.. = TRUE)
  require_that(all(existing %in% declared_files), "no undeclared destination entries")
  if (length(existing)) {
    require_that(!any(vapply(file.path(output_directory, existing), is_link, logical(1L))), "no symbolic-link outputs")
  }
} else {
  require_that(dir.create(output_directory, recursive = FALSE), "create output directory")
}

stage_directory <- tempfile("rebuild009-review-stage-", tmpdir = tempdir())
require_that(dir.create(stage_directory, recursive = FALSE), "create guarded staging directory")
old_options <- options(digits = 17)

write_csv <- function(value, filename) {
  target <- file.path(stage_directory, filename)
  utils::write.csv(value, target, row.names = FALSE, quote = TRUE)
  require_that(file.exists(target) && !is_link(target) && !isTRUE(file.info(target)$isdir), paste("staged regular file:", filename))
}
write_csv(hourly, declared_files[[2L]])
write_csv(threshold, declared_files[[3L]])
write_csv(daily, declared_files[[4L]])

png_target <- file.path(stage_directory, declared_files[[1L]])
grDevices::png(png_target, width = 1800, height = 900, res = 150)
graphics::par(mfrow = c(1, 3), mar = c(4.4, 4.4, 3.0, 1.2), mgp = c(2.4, 0.8, 0))
ceiling_energy <- seq(100, 300, length.out = 201)
constrained_energy <- 16 * pmin(ceiling_energy / 10000, evidence$threshold_active_ceiling_kg_dm_h) * 10000
plot(ceiling_energy, constrained_energy, type = "l", lwd = 2, col = "#1f4e79",
  xlab = "Synthetic active ceiling (kJ/h)", ylab = "Daily constrained energy (kJ)", main = "Analytical ceiling response")
abline(h = 3200, lty = 2, col = "#444444")
abline(v = 200, lty = 2, col = "#b22222")
points(threshold$active_ceiling_energy_equivalent_kj_h, threshold$daily_constrained_energy_kj, pch = 19, col = c("#377eb8", "#4daf4a", "#e41a1c"))
text(200, 3200, "  required = 3200 kJ", pos = 3, cex = 0.8)
text(200, 300, "threshold = 200 kJ/h", pos = 4, cex = 0.8, col = "#b22222")

body_change <- constrained_energy - 3200
plot(ceiling_energy, body_change, type = "l", lwd = 2, col = "#1f4e79",
  xlab = "Synthetic active ceiling (kJ/h)", ylab = "Daily body-energy change (kJ)", main = "Analytical daily body change")
abline(h = 0, lty = 2, col = "#444444")
abline(v = 200, lty = 2, col = "#b22222")
points(threshold$active_ceiling_energy_equivalent_kj_h, threshold$daily_constrained_energy_kj - 3200, pch = 19, col = c("#377eb8", "#4daf4a", "#e41a1c"))
text(200, 90, "zero change", pos = 4, cex = 0.8)

body_boundaries_kj <- function(hourly) c(hourly$body_energy_reserve_start_kj[[1L]], hourly$body_energy_reserve_end_kj)
all_body_boundaries <- unlist(lapply(evidence$fixtures, function(fixture) body_boundaries_kj(fixture$model$result$hourly)), use.names = FALSE)
body_limits <- range(all_body_boundaries)
body_padding <- max(100, 0.05 * diff(body_limits))
plot(0:48, body_boundaries_kj(evidence$fixtures[[1L]]$model$result$hourly), type = "l", lwd = 2,
  col = "#377eb8", ylim = body_limits + c(-body_padding, body_padding), xlab = "Measured time (h)", ylab = "Body-energy reserve (kJ)", main = "Measured reserve trajectories")
for (index in 2:3) lines(0:48, body_boundaries_kj(evidence$fixtures[[index]]$model$result$hourly),
  lwd = 2, lty = c(1, 2)[index - 1L], col = c("#4daf4a", "#e41a1c")[index - 1L])
abline(h = 10000, lty = 2, col = "#444444")
legend("bottomleft", legend = c("below threshold", "at threshold", "above threshold"),
  col = c("#377eb8", "#4daf4a", "#e41a1c"), lwd = 2, lty = c(1, 1, 2), bty = "n", cex = 0.75)
grDevices::dev.off()
require_that(file.exists(png_target) && !is_link(png_target) && file.info(png_target)$size > 0, "non-empty staged figure")

read_hourly <- utils::read.csv(file.path(stage_directory, declared_files[[2L]]), stringsAsFactors = FALSE, check.names = FALSE)
read_threshold <- utils::read.csv(file.path(stage_directory, declared_files[[3L]]), stringsAsFactors = FALSE, check.names = FALSE)
read_daily <- utils::read.csv(file.path(stage_directory, declared_files[[4L]]), stringsAsFactors = FALSE, check.names = FALSE)
require_that(same_table(read_hourly, hourly) && same_table(read_threshold, threshold) && same_table(read_daily, daily), "CSV read-back reconstruction")

for (filename in declared_files) {
  source_file <- file.path(stage_directory, filename)
  destination_file <- file.path(output_directory, filename)
  require_that(!is_link(source_file) && !isTRUE(file.info(source_file)$isdir), paste("regular staged source:", filename))
  require_that(file.rename(source_file, destination_file), paste("replace retained output:", filename))
}
retained <- list.files(output_directory, all.files = TRUE, no.. = TRUE)
require_that(identical(sort(retained), sort(declared_files)), "exact retained output set")
require_that(all(vapply(file.path(output_directory, retained), function(path) !is_link(path) && !isTRUE(file.info(path)$isdir), logical(1L))), "regular retained outputs")
retained_hourly <- utils::read.csv(file.path(output_directory, declared_files[[2L]]), stringsAsFactors = FALSE, check.names = FALSE)
retained_threshold <- utils::read.csv(file.path(output_directory, declared_files[[3L]]), stringsAsFactors = FALSE, check.names = FALSE)
retained_daily <- utils::read.csv(file.path(output_directory, declared_files[[4L]]), stringsAsFactors = FALSE, check.names = FALSE)
require_that(same_table(retained_hourly, hourly) && same_table(retained_threshold, threshold) && same_table(retained_daily, daily), "retained CSV read-back reconstruction")
unlink(stage_directory, recursive = TRUE, force = TRUE)
options(old_options)
cat("Goal 009 review pack written: exactly four retained regular files.\n")
