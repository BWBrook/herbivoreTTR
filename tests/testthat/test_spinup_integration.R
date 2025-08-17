local({
  base <- testthat::test_path("..", "..")
  # need to update, some of these files no longer exist because helpers have been split into individual scripts
  # suggest sourcing all .R functions in R/
  sys.source(file.path(base, "R", "constants.R"), envir = topenv())
  sys.source(file.path(base, "R", "utils.R"), envir = topenv())
  sys.source(file.path(base, "R", "init_herbivore.R"), envir = topenv())
  sys.source(file.path(base, "R", "ttr_forcing.R"), envir = topenv())
  sys.source(file.path(base, "R", "ttr_resistance.R"), envir = topenv())
  sys.source(file.path(base, "R", "ttr_transport.R"), envir = topenv())
  sys.source(file.path(base, "R", "ttr_uptake_growth.R"), envir = topenv())
  sys.source(file.path(base, "R", "ttr_daily.R"), envir = topenv())
  sys.source(file.path(base, "R", "run_daily_herbivore_simulation.R"), envir = topenv())
  sys.source(file.path(base, "R", "calc_foraging_traits.R"), envir = topenv())
  sys.source(file.path(base, "R", "reset_daily_variables.R"), envir = topenv())
  sys.source(file.path(base, "R", "update_gut_content.R"), envir = topenv())
  sys.source(file.path(base, "R", "hourly_digestion_step.R"), envir = topenv())
  sys.source(file.path(base, "R", "herbivore_eat.R"), envir = topenv())
  sys.source(file.path(base, "R", "herbivore_step.R"), envir = topenv())
  sys.source(file.path(base, "R", "get_plants_within_range.R"), envir = topenv())
})

make_one_plant <- function(ms = 2.0, x = 0, y = 0) {
  data.frame(
    plant_id = 1L,
    xcor = x, ycor = y,
    ms = ms, mr = 1.0, md = 0.0,
    cs = 1.0, cr = 0.5, cd = 0.0,
    ns = 0.1, nr = 0.05, nd = 0.0,
    bleaf = 1.8, bstem = 0.1, bdef = 0.1, brepr = 0.0, broot = 1.0,
    height = 1.0, veg_type = 0
  )
}

test_that("spin-up: plant-only (no herbivory intake or movement)", {
  # One day in spin-up period
  cond <- data.frame(day = 1:365, temp_mean = 20, sw = 0.5, N = 0.5)
  plants <- make_one_plant(ms = 2.0, x = 0, y = 0)
  herb <- init_herbivore(mass = 5e5)
  herb$xcor <- 0; herb$ycor <- 0
  day_of_sim <- 1L
  res <- run_daily_herbivore_simulation(herb, plants, cond, day_of_simulation = day_of_sim, minute_limit = 30)
  expect_equal(res$herbivore$intake_total_day, 0)
  expect_equal(res$herbivore$distance_moved, 0)
})

test_that("post-spin-up: herbivory active with intake and plant reduction", {
  # Conditions with SW = 0 to avoid growth; place herbivore at plant
  cond <- data.frame(day = 1:365, temp_mean = 20, sw = 0.0, N = 0.5)
  plants <- make_one_plant(ms = 2.0, x = 0, y = 0)
  herb <- init_herbivore(mass = 5e5)
  herb$xcor <- 0; herb$ycor <- 0
  # Simulate day right after spin-up ends
  spinup_days <- CONSTANTS$SPIN_UP_LENGTH * nrow(cond)
  day_of_sim <- spinup_days + 1L
  before_ms <- plants$ms
  res <- run_daily_herbivore_simulation(herb, plants, cond, day_of_simulation = day_of_sim, minute_limit = 10)
  expect_gt(res$herbivore$intake_total_day, 0)
  expect_lt(res$plants$ms[1], before_ms)
})

