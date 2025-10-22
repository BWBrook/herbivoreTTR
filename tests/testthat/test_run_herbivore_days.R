test_that("run_herbivore_days returns multi-day summary with intake", {
  res <- run_herbivore_days(days = 3L, minute_limit = 60)
  summary <- res$daily_summary

  expect_s3_class(summary, "data.frame")
  expect_equal(nrow(summary), 3L)
  expect_setequal(
    colnames(summary),
    c(
      "day_of_simulation",
      "today_temp",
      "total_distance_moved",
      "total_biomass_eaten",
      "energy_balance",
      "water_balance"
    )
  )
  expect_true(any(summary$total_biomass_eaten > 0))
  expect_equal(
    res$start_day,
    CONSTANTS$SPIN_UP_LENGTH * nrow(init_conditions()) + 1L
  )
})
