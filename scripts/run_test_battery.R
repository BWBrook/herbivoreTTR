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
testthat::test_dir("tests/testthat")

if (Sys.getenv("RUN_COVERAGE") == "1") {
  message("[4/4] Computing package coverage")
  cov <- covr::package_coverage(type = "tests", quiet = TRUE)
  message(sprintf("Coverage: %.2f%%", covr::percent_coverage(cov)))
} else {
  message("[4/4] Skipping coverage (set RUN_COVERAGE=1 to enable)")
}

message("== Test battery completed ==")
