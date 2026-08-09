test_that("body-energy reserve has one exact derived mass interpretation", {
  parameters <- new_body_mass_parameters(
    structural_body_mass_kg = 38,
    reserve_tissue_energy_density_kj_kg = 20000
  )

  expect_identical(
    parameters,
    list(
      structural_body_mass_kg = 38,
      reserve_tissue_energy_density_kj_kg = 20000
    )
  )
  expect_identical(
    names(formals(derive_body_mass_from_energy_reserve)),
    c("parameters", "body_energy_reserve_kj")
  )

  result <- derive_body_mass_from_energy_reserve(
    parameters,
    c(0, 10000, 40000)
  )

  expect_identical(
    result,
    data.frame(
      body_energy_reserve_kj = c(0, 10000, 40000),
      reserve_tissue_mass_kg = c(0, 0.5, 2),
      total_body_mass_kg = c(38, 38.5, 40)
    )
  )
})

test_that("body-mass conversion canonicalizes equivalent numeric inputs", {
  parameters <- structure(
    list(
      reserve_tissue_energy_density_kj_kg = structure(
        20000L,
        class = "energy_density"
      ),
      structural_body_mass_kg = 38L
    ),
    source = "synthetic reference"
  )
  reserves <- structure(
    c(40000L, 30000L),
    units = "kJ",
    names = c("reference", "depleted")
  )

  result <- derive_body_mass_from_energy_reserve(parameters, reserves)

  expect_identical(
    result,
    data.frame(
      body_energy_reserve_kj = c(40000, 30000),
      reserve_tissue_mass_kg = c(2, 1.5),
      total_body_mass_kg = c(40, 39.5)
    )
  )
})

test_that("body-mass boundaries reject scientifically invalid inputs", {
  expect_error(
    new_body_mass_parameters(0, 20000),
    "structural_body_mass_kg.*strictly positive"
  )
  expect_error(
    new_body_mass_parameters(38, Inf),
    "reserve_tissue_energy_density_kj_kg.*strictly positive"
  )

  parameters <- new_body_mass_parameters(38, 20000)
  expect_error(
    derive_body_mass_from_energy_reserve(
      list(structural_body_mass_kg = 38),
      40000
    ),
    "`parameters`"
  )
  expect_error(
    derive_body_mass_from_energy_reserve(parameters, c(40000, -1)),
    "body_energy_reserve_kj.*non-negative"
  )
  expect_error(
    derive_body_mass_from_energy_reserve(parameters, matrix(40000)),
    "body_energy_reserve_kj.*numeric vector"
  )

  .with_value_changing_double_method({
    expect_error(
      derive_body_mass_from_energy_reserve(
        parameters,
        .value_changing_double(40000)
      ),
      "body_energy_reserve_kj.*numeric vector"
    )
  })
})
