# Helper to record structured test logs for every testthat context

if (Sys.getenv("TEST_LOG_DISABLE", unset = "0") != "1") {
  test_log_env <- new.env(parent = emptyenv())

  get_project_root <- function() {
    if (requireNamespace("testthat", quietly = TRUE)) {
      root <- testthat::test_path("..", "..")
      return(normalizePath(root, mustWork = TRUE))
    }
    wd <- normalizePath(getwd(), mustWork = TRUE)
    if (basename(wd) == "testthat") {
      wd <- dirname(dirname(wd))
    }
    normalizePath(wd, mustWork = TRUE)
  }

  project_root <- get_project_root()
  timestamp <- format(Sys.time(), "%Y%m%d-%H%M%S")
  log_dir <- file.path(project_root, "data", "outputs")
  if (!dir.exists(log_dir)) {
    dir.create(log_dir, recursive = TRUE, showWarnings = FALSE)
  }
  log_path <- file.path(log_dir, sprintf("test_log_%s.csv", timestamp))

  if (!file.exists(log_path)) {
    header <- paste(
      c("timestamp", "suite", "test_name", "status", "duration_ms", "notes"),
      collapse = ","
    )
    writeLines(header, con = log_path, useBytes = TRUE)
  }

  TestLogReporter <- R6::R6Class(
    "TestLogReporter",
    inherit = testthat::Reporter,
    public = list(
      log_path = NULL,
      current_context = NULL,
      current_test = NULL,
      current_start = NULL,
      current_status = NULL,
      current_notes = NULL,
      initialize = function(log_path) {
        super$initialize()
        self$log_path <- log_path
      },
      start_test = function(context, test) {
        self$current_context <- context
        self$current_test <- test
        self$current_start <- Sys.time()
        self$current_status <- "pass"
        self$current_notes <- character()
      },
      add_result = function(context, test, result) {
        if (inherits(result, "expectation_failure") || inherits(result, "expectation_error")) {
          self$current_status <- "fail"
          self$current_notes <- c(self$current_notes, result$message)
        } else if (inherits(result, "expectation_skip")) {
          if (!identical(self$current_status, "fail")) {
            self$current_status <- "skip"
          }
          self$current_notes <- c(self$current_notes, result$message)
        } else if (inherits(result, "expectation_warning")) {
          if (identical(self$current_status, "pass")) {
            self$current_status <- "warn"
          }
          self$current_notes <- c(self$current_notes, result$message)
        }
      },
      add_error = function(context, test, error) {
        self$current_status <- "error"
        self$current_notes <- c(self$current_notes, conditionMessage(error))
      },
      add_skip = function(context, test, skip) {
        if (!identical(self$current_status, "fail")) {
          self$current_status <- "skip"
        }
        self$current_notes <- c(self$current_notes, conditionMessage(skip))
      },
      end_test = function(context, test) {
        duration_ms <- as.numeric(difftime(Sys.time(), self$current_start, units = "secs")) * 1000
        note <- paste(unique(self$current_notes), collapse = " | ")
        entry <- paste(
          format(Sys.time(), "%Y-%m-%dT%H:%M:%S"),
          context,
          test,
          self$current_status,
          sprintf("%.0f", duration_ms),
          gsub("[\r\n]", " ", note),
          sep = ","
        )
        write(entry, file = self$log_path, append = TRUE, ncolumns = 1, sep = "\n")
      }
    )
  )

  # Compose reporter with summary output so local runs still show results
  existing <- testthat::get_reporter()
  summary_reporter <- if (is.null(existing) || !inherits(existing, "Reporter")) {
    testthat::SummaryReporter$new()
  } else {
    existing
  }

  composite <- testthat::MultiReporter$new(list(
    TestLogReporter$new(log_path),
    summary_reporter
  ))

  options(testthat.default_reporter = composite)

  test_log_env$path <- log_path
  test_log_env$timestamp <- timestamp
  assign(".test_log_env", test_log_env, envir = parent.frame())
}
