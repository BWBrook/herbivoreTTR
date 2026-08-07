.food_energy_conversion_api <- function() {
  list(
    derive = getFromNamespace(
      "derive_ingested_available_energy_schedule",
      "herbivoreTTR"
    ),
    new_parameters = getFromNamespace(
      "new_food_energy_parameters",
      "herbivoreTTR"
    ),
    new_intake_schedule = getFromNamespace(
      "new_dry_matter_intake_schedule",
      "herbivoreTTR"
    ),
    new_energy_schedule = getFromNamespace(
      "new_ingested_available_energy_schedule",
      "herbivoreTTR"
    ),
    new_gut_state = getFromNamespace(
      "new_gut_energy_state",
      "herbivoreTTR"
    ),
    new_body_state = getFromNamespace(
      "new_body_energy_state",
      "herbivoreTTR"
    ),
    new_gut_parameters = getFromNamespace(
      "new_gut_energy_parameters",
      "herbivoreTTR"
    ),
    new_body_parameters = getFromNamespace(
      "new_body_energy_parameters",
      "herbivoreTTR"
    ),
    new_activity_schedule = getFromNamespace(
      "new_routine_activity_expenditure_schedule",
      "herbivoreTTR"
    ),
    run = getFromNamespace(
      "run_gut_body_energy_day",
      "herbivoreTTR"
    )
  )
}

.food_energy_conversion_inputs <- function(
  density = 10000,
  intake_rates = rep(0.01, 24L)
) {
  api <- .food_energy_conversion_api()

  list(
    api = api,
    parameters = api$new_parameters(density),
    schedule = api$new_intake_schedule(0:23, intake_rates)
  )
}

.run_food_energy_downstream <- function(
  api,
  energy_schedule,
  initial_gut_energy_kj = 400,
  maintenance_kj_h = 100
) {
  api$run(
    api$new_gut_state(initial_gut_energy_kj),
    api$new_body_state(5000),
    api$new_gut_parameters(0.25),
    api$new_body_parameters(maintenance_kj_h),
    energy_schedule,
    api$new_activity_schedule(0:23, rep(0, 24L))
  )
}

test_that("converter has the exact signature and existing energy schema", {
  fixture <- .food_energy_conversion_inputs(
    density = 8,
    intake_rates = as.numeric(0:23) / 8
  )
  api <- fixture$api

  expect_identical(
    names(formals(api$derive)),
    c("parameters", "schedule")
  )

  derived <- api$derive(fixture$parameters, fixture$schedule)
  manual <- api$new_energy_schedule(
    0:23,
    as.numeric(0:23)
  )

  expect_identical(derived, manual)
  expect_identical(class(derived), "data.frame")
  expect_identical(dim(derived), c(24L, 2L))
  expect_identical(
    names(derived),
    c(
      "hour_of_day",
      "prescribed_ingested_available_energy_kj_h"
    )
  )
  expect_identical(
    names(attributes(derived)),
    c("names", "class", "row.names")
  )
  expect_identical(derived$hour_of_day, 0:23)
  expect_type(
    derived$prescribed_ingested_available_energy_kj_h,
    "double"
  )
})

test_that("converter accepts equivalent numeric storage and harmless metadata", {
  api <- .food_energy_conversion_api()
  parameters <- structure(
    list(metabolizable_energy_density_kj_kg_dm = 10L),
    source = "test"
  )
  parameters$metabolizable_energy_density_kj_kg_dm <- structure(
    parameters$metabolizable_energy_density_kj_kg_dm,
    class = "energy_density",
    units = "kj_kg_dm"
  )
  schedule <- data.frame(
    hour_of_day = as.double(0:23),
    prescribed_dry_matter_intake_kg_dm_h = rep(2L, 24L),
    row.names = paste0("h", 0:23)
  )
  class(schedule) <- c("annotated_intake_schedule", "data.frame")
  attr(schedule, "source") <- "test"
  schedule <- schedule[c(
    "prescribed_dry_matter_intake_kg_dm_h",
    "hour_of_day"
  )]

  result <- api$derive(parameters, schedule)

  expect_identical(result$hour_of_day, 0:23)
  expect_identical(
    result$prescribed_ingested_available_energy_kj_h,
    rep(20, 24L)
  )
  expect_identical(class(result), "data.frame")
  expect_identical(row.names(result), as.character(seq_len(24L)))

  schedule$prescribed_dry_matter_intake_kg_dm_h <- factor(
    rep("2", 24L)
  )
  error <- expect_error(
    api$derive(parameters, schedule),
    "`prescribed_dry_matter_intake_kg_dm_h`.*numeric"
  )
  expect_null(conditionCall(error))
})

