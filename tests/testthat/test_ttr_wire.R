## Internals available via helper-ttr.R (source_all_R)

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
