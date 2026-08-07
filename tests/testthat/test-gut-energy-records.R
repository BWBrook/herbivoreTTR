.gut_energy_namespace_function <- function(name) {
  getFromNamespace(name, "herbivoreTTR")
}

test_that("gut state constructor returns the exact plain record", {
  new_state <- .gut_energy_namespace_function("new_gut_energy_state")

  expect_identical(names(formals(new_state)), "gut_available_energy_kj")

  state <- new_state(gut_available_energy_kj = 400L)

  expect_type(state, "list")
  expect_false(is.object(state))
  expect_identical(names(state), "gut_available_energy_kj")
  expect_identical(
    attributes(state),
    list(names = "gut_available_energy_kj")
  )
  expect_identical(state$gut_available_energy_kj, 400)
})

test_that("gut state constructor accepts zero and rejects malformed stocks", {
  new_state <- .gut_energy_namespace_function("new_gut_energy_state")

  expect_identical(new_state(0)$gut_available_energy_kj, 0)
  expect_error(new_state())
  expect_error(new_state(400, extra = 1))
  expect_error(new_state(numeric()))
  expect_error(new_state(c(400, 401)))

  invalid_values <- list(
    Inf,
    -Inf,
    NaN,
    NA_real_,
    -1,
    "400",
    TRUE,
    400 + 0i,
    factor("400"),
    list(400),
    matrix(400, nrow = 1L, ncol = 1L)
  )

  for (value in invalid_values) {
    expect_error(new_state(value), "`gut_available_energy_kj`")
  }
})

test_that("gut scalar constructors accept harmless numeric metadata", {
  new_state <- .gut_energy_namespace_function("new_gut_energy_state")
  new_parameters <- .gut_energy_namespace_function(
    "new_gut_energy_parameters"
  )
  stock <- structure(
    400L,
    class = "energy_kj",
    source = "test"
  )
  release_fraction <- structure(
    0.25,
    names = "release",
    source = "test"
  )

  expect_identical(new_state(stock)$gut_available_energy_kj, 400)
  expect_identical(
    new_parameters(release_fraction)$gut_release_fraction_h,
    0.25
  )
})

test_that("gut parameter constructor returns the exact plain record", {
  new_parameters <- .gut_energy_namespace_function(
    "new_gut_energy_parameters"
  )

  expect_identical(
    names(formals(new_parameters)),
    "gut_release_fraction_h"
  )

  parameters <- new_parameters(gut_release_fraction_h = 1L)

  expect_type(parameters, "list")
  expect_false(is.object(parameters))
  expect_identical(names(parameters), "gut_release_fraction_h")
  expect_identical(
    attributes(parameters),
    list(names = "gut_release_fraction_h")
  )
  expect_identical(parameters$gut_release_fraction_h, 1)
})

test_that("gut release fraction is finite, scalar, numeric, and in (0, 1]", {
  new_parameters <- .gut_energy_namespace_function(
    "new_gut_energy_parameters"
  )

  expect_identical(
    new_parameters(0.25)$gut_release_fraction_h,
    0.25
  )
  expect_error(new_parameters())
  expect_error(new_parameters(0.25, extra = 1))
  expect_error(new_parameters(numeric()))
  expect_error(new_parameters(c(0.25, 0.5)))

  invalid_values <- list(
    0,
    -0.25,
    1.01,
    Inf,
    -Inf,
    NaN,
    NA_real_,
    "0.25",
    TRUE,
    0.25 + 0i,
    factor("0.25"),
    list(0.25),
    matrix(0.25, nrow = 1L, ncol = 1L)
  )

  for (value in invalid_values) {
    expect_error(new_parameters(value), "`gut_release_fraction_h`")
  }
})

test_that("ingestion schedule has the exact base data-frame contract", {
  new_schedule <- .gut_energy_namespace_function(
    "new_ingested_available_energy_schedule"
  )
  hours <- 0:23
  rates <- 100 + as.numeric(hours)

  expect_identical(
    names(formals(new_schedule)),
    c("hour_of_day", "prescribed_ingested_available_energy_kj_h")
  )

  schedule <- new_schedule(
    hour_of_day = hours,
    prescribed_ingested_available_energy_kj_h = rates
  )

  expect_identical(class(schedule), "data.frame")
  expect_false(is.object(schedule$hour_of_day))
  expect_identical(dim(schedule), c(24L, 2L))
  expect_identical(
    names(schedule),
    c(
      "hour_of_day",
      "prescribed_ingested_available_energy_kj_h"
    )
  )
  expect_identical(
    names(attributes(schedule)),
    c("names", "class", "row.names")
  )
  expect_identical(schedule$hour_of_day, hours)
  expect_identical(
    schedule$prescribed_ingested_available_energy_kj_h,
    rates
  )
})

