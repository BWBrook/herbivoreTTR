test_that("init_conditions flat mode is deterministic and bounded", {
  set.seed(123)
  res <- init_conditions(days_in_year = 12, mode = "flat", mean_temp = 18, amplitude = 5)
  expect_equal(ncol(res), 4)
  expect_equal(res$sw, rep(0.5, 12))
  expect_equal(res$N, rep(0.5, 12))
  expect_true(all(res$temp_mean <= 23))
  expect_equal(res$day, seq_len(12))
})

test_that("init_conditions stochastic mode stays within configured ranges", {
  set.seed(42)
  res <- init_conditions(days_in_year = 20, mode = "stochastic")
  expect_true(all(res$sw >= 0.3 & res$sw <= 0.6))
  expect_true(all(res$N >= 0.4 & res$N <= 0.6))
  # Repeat with same seed to confirm determinism
  set.seed(42)
  res2 <- init_conditions(days_in_year = 20, mode = "stochastic")
  expect_equal(res, res2)
})

test_that("init_conditions seasonal mode produces sinusoidal patterns", {
  res <- init_conditions(days_in_year = 365, mode = "seasonal", mean_temp = 20, amplitude = 10)
  expect_equal(length(res$sw), 365)
  expect_true(max(res$sw) <= 0.55)
  expect_true(min(res$sw) >= 0.35)
  expect_lt(range(res$temp_mean)[1], range(res$temp_mean)[2])
  expect_equal(mean(res$temp_mean), 20, tolerance = 1e-6)
})

test_that("init_conditions validates mode values", {
  expect_error(
    init_conditions(mode = "unknown"),
    class = "herbivoreTTR_init_conditions_mode"
  )
})