test_that("converter rejects missing, extra, and malformed parameters", {
  fixture <- .food_energy_conversion_inputs()
  api <- fixture$api
  density_name <- "metabolizable_energy_density_kj_kg_dm"
  malformed_records <- list(
    NULL,
    10000,
    list(),
    list(10000),
    list(wrong_name = 10000),
    structure(
      list(10000, 1),
      names = c(density_name, "extra")
    )
  )
  malformed_fields <- list(
    structure(list(0), names = density_name),
    structure(list(-1), names = density_name),
    structure(list(Inf), names = density_name),
    structure(list(NA_real_), names = density_name),
    structure(list("10000"), names = density_name),
    structure(list(TRUE), names = density_name),
    structure(list(10000 + 0i), names = density_name),
    structure(list(factor("10000")), names = density_name),
    structure(list(matrix(10000)), names = density_name)
  )

  expect_error(api$derive())
  expect_error(api$derive(parameters = fixture$parameters))
  expect_error(api$derive(schedule = fixture$schedule))
  expect_error(
    api$derive(fixture$parameters, fixture$schedule, extra = 1)
  )

  for (parameters in malformed_records) {
    expect_error(
      api$derive(parameters, fixture$schedule),
      "`parameters`"
    )
  }
  for (parameters in malformed_fields) {
    expect_error(
      api$derive(parameters, fixture$schedule),
      "`parameters\\$metabolizable_energy_density_kj_kg_dm`"
    )
  }

  error <- expect_error(
    api$derive(malformed_fields[[1L]], fixture$schedule),
    "`parameters\\$metabolizable_energy_density_kj_kg_dm`"
  )
  expect_null(conditionCall(error))
})

test_that("converter rejects malformed dry-matter schedules", {
  fixture <- .food_energy_conversion_inputs()
  api <- fixture$api
  valid <- fixture$schedule
  unordered_hours <- valid
  unordered_hours$hour_of_day <- c(1:23, 0L)
  fractional_hours <- valid
  fractional_hours$hour_of_day <- c(as.double(0:22), 23.5)
  character_hours <- valid
  character_hours$hour_of_day <- as.character(0:23)
  logical_hours <- valid
  logical_hours$hour_of_day <- rep(TRUE, 24L)
  complex_hours <- valid
  complex_hours$hour_of_day <- as.complex(0:23)
  factor_hours <- valid
  factor_hours$hour_of_day <- factor(0:23)
  negative_rates <- valid
  negative_rates$prescribed_dry_matter_intake_kg_dm_h[[1L]] <- -0.01
  nonfinite_rates <- valid
  nonfinite_rates$prescribed_dry_matter_intake_kg_dm_h[[1L]] <- Inf
  character_rates <- valid
  character_rates$prescribed_dry_matter_intake_kg_dm_h <- rep("0.01", 24L)
  logical_rates <- valid
  logical_rates$prescribed_dry_matter_intake_kg_dm_h <- rep(TRUE, 24L)
  complex_rates <- valid
  complex_rates$prescribed_dry_matter_intake_kg_dm_h <- rep(0.01 + 0i, 24L)
  factor_rates <- valid
  factor_rates$prescribed_dry_matter_intake_kg_dm_h <- factor(
    rep("0.01", 24L)
  )
  matrix_rates <- valid
  matrix_rates$prescribed_dry_matter_intake_kg_dm_h <- matrix(
    rep(0.01, 24L),
    ncol = 1L
  )
  malformed_containers <- list(
    NULL,
    as.list(valid),
    as.matrix(valid),
    valid[-24L, , drop = FALSE],
    valid["hour_of_day"],
    transform(valid, extra = 1)
  )
  malformed_hours <- list(
    unordered_hours,
    fractional_hours,
    character_hours,
    logical_hours,
    complex_hours,
    factor_hours
  )
  malformed_rates <- list(
    negative_rates,
    nonfinite_rates,
    character_rates,
    logical_rates,
    complex_rates,
    factor_rates,
    matrix_rates
  )

  for (schedule in malformed_containers) {
    expect_error(
      api$derive(fixture$parameters, schedule),
      "`schedule`"
    )
  }
  for (schedule in malformed_hours) {
    expect_error(
      api$derive(fixture$parameters, schedule),
      "`hour_of_day`"
    )
  }
  for (schedule in malformed_rates) {
    expect_error(
      api$derive(fixture$parameters, schedule),
      "`prescribed_dry_matter_intake_kg_dm_h`"
    )
  }
})

