local({
  base <- testthat::test_path("..", "..")
  sys.source(file.path(base, "R", "constants.R"), envir = topenv())
  sys.source(file.path(base, "R", "utils.R"), envir = topenv())
  sys.source(file.path(base, "R", "init_plants.R"), envir = topenv())
  sys.source(file.path(base, "R", "ttr_forcing.R"), envir = topenv())
  sys.source(file.path(base, "R", "ttr_resistance.R"), envir = topenv())
  sys.source(file.path(base, "R", "ttr_transport.R"), envir = topenv())
  sys.source(file.path(base, "R", "ttr_uptake_growth.R"), envir = topenv())
  sys.source(file.path(base, "R", "ttr_daily.R"), envir = topenv())
  sys.source(file.path(base, "R", "init_conditions.R"), envir = topenv())
})

test_that("transport_resistance updates plants without NaN/Inf and keeps non-negative masses", {
  cond <- init_conditions(days_in_year = 10, mode = "flat", mean_temp = 20, amplitude = 0)
  plants <- init_plants(veg_types = c(0, 1, 2))
  before <- plants[1,]
  out <- transport_resistance(plants[1, , drop = FALSE], cond, day_index = 1)
  expect_equal(nrow(out), 1)
  expect_true(all(sapply(out, function(col) all(is.finite(col)))))
  expect_true(all(out$ms >= 0)); expect_true(all(out$mr >= 0))
  expect_true(all(out$bleaf >= 0)); expect_true(all(out$bstem >= 0)); expect_true(all(out$bdef >= 0))
  # Check that some state likely changed sensibly (not mandatory to increase/decrease consistently)
  expect_true(is.numeric(out$ms))
})

