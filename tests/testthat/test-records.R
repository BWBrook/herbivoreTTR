test_that("plain records preserve units and reject invalid values", {
  expect_identical(
    new_body_energy_state(40000),
    list(body_energy_reserve_kj = 40000)
  )
  expect_identical(
    new_gut_energy_parameters(0.25),
    list(gut_release_fraction_h = 0.25)
  )
  expect_identical(
    new_food_energy_parameters(10000),
    list(metabolizable_energy_density_kj_kg_dm = 10000)
  )

  expect_error(new_body_energy_state(-1), "non-negative")
  expect_error(
    new_body_energy_state(structure(40000, class = "classed_energy")),
    "numeric"
  )
  expect_error(new_body_energy_parameters(Inf), "finite")
  expect_error(new_gut_energy_parameters(0), "\\(0, 1\\]")
  expect_error(new_food_energy_parameters(NA_real_), "strictly positive")
})

test_that("daily schedules use one explicit 24-hour clock", {
  hour <- 0:23
  intake <- new_dry_matter_intake_schedule(hour, rep(0.02, 24L))
  activity <- new_routine_activity_expenditure_schedule(
    hour,
    rep(50, 24L)
  )
  forage <- new_forage_acquisition_ceiling_schedule(
    hour,
    rep(0.025, 24L)
  )

  expect_identical(intake$hour_of_day, 0:23)
  expect_type(intake$prescribed_dry_matter_intake_kg_dm_h, "double")
  expect_equal(nrow(activity), 24L)
  expect_equal(nrow(forage), 24L)

  expect_error(
    new_dry_matter_intake_schedule(1:24, rep(0.02, 24L)),
    "0:23"
  )
  expect_error(
    new_routine_activity_expenditure_schedule(hour, rep(-1, 24L)),
    "non-negative"
  )
  expect_error(
    new_forage_acquisition_ceiling_schedule(hour, factor(rep("0.02", 24L))),
    "numeric"
  )
})

test_that("food conversion and appetite records expose the current boundary", {
  hour <- 0:23
  dry_matter <- new_dry_matter_intake_schedule(
    hour,
    c(rep(0.02, 16L), rep(0, 8L))
  )
  energy <- derive_ingested_available_energy_schedule(
    new_food_energy_parameters(10000),
    dry_matter
  )
  expect_equal(
    energy$prescribed_ingested_available_energy_kj_h,
    dry_matter$prescribed_dry_matter_intake_kg_dm_h * 10000
  )

  feeding_open <- hour < 16
  reference <- new_appetite_reference_schedule(
    hour,
    feeding_open,
    as.double(feeding_open) * 0.02,
    rep(40000, 24L),
    rep(400, 24L)
  )
  expect_equal(nrow(reference), 24L)
  expect_error(
    new_appetite_reference_schedule(
      hour,
      feeding_open,
      rep(0.02, 24L),
      rep(40000, 24L),
      rep(400, 24L)
    ),
    "zero when feeding opportunity is closed"
  )
})

test_that("body mass is a read-only energy interpretation", {
  parameters <- new_body_mass_parameters(38, 20000)
  result <- derive_body_mass_from_energy_reserve(
    parameters,
    c(0, 10000, 40000)
  )
  expect_equal(result$reserve_tissue_mass_kg, c(0, 0.5, 2))
  expect_equal(result$total_body_mass_kg, c(38, 38.5, 40))
  expect_error(
    derive_body_mass_from_energy_reserve(parameters, c(40000, -1)),
    "non-negative"
  )
})