test_that("ingestion schedule normalizes integer energy rates to doubles", {
  new_schedule <- .gut_energy_namespace_function(
    "new_ingested_available_energy_schedule"
  )

  schedule <- new_schedule(0:23, rep(100L, 24L))

  expect_identical(schedule$hour_of_day, 0:23)
  expect_identical(
    schedule$prescribed_ingested_available_energy_kj_h,
    rep(100, 24L)
  )
})

test_that("ingestion schedule accepts semantic numeric storage and metadata", {
  new_schedule <- .gut_energy_namespace_function(
    "new_ingested_available_energy_schedule"
  )
  hours <- structure(
    as.double(0:23),
    names = paste0("h", 0:23),
    source = "test"
  )
  rates <- structure(
    rep(100L, 24L),
    class = "energy_rate",
    source = "test"
  )

  schedule <- new_schedule(hours, rates)

  expect_identical(schedule$hour_of_day, 0:23)
  expect_identical(
    schedule$prescribed_ingested_available_energy_kj_h,
    rep(100, 24L)
  )
  expect_null(attributes(schedule$hour_of_day))
  expect_null(attributes(
    schedule$prescribed_ingested_available_energy_kj_h
  ))
})

test_that("ingestion schedule rejects missing, extra, and wrong-length inputs", {
  new_schedule <- .gut_energy_namespace_function(
    "new_ingested_available_energy_schedule"
  )

  expect_error(new_schedule())
  expect_error(new_schedule(hour_of_day = 0:23))
  expect_error(
    new_schedule(
      prescribed_ingested_available_energy_kj_h = rep(100, 24L)
    )
  )
  expect_error(new_schedule(0:23, rep(100, 24L), extra = 1))
  expect_error(new_schedule(0:22, rep(100, 23L)))
  expect_error(new_schedule(0:23, rep(100, 23L)))
  expect_error(new_schedule(0:24, rep(100, 25L)))
})

test_that("ingestion schedule requires ordered whole numeric hours zero to 23", {
  new_schedule <- .gut_energy_namespace_function(
    "new_ingested_available_energy_schedule"
  )
  rates <- rep(100, 24L)
  invalid_hours <- list(
    c(0:22, 22L),
    c(1:23, 0L),
    c(0:22, 24L),
    replace(0:23, 24L, NA_integer_),
    c(as.double(0:22), 23.5),
    as.character(0:23),
    rep(TRUE, 24L),
    as.complex(0:23),
    factor(0:23),
    matrix(0:23, nrow = 1L),
    array(0:23, dim = c(2L, 3L, 4L))
  )

  for (hours in invalid_hours) {
    expect_error(new_schedule(hours, rates), "`hour_of_day`")
  }

  error <- expect_error(
    new_schedule(c(as.double(0:22), 23.5), rates),
    "`hour_of_day`"
  )
  expect_null(conditionCall(error))
})

test_that("ingestion schedule requires finite non-negative numeric rates", {
  new_schedule <- .gut_energy_namespace_function(
    "new_ingested_available_energy_schedule"
  )
  invalid_rates <- list(
    replace(rep(100, 24L), 1L, -1),
    replace(rep(100, 24L), 1L, Inf),
    replace(rep(100, 24L), 1L, -Inf),
    replace(rep(100, 24L), 1L, NaN),
    replace(rep(100, 24L), 1L, NA_real_),
    rep("100", 24L),
    rep(TRUE, 24L),
    rep(100 + 0i, 24L),
    factor(rep("100", 24L)),
    as.list(rep(100, 24L)),
    matrix(100, nrow = 1L, ncol = 24L)
  )

  for (rates in invalid_rates) {
    expect_error(
      new_schedule(0:23, rates),
      "`prescribed_ingested_available_energy_kj_h`"
    )
  }

  error <- expect_error(
    new_schedule(0:23, factor(rep("100", 24L))),
    "`prescribed_ingested_available_energy_kj_h`"
  )
  expect_null(conditionCall(error))
})

test_that("constructors do not mutate accepted inputs", {
  new_state <- .gut_energy_namespace_function("new_gut_energy_state")
  new_parameters <- .gut_energy_namespace_function(
    "new_gut_energy_parameters"
  )
  new_schedule <- .gut_energy_namespace_function(
    "new_ingested_available_energy_schedule"
  )
  gut_stock <- 400L
  release_fraction <- 1L
  hours <- 0:23
  rates <- rep(100L, 24L)
  inputs_before <- list(gut_stock, release_fraction, hours, rates)

  new_state(gut_stock)
  new_parameters(release_fraction)
  new_schedule(hours, rates)

  expect_identical(
    list(gut_stock, release_fraction, hours, rates),
    inputs_before
  )
})
