test_that("init_project_options configures RNG and options", {
  withr::local_options(list(scipen = getOption("scipen")))
  old_seed <- .Random.seed
  on.exit({
    if (!is.null(old_seed)) assign(".Random.seed", old_seed, envir = .GlobalEnv)
  }, add = TRUE)

  if (requireNamespace("progressr", quietly = TRUE)) {
    progressr_ns <- asNamespace("progressr")
    was_locked <- bindingIsLocked("handlers", progressr_ns)
    if (was_locked) {
      unlockBinding("handlers", progressr_ns)
    }
    original_handlers <- get("handlers", envir = progressr_ns)
    assign("handlers", function(...) invisible(NULL), envir = progressr_ns)
    withr::defer({
      if (bindingIsLocked("handlers", progressr_ns)) {
        unlockBinding("handlers", progressr_ns)
      }
      assign("handlers", original_handlers, envir = progressr_ns)
      if (was_locked) {
        lockBinding("handlers", progressr_ns)
      }
    }, envir = parent.frame())
    if (was_locked) {
      lockBinding("handlers", progressr_ns)
    }
  }

  init_project_options(seed = 101)
  expect_equal(getOption("scipen"), 999)
  expect_equal(getOption("readr.show_col_types"), FALSE)

  vals <- round(runif(3), 6)
  expect_equal(vals, c(0.985708, 0.916748, 0.272728))
})

test_that("CONSTANTS list has no missing entries and derived values coherent", {
  expect_false(any(vapply(CONSTANTS, is.null, logical(1))))
  expect_equal(
    CONSTANTS$PLANTS_PER_PLOT,
    CONSTANTS$PLANTS_IN_X * CONSTANTS$PLANTS_IN_Y
  )
  expect_gt(CONSTANTS$GUT_CAPACITY_A, 0)
  expect_gt(CONSTANTS$FORAGE_VEL_A, 0)
  expect_gt(CONSTANTS$PLANT_INITIAL_MASS_MAX, CONSTANTS$PLANT_INITIAL_MASS_MIN)
})

test_that("package bootstrap helpers short-circuit for empty vectors", {
  expect_invisible(ensure_packages_installed(NULL))
  expect_invisible(ensure_packages_installed(character()))
  expect_invisible(lib(NULL))
})
