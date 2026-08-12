test_that("forage records preserve the physical accounting boundary", {
  state <- new_forage_biomass_state(1000)
  schedule <- new_forage_growth_loss_schedule(
    0:23,
    rep(2, 24L),
    rep(1, 24L)
  )

  expect_identical(state, list(forage_biomass_kg_dm_ha = 1000))
  expect_identical(names(schedule), c(
    "hour_of_day",
    "prescribed_forage_growth_kg_dm_ha_h",
    "prescribed_forage_background_loss_kg_dm_ha_h"
  ))
  expect_equal(nrow(schedule), 24L)
  expect_error(new_forage_biomass_state(-1), "non-negative")
  expect_error(
    new_forage_growth_loss_schedule(1:24, rep(2, 24L), rep(1, 24L)),
    "0:23"
  )
  expect_error(
    new_forage_growth_loss_schedule(0:23, rep(2, 24L), rep(-1, 24L)),
    "non-negative"
  )
})
test_that("hourly forage transition conserves biomass without clamping", {
  input <- new_forage_growth_loss_schedule(
    0:23,
    rep(2, 24L),
    rep(1, 24L)
  )[1L, , drop = FALSE]
  result <- step_forage_biomass(new_forage_biomass_state(1000), input)

  expect_equal(result$state$forage_biomass_kg_dm_ha, 1001)
  expect_equal(result$fluxes$net_forage_biomass_rate_kg_dm_ha_h, 1)
  expect_equal(result$fluxes$prescribed_forage_growth_kg_dm_ha, 2)
  expect_equal(result$fluxes$prescribed_forage_background_loss_kg_dm_ha, 1)
  expect_equal(result$fluxes$forage_biomass_balance_residual_kg_dm_ha, 0)

  impossible_loss <- new_forage_growth_loss_schedule(
    0:23,
    rep(0, 24L),
    rep(2, 24L)
  )[1L, , drop = FALSE]
  expect_error(
    step_forage_biomass(new_forage_biomass_state(1), impossible_loss),
    "negative"
  )
})

test_that("daily forage runner separates turnover from net change", {
  run_fixture <- function(growth, loss) {
    run_forage_biomass_day(
      new_forage_biomass_state(1000),
      new_forage_growth_loss_schedule(
        0:23,
        rep(growth, 24L),
        rep(loss, 24L)
      )
    )
  }

  balanced <- run_fixture(2, 2)
  gain <- run_fixture(2, 1)
  loss <- run_fixture(1, 2)

  expect_equal(balanced$daily$total_prescribed_forage_growth_kg_dm_ha, 48)
  expect_equal(
    balanced$daily$total_prescribed_forage_background_loss_kg_dm_ha,
    48
  )
  expect_equal(balanced$daily$forage_biomass_final_kg_dm_ha, 1000)
  expect_equal(
    balanced$hourly$forage_biomass_start_kg_dm_ha[-1L],
    head(balanced$hourly$forage_biomass_end_kg_dm_ha, -1L)
  )
  expect_equal(
    c(
      gain$daily$forage_biomass_final_kg_dm_ha,
      loss$daily$forage_biomass_final_kg_dm_ha
    ),
    c(1024, 976)
  )
  expect_equal(
    c(
      gain$daily$observed_forage_biomass_change_kg_dm_ha,
      loss$daily$observed_forage_biomass_change_kg_dm_ha
    ),
    c(24, -24)
  )
  expect_true(
    max(abs(balanced$hourly$forage_biomass_balance_residual_kg_dm_ha)) < 1e-10
  )
  expect_equal(balanced$daily$forage_biomass_balance_residual_kg_dm_ha, 0)
})
