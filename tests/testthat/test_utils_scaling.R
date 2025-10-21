test_that("select_randomly returns deterministic sample with seed", {
  pick1 <- withr::with_seed(1, select_randomly(letters[1:5]))
  pick2 <- withr::with_seed(1, select_randomly(letters[1:5]))
  expect_identical(pick1, pick2)
  expect_true(pick1 %in% letters[1:5])
})

test_that("calc_toroidal_distance handles wrap-around correctly", {
  dist_direct <- calc_toroidal_distance(0, 0, 2, 2, plot_width = 10, plot_height = 10)
  dist_wrap <- calc_toroidal_distance(0, 0, 9, 9, plot_width = 10, plot_height = 10)
  expect_equal(dist_direct, sqrt(8), tolerance = 1e-6)
  expect_lt(dist_wrap, dist_direct)
})

test_that("sigmoid sf is bounded between zero and one", {
  x <- seq(-10, 10, length.out = 5)
  res <- sf(x, k = 0, b = 0.5)
  expect_true(all(res >= 0 & res <= 1))
  expect_gt(res[1], res[length(res)])
})

test_that("herbivore allometry helpers are monotonic", {
  masses <- c(1e4, 5e4, 1e5)
  gut <- calc_gut_capacity(masses)
  bite <- calc_bite_size(masses)
  fv <- calc_foraging_velocity(masses)
  water <- calc_water_requirement(masses)
  expect_true(all(diff(gut) > 0))
  expect_true(all(diff(bite) > 0))
  expect_true(all(diff(fv) > 0))
  expect_true(all(diff(water) > 0))

  handling <- calc_handling_time(masses)
  expect_true(all(diff(handling) < 0)) # negative exponent
})
