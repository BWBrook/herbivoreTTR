.appetite_reference_schedule <- function() {
  herbivoreTTR::new_appetite_reference_schedule(
    hour_of_day = 0:23,
    feeding_opportunity_open = c(
      rep(TRUE, 8L),
      rep(FALSE, 8L),
      rep(TRUE, 8L)
    ),
    reference_dry_matter_intake_kg_dm_h = c(
      rep(0.020, 8L),
      rep(0, 8L),
      rep(0.020, 8L)
    ),
    reference_body_energy_reserve_kj = rep(10000, 24L),
    reference_gut_available_energy_kj = rep(600, 24L)
  )
}

.appetite_parameters <- function(maximum_rate = 0.025) {
  herbivoreTTR::new_appetite_control_parameters(
    maximum_dry_matter_intake_kg_dm_h = maximum_rate,
    body_energy_feedback_fraction_h = 0.05,
    gut_energy_feedback_fraction_h = 0.10
  )
}

.calculate_appetite_target <- function(
  gut_energy_kj = 600,
  body_energy_kj = 10000,
  hour_index = 1L,
  maximum_rate = 0.025
) {
  herbivoreTTR::calculate_appetite_target(
    gut_state = herbivoreTTR::new_gut_energy_state(gut_energy_kj),
    body_state = herbivoreTTR::new_body_energy_state(body_energy_kj),
    food_parameters = herbivoreTTR::new_food_energy_parameters(10000),
    appetite_parameters = .appetite_parameters(maximum_rate),
    reference_row = .appetite_reference_schedule()[
      hour_index,
      ,
      drop = FALSE
    ]
  )
}

.forage_acquisition_ceiling_schedule <- function(rate = 0.025) {
  herbivoreTTR::new_forage_acquisition_ceiling_schedule(
    hour_of_day = 0:23,
    forage_acquisition_ceiling_kg_dm_h = rep(rate, 24L)
  )
}

test_that("appetite records are canonical and explicit", {
  parameters <- .appetite_parameters()
  schedule <- .appetite_reference_schedule()

  expect_identical(
    parameters,
    list(
      maximum_dry_matter_intake_kg_dm_h = 0.025,
      body_energy_feedback_fraction_h = 0.05,
      gut_energy_feedback_fraction_h = 0.10
    )
  )
  expect_identical(class(schedule), "data.frame")
  expect_identical(dim(schedule), c(24L, 5L))
  expect_identical(
    names(schedule),
    c(
      "hour_of_day",
      "feeding_opportunity_open",
      "reference_dry_matter_intake_kg_dm_h",
      "reference_body_energy_reserve_kj",
      "reference_gut_available_energy_kj"
    )
  )
  expect_identical(schedule$hour_of_day, 0:23)
  expect_type(schedule$feeding_opportunity_open, "logical")
  expect_true(all(vapply(schedule[3:5], is.double, logical(1))))
})

test_that("forage-acquisition ceiling is a separate canonical rate schedule", {
  schedule <- .forage_acquisition_ceiling_schedule()

  expect_identical(class(schedule), "data.frame")
  expect_identical(dim(schedule), c(24L, 2L))
  expect_identical(
    names(schedule),
    c("hour_of_day", "forage_acquisition_ceiling_kg_dm_h")
  )
  expect_identical(schedule$hour_of_day, 0:23)
  expect_identical(
    schedule$forage_acquisition_ceiling_kg_dm_h,
    rep(0.025, 24L)
  )

  semantic <- herbivoreTTR::new_forage_acquisition_ceiling_schedule(
    structure(as.double(0:23), provenance = "accepted metadata"),
    structure(rep(0.025, 24L), provenance = "accepted metadata")
  )
  expect_identical(semantic, schedule)
})

test_that("appetite records reject scientifically invalid values", {
  expect_error(
    herbivoreTTR::new_appetite_control_parameters(0, 0.05, 0.10),
    "strictly positive"
  )
  expect_error(
    herbivoreTTR::new_appetite_control_parameters(0.025, -0.05, 0.10),
    "non-negative"
  )
  expect_error(
    herbivoreTTR::new_appetite_control_parameters(0.025, 0.05, Inf),
    "finite"
  )
  expect_error(
    herbivoreTTR::new_appetite_reference_schedule(
      0:23,
      rep(1, 24L),
      rep(0.020, 24L),
      rep(10000, 24L),
      rep(600, 24L)
    ),
    "logical"
  )
  expect_error(
    herbivoreTTR::new_appetite_reference_schedule(
      0:23,
      c(rep(TRUE, 8L), rep(FALSE, 8L), rep(TRUE, 8L)),
      rep(0.020, 24L),
      rep(10000, 24L),
      rep(600, 24L)
    ),
    "closed"
  )
  expect_error(
    herbivoreTTR::new_appetite_reference_schedule(
      0:23,
      rep(TRUE, 24L),
      rep(0.020, 24L),
      rep(-1, 24L),
      rep(600, 24L)
    ),
    "body"
  )
  expect_error(
    herbivoreTTR::new_forage_acquisition_ceiling_schedule(
      0:23,
      c(-0.001, rep(0.025, 23L))
    ),
    "non-negative"
  )
  expect_error(
    herbivoreTTR::new_forage_acquisition_ceiling_schedule(
      1:24,
      rep(0.025, 24L)
    ),
    "0:23"
  )
})