test_that("converter rejects non-finite products including overflow", {
  fixture <- .food_energy_conversion_inputs(
    density = .Machine$double.xmax,
    intake_rates = c(2, rep(0, 23L))
  )

  expect_error(
    fixture$api$derive(fixture$parameters, fixture$schedule),
    "finite"
  )
})

test_that("zero and constant fixtures give exact schedules and totals", {
  zero <- .food_energy_conversion_inputs(intake_rates = rep(0, 24L))
  zero_derived <- zero$api$derive(zero$parameters, zero$schedule)

  expect_identical(
    zero_derived,
    zero$api$new_energy_schedule(0:23, rep(0, 24L))
  )

  constant <- .food_energy_conversion_inputs()
  constant_derived <- constant$api$derive(
    constant$parameters,
    constant$schedule
  )

  expect_identical(
    constant_derived,
    constant$api$new_energy_schedule(0:23, rep(100, 24L))
  )
  expect_equal(
    sum(constant$schedule$prescribed_dry_matter_intake_kg_dm_h),
    0.24,
    tolerance = 1e-15
  )
  expect_identical(
    sum(
      constant_derived$
        prescribed_ingested_available_energy_kj_h
    ),
    2400
  )
})

test_that("constant bridge matches the manual Goal 003 equilibrium result", {
  fixture <- .food_energy_conversion_inputs()
  api <- fixture$api
  derived <- api$derive(fixture$parameters, fixture$schedule)
  manual <- api$new_energy_schedule(0:23, rep(100, 24L))
  derived_result <- .run_food_energy_downstream(api, derived)
  manual_result <- .run_food_energy_downstream(api, manual)

  expect_identical(derived, manual)
  expect_identical(derived_result, manual_result)
  expect_identical(
    derived_result$hourly$gut_available_energy_start_kj,
    rep(400, 24L)
  )
  expect_identical(
    derived_result$hourly$gut_available_energy_end_kj,
    rep(400, 24L)
  )
  expect_identical(
    derived_result$hourly$body_energy_reserve_end_kj,
    rep(5000, 24L)
  )
})

test_that("pulse bridge matches the manual delayed Goal 003 result", {
  fixture <- .food_energy_conversion_inputs(
    intake_rates = c(0.04, rep(0, 23L))
  )
  api <- fixture$api
  derived <- api$derive(fixture$parameters, fixture$schedule)
  manual <- api$new_energy_schedule(0:23, c(400, rep(0, 23L)))
  derived_result <- .run_food_energy_downstream(
    api,
    derived,
    initial_gut_energy_kj = 0,
    maintenance_kj_h = 0
  )
  manual_result <- .run_food_energy_downstream(
    api,
    manual,
    initial_gut_energy_kj = 0,
    maintenance_kj_h = 0
  )

  expect_identical(derived, manual)
  expect_identical(derived_result, manual_result)
  expect_identical(
    derived_result$hourly$assimilated_energy_kj_h[1:4],
    c(0, 100, 75, 56.25)
  )
})

test_that("factorized food inputs give identical schedules and dynamics", {
  first <- .food_energy_conversion_inputs(
    density = 10000,
    intake_rates = rep(0.01, 24L)
  )
  second <- .food_energy_conversion_inputs(
    density = 5000,
    intake_rates = rep(0.02, 24L)
  )
  first_derived <- first$api$derive(first$parameters, first$schedule)
  second_derived <- second$api$derive(
    second$parameters,
    second$schedule
  )

  expect_false(identical(first$parameters, second$parameters))
  expect_false(identical(first$schedule, second$schedule))
  expect_identical(first_derived, second_derived)
  expect_identical(
    .run_food_energy_downstream(first$api, first_derived),
    .run_food_energy_downstream(second$api, second_derived)
  )
})

test_that("converter does not mutate either supplied input", {
  fixture <- .food_energy_conversion_inputs(
    intake_rates = 0.001 * as.numeric(0:23)
  )
  before <- unserialize(serialize(
    list(fixture$parameters, fixture$schedule),
    connection = NULL
  ))

  fixture$api$derive(fixture$parameters, fixture$schedule)

  expect_identical(
    list(fixture$parameters, fixture$schedule),
    before
  )
})
