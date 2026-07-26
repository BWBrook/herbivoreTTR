.body_energy_public_function <- function(name) {
  getExportedValue("herbivoreTTR", name)
}

test_that("state constructor returns the exact plain record", {
  new_state <- .body_energy_public_function("new_body_energy_state")

  expect_identical(
    names(formals(new_state)),
    "body_energy_reserve_kj"
  )

  state <- new_state(body_energy_reserve_kj = 5000)

  expect_type(state, "list")
  expect_false(is.object(state))
  expect_identical(names(state), "body_energy_reserve_kj")
  expect_identical(state$body_energy_reserve_kj, 5000)
})

test_that("state constructor rejects every malformed reserve value", {
  new_state <- .body_energy_public_function("new_body_energy_state")

  expect_error(new_state())
  expect_error(new_state(5000, extra = 1))
  expect_error(new_state(numeric()))
  expect_error(new_state(c(5000, 5001)))

  invalid_values <- list(
    Inf,
    -Inf,
    NaN,
    NA_real_,
    -1,
    "5000",
    TRUE,
    factor("5000"),
    list(5000)
  )

  for (value in invalid_values) {
    expect_error(
      new_state(value),
      info = paste("value:", paste(value, collapse = ", "))
    )
  }
})

test_that("scalar energy constructors reject matrices and attributed numerics", {
  new_state <- .body_energy_public_function("new_body_energy_state")
  new_parameters <- .body_energy_public_function(
    "new_body_energy_parameters"
  )

  invalid_reserves <- list(
    matrix(5000, nrow = 1L, ncol = 1L),
    structure(5000, class = "energy_kj"),
    structure(5000, note = "attributed")
  )
  invalid_maintenance_rates <- list(
    matrix(100, nrow = 1L, ncol = 1L),
    structure(100, class = "energy_rate"),
    structure(100, note = "attributed")
  )

  for (value in invalid_reserves) {
    expect_error(new_state(value))
  }
  for (value in invalid_maintenance_rates) {
    expect_error(new_parameters(value))
  }
})

test_that("parameter constructor returns the exact plain record", {
  new_parameters <- .body_energy_public_function(
    "new_body_energy_parameters"
  )

  expect_identical(
    names(formals(new_parameters)),
    "maintenance_expenditure_kj_h"
  )

  parameters <- new_parameters(maintenance_expenditure_kj_h = 100)

  expect_type(parameters, "list")
  expect_false(is.object(parameters))
  expect_identical(names(parameters), "maintenance_expenditure_kj_h")
  expect_identical(parameters$maintenance_expenditure_kj_h, 100)
})

test_that("parameter constructor rejects missing, extra, and non-scalar values", {
  new_parameters <- .body_energy_public_function(
    "new_body_energy_parameters"
  )

  expect_error(new_parameters())
  expect_error(new_parameters(100, extra = 1))
  expect_error(new_parameters(numeric()))
  expect_error(new_parameters(c(100, 101)))
})

test_that("parameter constructor rejects non-finite, negative, and non-numeric values", {
  new_parameters <- .body_energy_public_function(
    "new_body_energy_parameters"
  )

  invalid_values <- list(
    Inf,
    -Inf,
    NaN,
    NA_real_,
    -1,
    "100",
    TRUE,
    factor("100"),
    list(100)
  )

  for (value in invalid_values) {
    expect_error(
      new_parameters(value),
      info = paste("value:", paste(value, collapse = ", "))
    )
  }
})

test_that("energy constructors normalize accepted integers to doubles", {
  new_state <- .body_energy_public_function("new_body_energy_state")
  new_parameters <- .body_energy_public_function(
    "new_body_energy_parameters"
  )
  new_schedule <- .body_energy_public_function(
    "new_assimilated_energy_schedule"
  )

  state <- new_state(5000L)
  parameters <- new_parameters(100L)
  schedule <- new_schedule(0:23, rep(100L, 24L))

  expect_identical(state$body_energy_reserve_kj, 5000)
  expect_identical(parameters$maintenance_expenditure_kj_h, 100)
  expect_identical(schedule$hour_of_day, 0:23)
  expect_identical(
    schedule$prescribed_assimilated_energy_kj_h,
    rep(100, 24L)
  )
})

test_that("schedule constructor returns the exact ordered base data frame", {
  new_schedule <- .body_energy_public_function(
    "new_assimilated_energy_schedule"
  )
  hours <- 0:23
  rates <- 100 + as.numeric(hours)

  expect_identical(
    names(formals(new_schedule)),
    c("hour_of_day", "prescribed_assimilated_energy_kj_h")
  )

  schedule <- new_schedule(
    hour_of_day = hours,
    prescribed_assimilated_energy_kj_h = rates
  )

  expect_identical(class(schedule), "data.frame")
  expect_identical(dim(schedule), c(24L, 2L))
  expect_identical(
    names(schedule),
    c("hour_of_day", "prescribed_assimilated_energy_kj_h")
  )
  expect_identical(schedule$hour_of_day, hours)
  expect_identical(schedule$prescribed_assimilated_energy_kj_h, rates)
})

test_that("schedule constructor rejects missing, extra, and wrong-length inputs", {
  new_schedule <- .body_energy_public_function(
    "new_assimilated_energy_schedule"
  )

  expect_error(new_schedule())
  expect_error(new_schedule(hour_of_day = 0:23))
  expect_error(
    new_schedule(prescribed_assimilated_energy_kj_h = rep(100, 24))
  )
  expect_error(new_schedule(0:23, rep(100, 24), extra = 1))
  expect_error(new_schedule(0:22, rep(100, 23)))
  expect_error(new_schedule(0:23, rep(100, 23)))
  expect_error(new_schedule(0:24, rep(100, 25)))
})

test_that("schedule constructor requires integer hours zero through twenty-three in order", {
  new_schedule <- .body_energy_public_function(
    "new_assimilated_energy_schedule"
  )
  rates <- rep(100, 24)
  invalid_hours <- list(
    as.numeric(0:23),
    c(0:22, 22L),
    c(1:23, 0L),
    c(0:22, 24L),
    replace(0:23, 24, NA_integer_),
    as.character(0:23),
    rep(TRUE, 24)
  )

  for (hours in invalid_hours) {
    expect_error(
      new_schedule(hours, rates),
      info = paste("hours:", paste(hours, collapse = ", "))
    )
  }
})

test_that("schedule constructor requires finite non-negative numeric rates", {
  new_schedule <- .body_energy_public_function(
    "new_assimilated_energy_schedule"
  )
  hours <- 0:23
  invalid_rates <- list(
    replace(rep(100, 24), 1, -1),
    replace(rep(100, 24), 1, Inf),
    replace(rep(100, 24), 1, -Inf),
    replace(rep(100, 24), 1, NaN),
    replace(rep(100, 24), 1, NA_real_),
    rep("100", 24),
    rep(TRUE, 24),
    as.list(rep(100, 24))
  )

  for (rates in invalid_rates) {
    expect_error(
      new_schedule(hours, rates),
      info = paste("rates:", paste(rates, collapse = ", "))
    )
  }
})

test_that("schedule constructor rejects matrices and attributed numeric vectors", {
  new_schedule <- .body_energy_public_function(
    "new_assimilated_energy_schedule"
  )
  invalid_rates <- list(
    matrix(100, nrow = 1L, ncol = 24L),
    structure(rep(100, 24L), class = "energy_rate"),
    structure(rep(100, 24L), note = "attributed")
  )

  for (rates in invalid_rates) {
    expect_error(new_schedule(0:23, rates))
  }
})
