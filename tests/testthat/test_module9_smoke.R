## Internals available via helper-ttr.R (source_all_R)

test_that("single-minute eat: plant decreases by d kg, gut increases by d*1000 g", {
  plants <- data.frame(
    plant_id = 1L,
    xcor = 0, ycor = 0,
    ms = 2.0, mr = 1.0, bdef = 0.0, height = 1.0,
    cs = 1.0, cr = 0.5, ns = 0.1, nr = 0.05,
    bleaf = 1.9, bstem = 0.1
  )
  herb <- init_herbivore(mass = 5e5)
  herb$xcor <- 0; herb$ycor <- 0
  herb$selected_plant_id <- 1L
  herb$behaviour <- "EATING"
  # Make intake limited by handling rate (1 g/min)
  herb$gut_capacity <- 1e9
  herb$handling_time <- 1    # min/g -> 1 g/min
  herb$bite_size <- 1000     # g, not limiting
  before_ms <- plants$ms
  before_gut <- herb$gut_content
  res <- herbivore_eat(herb, plants)
  delta_kg <- before_ms - res$plants$ms
  delta_gut <- res$herbivore$gut_content - before_gut
  expect_gt(delta_kg, 0)
  expect_equal(delta_gut, delta_kg * 1000, tolerance = 1e-9)
})

test_that("daily runs: 1 day and 7 days remain finite and non-negative", {
  sim <- init_simulation(temp_mode = "flat", veg_types = c(0,1,2), herbivore_mass = 5e5)
  herb <- sim$herbivore
  plants <- sim$plants
  cond <- sim$conditions

  # Run 1 day at spin-up+1 so herbivory is active
  spinup_days <- CONSTANTS$SPIN_UP_LENGTH * nrow(cond)
  day0 <- spinup_days + 1L
  res1 <- run_daily_herbivore_simulation(herb, plants, cond, day_of_simulation = day0, minute_limit = 60)
  expect_true(is.finite(res1$herbivore$energy_balance))
  expect_true(is.finite(res1$herbivore$water_balance))
  expect_true(all(res1$plants$ms >= 0))
  expect_true(all(is.finite(res1$plants$ms)))

  # Run 7 consecutive days, feeding forward state
  herb2 <- res1$herbivore; plants2 <- res1$plants
  for (k in 1:6) {
    resk <- run_daily_herbivore_simulation(herb2, plants2, cond, day_of_simulation = day0 + k, minute_limit = 60)
    herb2 <- resk$herbivore; plants2 <- resk$plants
  }
  expect_true(is.finite(herb2$energy_balance))
  expect_true(is.finite(herb2$water_balance))
  expect_true(all(plants2$ms >= 0))
  # check pools reasonable (no explosions)
  pools <- c(plants2$ms, plants2$mr, plants2$cs, plants2$cr, plants2$ns, plants2$nr)
  expect_true(all(is.finite(pools)))
  expect_true(all(pools < 1e6))
})
