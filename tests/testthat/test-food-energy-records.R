.food_energy_public_function <- function(name) {
  getFromNamespace(name, "herbivoreTTR")
}

test_that("food parameter constructor returns the exact plain record", {
  new_parameters <- .food_energy_public_function(
    "new_food_energy_parameters"
  )

  expect_identical(
    names(formals(new_parameters)),
    "metabolizable_energy_density_kj_kg_dm"
  )

  parameters <- new_parameters(
    metabolizable_energy_density_kj_kg_dm = 10000L
  )

  expect_type(parameters, "list")
  expect_false(is.object(parameters))
  expect_identical(
    names(parameters),
    "metabolizable_energy_density_kj_kg_dm"
  )
  expect_identical(
    attributes(parameters),
    list(names = "metabolizable_energy_density_kj_kg_dm")
  )
  expect_identical(
    parameters$metabolizable_energy_density_kj_kg_dm,
    10000
  )
})

test_that("food energy density is finite, bare, scalar, and positive", {
  new_parameters <- .food_energy_public_function(
    "new_food_energy_parameters"
  )

  expect_identical(
    new_parameters(.Machine$double.xmin)$
      metabolizable_energy_density_kj_kg_dm,
    .Machine$double.xmin
  )
  expect_error(new_parameters())
  expect_error(new_parameters(10000, extra = 1))
  expect_error(new_parameters(numeric()))
  expect_error(new_parameters(c(10000, 11000)))

  invalid_values <- list(
    0,
    -1,
    Inf,
    -Inf,
    NaN,
    NA_real_,
    "10000",
    TRUE,
    factor("10000"),
    list(10000),
    matrix(10000, nrow = 1L, ncol = 1L),
    structure(10000, class = "energy_density"),
    structure(10000, note = "attributed"),
    structure(10000, names = "density")
  )

  for (value in invalid_values) {
    expect_error(new_parameters(value))
  }
})

test_that("dry-matter schedule has the exact base data-frame contract", {
  new_schedule <- .food_energy_public_function(
    "new_dry_matter_intake_schedule"
  )
  hours <- 0:23
  rates <- 0.001 * as.numeric(0:23)

  expect_identical(
    names(formals(new_schedule)),
    c(
      "hour_of_day",
      "prescribed_dry_matter_intake_kg_dm_h"
    )
  )

  schedule <- new_schedule(
    hour_of_day = hours,
    prescribed_dry_matter_intake_kg_dm_h = rates
  )

  expect_identical(class(schedule), "data.frame")
  expect_false(is.object(schedule$hour_of_day))
  expect_false(is.object(
    schedule$prescribed_dry_matter_intake_kg_dm_h
  ))
  expect_identical(dim(schedule), c(24L, 2L))
  expect_identical(
    names(schedule),
    c(
      "hour_of_day",
      "prescribed_dry_matter_intake_kg_dm_h"
    )
  )
  expect_identical(
    names(attributes(schedule)),
    c("names", "class", "row.names")
  )
  expect_identical(schedule$hour_of_day, hours)
  expect_identical(
    schedule$prescribed_dry_matter_intake_kg_dm_h,
    rates
  )
})

test_that("dry-matter schedule normalizes accepted integer rates to doubles", {
  new_schedule <- .food_energy_public_function(
    "new_dry_matter_intake_schedule"
  )

  schedule <- new_schedule(0:23, rep(1L, 24L))

  expect_identical(schedule$hour_of_day, 0:23)
  expect_identical(
    schedule$prescribed_dry_matter_intake_kg_dm_h,
    rep(1, 24L)
  )
})

test_that("dry-matter schedule rejects missing, extra, and wrong lengths", {
  new_schedule <- .food_energy_public_function(
    "new_dry_matter_intake_schedule"
  )

  expect_error(new_schedule())
  expect_error(new_schedule(hour_of_day = 0:23))
  expect_error(
    new_schedule(
      prescribed_dry_matter_intake_kg_dm_h = rep(0.01, 24L)
    )
  )
  expect_error(new_schedule(0:23, rep(0.01, 24L), extra = 1))
  expect_error(new_schedule(0:22, rep(0.01, 23L)))
  expect_error(new_schedule(0:23, rep(0.01, 23L)))
  expect_error(new_schedule(0:24, rep(0.01, 25L)))
})

test_that("dry-matter schedule requires bare integer hours zero through 23", {
  new_schedule <- .food_energy_public_function(
    "new_dry_matter_intake_schedule"
  )
  rates <- rep(0.01, 24L)
  invalid_hours <- list(
    as.numeric(0:23),
    c(0:22, 22L),
    c(1:23, 0L),
    c(0:22, 24L),
    replace(0:23, 24L, NA_integer_),
    as.character(0:23),
    rep(TRUE, 24L),
    matrix(0:23, nrow = 1L),
    structure(0:23, class = "hour_index"),
    structure(0:23, note = "attributed"),
    structure(0:23, names = as.character(0:23))
  )

  for (hours in invalid_hours) {
    expect_error(new_schedule(hours, rates))
  }
})

test_that("dry-matter schedule requires bare finite non-negative rates", {
  new_schedule <- .food_energy_public_function(
    "new_dry_matter_intake_schedule"
  )
  invalid_rates <- list(
    replace(rep(0.01, 24L), 1L, -0.01),
    replace(rep(0.01, 24L), 1L, Inf),
    replace(rep(0.01, 24L), 1L, -Inf),
    replace(rep(0.01, 24L), 1L, NaN),
    replace(rep(0.01, 24L), 1L, NA_real_),
    rep("0.01", 24L),
    rep(TRUE, 24L),
    as.list(rep(0.01, 24L)),
    matrix(0.01, nrow = 1L, ncol = 24L),
    structure(rep(0.01, 24L), class = "intake_rate"),
    structure(rep(0.01, 24L), note = "attributed"),
    structure(rep(0.01, 24L), names = as.character(0:23))
  )

  for (rates in invalid_rates) {
    expect_error(new_schedule(0:23, rates))
  }
})

test_that("food record constructors do not mutate accepted inputs", {
  new_parameters <- .food_energy_public_function(
    "new_food_energy_parameters"
  )
  new_schedule <- .food_energy_public_function(
    "new_dry_matter_intake_schedule"
  )
  density <- 10000L
  hours <- 0:23
  rates <- rep(1L, 24L)
  inputs_before <- unserialize(serialize(
    list(density, hours, rates),
    connection = NULL
  ))

  new_parameters(density)
  new_schedule(hours, rates)

  expect_identical(list(density, hours, rates), inputs_before)
})