test_that("the exact reference produces zero feedback and its appetite target", {
  result <- .calculate_appetite_target()

  expect_identical(
    names(result),
    c(
      "feeding_opportunity_open",
      "reference_dry_matter_intake_kg_dm_h",
      "maximum_dry_matter_intake_kg_dm_h",
      "reference_ingested_available_energy_kj_h",
      "body_energy_deviation_from_reference_kj",
      "body_energy_feedback_kj_h",
      "gut_energy_deviation_from_reference_kj",
      "gut_energy_feedback_kj_h",
      "unconstrained_ingested_available_energy_kj_h",
      "unconstrained_dry_matter_intake_kg_dm_h",
      "appetite_target_dry_matter_intake_kg_dm_h",
      "appetite_target_ingested_available_energy_kj_h",
      "lower_intake_bound_active",
      "upper_intake_bound_active"
    )
  )
  expect_identical(result$feeding_opportunity_open, TRUE)
  expect_identical(result$body_energy_deviation_from_reference_kj, 0)
  expect_identical(result$body_energy_feedback_kj_h, 0)
  expect_identical(result$gut_energy_deviation_from_reference_kj, 0)
  expect_identical(result$gut_energy_feedback_kj_h, 0)
  expect_identical(result$reference_ingested_available_energy_kj_h, 200)
  expect_identical(result$unconstrained_ingested_available_energy_kj_h, 200)
  expect_identical(result$appetite_target_dry_matter_intake_kg_dm_h, 0.020)
  expect_identical(result$appetite_target_ingested_available_energy_kj_h, 200)
  expect_false(result$lower_intake_bound_active)
  expect_false(result$upper_intake_bound_active)
})

test_that("body and gut feedback are directional and additive", {
  body_deficit <- .calculate_appetite_target(body_energy_kj = 9500)
  body_surplus <- .calculate_appetite_target(body_energy_kj = 10500)
  gut_surplus <- .calculate_appetite_target(gut_energy_kj = 800)
  gut_deficit <- .calculate_appetite_target(gut_energy_kj = 400)
  integrated <- .calculate_appetite_target(
    gut_energy_kj = 800,
    body_energy_kj = 9500
  )

  expect_identical(body_deficit$body_energy_feedback_kj_h, 25)
  expect_equal(body_deficit$appetite_target_ingested_available_energy_kj_h, 225)
  expect_identical(body_surplus$body_energy_feedback_kj_h, -25)
  expect_equal(body_surplus$appetite_target_ingested_available_energy_kj_h, 175)
  expect_identical(gut_surplus$gut_energy_feedback_kj_h, -20)
  expect_equal(gut_surplus$appetite_target_ingested_available_energy_kj_h, 180)
  expect_identical(gut_deficit$gut_energy_feedback_kj_h, 20)
  expect_equal(gut_deficit$appetite_target_ingested_available_energy_kj_h, 220)
  expect_identical(integrated$body_energy_feedback_kj_h, 25)
  expect_identical(integrated$gut_energy_feedback_kj_h, -20)
  expect_equal(integrated$appetite_target_ingested_available_energy_kj_h, 205)
})

test_that("feeding opportunity and physiological bounds constrain target", {
  closed <- .calculate_appetite_target(
    body_energy_kj = 5000,
    hour_index = 9L
  )
  upper <- .calculate_appetite_target(body_energy_kj = 8000)
  lower <- .calculate_appetite_target(body_energy_kj = 15000)

  expect_false(closed$feeding_opportunity_open)
  expect_gt(closed$unconstrained_ingested_available_energy_kj_h, 0)
  expect_identical(closed$appetite_target_dry_matter_intake_kg_dm_h, 0)
  expect_identical(closed$appetite_target_ingested_available_energy_kj_h, 0)

  expect_identical(upper$unconstrained_ingested_available_energy_kj_h, 300)
  expect_identical(upper$appetite_target_dry_matter_intake_kg_dm_h, 0.025)
  expect_identical(upper$appetite_target_ingested_available_energy_kj_h, 250)
  expect_true(upper$upper_intake_bound_active)
  expect_false(upper$lower_intake_bound_active)

  expect_identical(lower$unconstrained_ingested_available_energy_kj_h, -50)
  expect_identical(lower$appetite_target_dry_matter_intake_kg_dm_h, 0)
  expect_identical(lower$appetite_target_ingested_available_energy_kj_h, 0)
  expect_true(lower$lower_intake_bound_active)
  expect_false(lower$upper_intake_bound_active)
})

test_that("reference intake cannot exceed the declared maximum", {
  expect_error(
    .calculate_appetite_target(maximum_rate = 0.015),
    "must not exceed"
  )
})
