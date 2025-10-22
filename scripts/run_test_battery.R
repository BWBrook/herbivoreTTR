# Run the full HerbivoreTTR test battery: pipeline, unit tests, optional coverage

message("== HerbivoreTTR Test Battery ==")

if (!exists("init_project_options")) {
  for (f in list.files("R", full.names = TRUE)) {
    sys.source(f, envir = globalenv())
  }
}

message("[1/4] Initialising project options")
init_project_options()

message("[2/4] Executing pipeline via targets::tar_make()")
targets::tar_make(callr_function = NULL)

message("[3/4] Running unit and integration tests")

ensure_log_dir <- function(path) {
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  path
}

write_test_log <- function(results, log_path, timestamp_run) {
  severity <- c(pass = 1, warn = 2, skip = 3, fail = 4, error = 5)
  entries <- new.env(parent = emptyenv())

  status_from_expectation <- function(exp) {
    if (inherits(exp, "expectation_failure")) return("fail")
    if (inherits(exp, "expectation_error")) return("error")
    if (inherits(exp, "expectation_warning")) return("warn")
    if (inherits(exp, "expectation_skip")) return("skip")
    "pass"
  }

  add_entry <- function(suite, test_name, status, note) {
    key <- paste0(suite, "||", test_name)
    entry <- if (exists(key, envir = entries, inherits = FALSE)) {
      get(key, envir = entries, inherits = FALSE)
    } else {
      list(suite = suite, test = test_name, status = "pass", notes = character())
    }
    if (!is.null(severity[status]) && severity[status] > severity[entry$status]) {
      entry$status <- status
    }
    if (!is.null(note) && nzchar(note) && !identical(status, "pass")) {
      entry$notes <- unique(c(entry$notes, trimws(note)))
    }
    assign(key, entry, envir = entries)
  }

  for (res in results) {
    suite <- res$context
    if (is.null(suite) || !nzchar(suite)) {
      suite <- tools::file_path_sans_ext(basename(res$file))
    }
    if (length(res$results) == 0) {
      add_entry(suite, res$test %||% suite, "pass", NULL)
    }
    for (exp in res$results) {
      test_name <- exp$test
      if (is.null(test_name) || !nzchar(test_name)) {
        test_name <- suite
      }
      status <- status_from_expectation(exp)
      note <- conditionMessage(exp)
      add_entry(suite, test_name, status, note)
    }
  }

  entries_list <- as.list(entries)
  if (!length(entries_list)) return(invisible(NULL))

  log_df <- do.call(rbind, lapply(entries_list, function(entry) {
    data.frame(
      timestamp = timestamp_run,
      suite = entry$suite,
      test_name = entry$test,
      status = entry$status,
      duration_ms = "",
      notes = paste(entry$notes, collapse = " | "),
      stringsAsFactors = FALSE
    )
  }))

  write.table(
    log_df,
    file = log_path,
    sep = ",",
    row.names = FALSE,
    col.names = FALSE,
    quote = TRUE,
    append = TRUE
  )
  invisible(NULL)
}

`%||%` <- function(x, y) {
  if (is.null(x) || !nzchar(x)) y else x
}

log_dir <- ensure_log_dir(file.path("data", "outputs"))
timestamp_run <- format(Sys.time(), "%Y-%m-%dT%H:%M:%S")
log_path <- file.path(log_dir, sprintf("test_log_%s.csv", gsub("[^0-9]", "", timestamp_run)))
if (!file.exists(log_path)) {
  writeLines("timestamp,suite,test_name,status,duration_ms,notes", log_path)
}

list_reporter <- testthat::ListReporter$new()
summary_reporter <- testthat::SummaryReporter$new()
multi_reporter <- testthat::MultiReporter$new(list(summary_reporter, list_reporter))

testthat::test_dir("tests/testthat", reporter = multi_reporter)

write_test_log(list_reporter$get_results(), log_path, timestamp_run)
message(sprintf("Test log written to %s", log_path))

if (Sys.getenv("RUN_COVERAGE") == "1") {
  message("[4/4] Computing package coverage")
  cov <- covr::package_coverage(type = "tests", quiet = TRUE)
  message(sprintf("Coverage: %.2f%%", covr::percent_coverage(cov)))
} else {
  message("[4/4] Skipping coverage (set RUN_COVERAGE=1 to enable)")
}

message("== Test battery completed ==")
