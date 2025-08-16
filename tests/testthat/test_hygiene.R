test_that("constants self-reference is resolved after load", {
  sys.source(file.path(testthat::test_path("..", ".."), "R", "constants.R"), envir = topenv())
  expect_true(is.numeric(CONSTANTS$PLANTS_PER_PLOT))
  expect_equal(CONSTANTS$PLANTS_PER_PLOT, CONSTANTS$PLANTS_IN_X * CONSTANTS$PLANTS_IN_Y)
})

test_that("calc_plant_tastiness uses bdef and returns finite values", {
  # Minimal plants_in_range input with bdef column
  plants_in_range <- data.frame(
    plant_id = 1:3,
    ns = c(1, 2, 3),
    cs = c(1, 2, 3),
    distance = c(0.1, 1, 10),
    bdef = c(0, 0.1, 1)
  )
  res <- calc_plant_tastiness(plants_in_range, herbivore = NULL, desired_dp_dc_ratio = 1)
  expect_length(res, nrow(plants_in_range))
  expect_true(all(is.finite(res)))
  expect_true(all(res >= 0))
})

test_that("packages and options helpers are defined without side-effects", {
  sys.source(file.path(testthat::test_path("..", ".."), "R", "packages.R"), envir = topenv())
  sys.source(file.path(testthat::test_path("..", ".."), "R", "options.R"), envir = topenv())
  expect_true(exists("ensure_packages_installed", mode = "function"))
  expect_true(exists("lib", mode = "function"))
  expect_true(exists("init_project_options", mode = "function"))
})

test_that("init_plants includes defence pools cd/nd placeholders", {
  sys.source(file.path(testthat::test_path("..", ".."), "R", "constants.R"), envir = topenv())
  sys.source(file.path(testthat::test_path("..", ".."), "R", "utils.R"), envir = topenv())
  sys.source(file.path(testthat::test_path("..", ".."), "R", "init_plants.R"), envir = topenv())
  p <- init_plants(veg_types = c(0,1,2))
  expect_true(all(c("cd","nd","md","bdef") %in% names(p)))
  expect_true(all(is.finite(p$cd)))
  expect_true(all(is.finite(p$nd)))
  expect_true(all(p$cd >= 0))
  expect_true(all(p$nd >= 0))
})
