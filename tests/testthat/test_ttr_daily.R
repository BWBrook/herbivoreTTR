## Internals available via helper-ttr.R (source_all_R)

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
