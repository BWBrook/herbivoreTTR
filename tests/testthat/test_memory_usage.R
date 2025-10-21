test_that("seven-day simulation stays within memory budget", {
  skip_on_cran()
  skip_if_not_installed("pryr")
  mem_mb <- pryr::mem_change({
    sim <- init_simulation(temp_mode = "flat")
    herb <- sim$herbivore
    plants <- sim$plants
    cond <- sim$conditions
    day0 <- CONSTANTS$SPIN_UP_LENGTH * nrow(cond) + 1L
    for (k in 0:6) {
      day <- day0 + k
      res <- run_daily_herbivore_simulation(
        herbivore = herb,
        plants = plants,
        conditions = cond,
        day_of_simulation = day,
        minute_limit = 30
      )
      herb <- res$herbivore
      plants <- res$plants
    }
  }) / (1024^2)
  expect_lt(mem_mb, 250)
})
