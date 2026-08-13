test_that("residual threshold defines the accessible forage boundary", {
  result <- derive_accessible_forage_biomass(
    c(0, 250, 500, 750, 1000, 1500),
    500
  )

  expect_identical(names(result), c(
    "forage_biomass_kg_dm_ha",
    "residual_unavailable_forage_threshold_kg_dm_ha",
    "accessible_forage_biomass_kg_dm_ha"
  ))
  expect_equal(
    result$accessible_forage_biomass_kg_dm_ha,
    c(0, 0, 0, 250, 500, 1000)
  )
  expect_true(all(
    result$accessible_forage_biomass_kg_dm_ha >= 0 &
      result$accessible_forage_biomass_kg_dm_ha <=
        result$forage_biomass_kg_dm_ha
  ))
})

test_that("availability boundary has transparent limiting cases", {
  standing <- c(0, 250, 1000)

  expect_equal(
    derive_accessible_forage_biomass(standing, 0)$
      accessible_forage_biomass_kg_dm_ha,
    standing
  )
  expect_equal(
    derive_accessible_forage_biomass(standing, 2000)$
      accessible_forage_biomass_kg_dm_ha,
    rep(0, length(standing))
  )
})

test_that("availability boundary rejects invalid quantities", {
  expect_error(
    derive_accessible_forage_biomass(numeric(), 500),
    "non-empty"
  )
  expect_error(
    derive_accessible_forage_biomass(c(500, -1), 500),
    "non-negative"
  )
  expect_error(
    derive_accessible_forage_biomass(500, c(100, 200)),
    "one finite"
  )
  expect_error(
    derive_accessible_forage_biomass(500, -1),
    "non-negative"
  )
})
