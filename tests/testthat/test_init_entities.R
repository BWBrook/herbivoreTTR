test_that("init_plants builds full grid with expected columns", {
  set.seed(99)
  plants <- init_plants(veg_types = c(0, 1))
  expect_equal(nrow(plants), CONSTANTS$PLANTS_PER_PLOT)
  expect_equal(anyDuplicated(plants$plant_id), 0)
  expect_setequal(
    names(plants),
    c(
      "x", "y", "plant_id", "veg_type", "ms", "mr", "cs", "cr", "ns", "nr",
      "cd", "nd", "bleaf", "bstem", "broot", "brepr", "bdef", "md", "height",
      "qroot", "qshoot", "gs", "gr", "gd", "uc", "un", "rsC", "rrC", "rdC",
      "rsN", "rrN", "rdN", "tauC", "tauN", "tauCd", "tauNd"
    )
  )
  expect_true(all(plants$veg_type %in% c(0, 1)))
  expect_true(all(plants$ms >= CONSTANTS$PLANT_INITIAL_MASS_MIN))
  expect_true(all(plants$ms <= CONSTANTS$PLANT_INITIAL_MASS_MAX))
})

test_that("init_herbivore seeds digestion pools and derived traits", {
  set.seed(321)
  herb <- init_herbivore(mass = 5e5, MRT = 24)
  expect_equal(length(herb$digestion$bleaf), 24)
  expect_equal(herb$gut_capacity, calc_gut_capacity(herb$mass))
  expect_equal(herb$bite_size, calc_bite_size(herb$mass))
  expect_equal(herb$handling_time, calc_handling_time(herb$mass))
  expect_equal(herb$fv_max, calc_foraging_velocity(herb$mass))
  expect_true(herb$daily_water_requirement > 0)
  expect_identical(herb$behaviour, "MOVING")
})

test_that("calc_foraging_traits is monotonic in mass", {
  herb_small <- list(mass = 1e5)
  herb_large <- list(mass = 5e5)
  herb_small <- calc_foraging_traits(herb_small)
  herb_large <- calc_foraging_traits(herb_large)
  expect_lt(herb_small$gut_capacity, herb_large$gut_capacity)
  expect_lt(herb_small$bite_size, herb_large$bite_size)
  expect_gt(herb_small$handling_time, herb_large$handling_time) # negative exponent
  expect_lt(herb_small$fv_max, herb_large$fv_max)
})

test_that("init_simulation returns coherent components", {
  set.seed(777)
  sim <- init_simulation(temp_mode = "flat", veg_types = c(0, 2), herbivore_mass = 2e5)
  expect_named(sim, c("conditions", "plants", "herbivore"))
  expect_equal(ncol(sim$conditions), 4)
  expect_true(all(sim$plants$veg_type %in% c(0, 2)))
  expect_equal(sim$herbivore$mass, 2e5)
})
