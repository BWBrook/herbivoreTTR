test_that("summarise_hourly_herbivore_record aggregates minute data", {
  set.seed(123)
  sim <- init_simulation()
  start_day <- CONSTANTS$SPIN_UP_LENGTH * nrow(sim$conditions) + 1L
  res <- run_daily_herbivore_simulation(
    herbivore = sim$herbivore,
    plants = sim$plants,
    conditions = sim$conditions,
    day_of_simulation = start_day,
    minute_limit = 120L
  )

  hourly <- summarise_hourly_herbivore_record(
    daily_record = res$daily_record,
    day_of_simulation = res$daily_summary$day_of_simulation
  )

  expect_equal(nrow(hourly), 2L)
  expect_equal(hourly$day_of_simulation, rep(start_day, 2L))
  expect_true(all(hourly$hour == c(1L, 2L)))
  expect_true(all(hourly$distance_moved_hour >= 0))
  expect_true(all(hourly$intake_total_hour >= 0))
  expect_equal(
    tail(hourly$intake_total_cumulative, 1),
    sum(hourly$intake_total_hour)
  )
})
