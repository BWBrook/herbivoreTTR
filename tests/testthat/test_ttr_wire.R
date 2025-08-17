local({
  base <- testthat::test_path("..", "..")
  # need to update, some of these files no longer exist because helpers have been split into individual scripts
  # suggest sourcing all .R functions in R/
  sys.source(file.path(base, "R", "constants.R"), envir = topenv())
  sys.source(file.path(base, "R", "utils.R"), envir = topenv())
  sys.source(file.path(base, "R", "init_plants.R"), envir = topenv())
  sys.source(file.path(base, "R", "init_herbivore.R"), envir = topenv())
  sys.source(file.path(base, "R", "init_conditions.R"), envir = topenv())
  sys.source(file.path(base, "R", "ttr_forcing.R"), envir = topenv())
  sys.source(file.path(base, "R", "ttr_resistance.R"), envir = topenv())
  sys.source(file.path(base, "R", "ttr_transport.R"), envir = topenv())
  sys.source(file.path(base, "R", "ttr_uptake_growth.R"), envir = topenv())
  sys.source(file.path(base, "R", "ttr_daily.R"), envir = topenv())
  sys.source(file.path(base, "R", "run_daily_herbivore_simulation.R"), envir = topenv())
})

test_that("run_daily_herbivore_simulation wires TTR and returns uc/gs columns", {
  cond <- init_conditions(days_in_year = 10, mode = "flat", mean_temp = 20, amplitude = 0)
  plants <- init_plants(veg_types = c(0,1,2))
  herb  <- init_herbivore(mass = 5e5)
  res <- run_daily_herbivore_simulation(herb, plants, cond, day_of_simulation = 1, minute_limit = 0)
  expect_true("uc" %in% names(res$plants))
  expect_true("gs" %in% names(res$plants))
  expect_true(all(is.finite(res$plants$ms)))
  expect_true(all(res$plants$ms >= 0))
})

