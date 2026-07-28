.goal006_day_hourly <- function(result, measurement_day) {
  rows <- result$hourly$measurement_day == measurement_day
  result$hourly[rows, , drop = FALSE]
}

.goal006_day_daily <- function(result, measurement_day) {
  rows <- result$daily$measurement_day == measurement_day
  result$daily[rows, , drop = FALSE]
}

.goal006_gut_boundaries_kj <- function(hourly) {
  c(
    hourly$gut_available_energy_start_kj[[1L]],
    hourly$gut_available_energy_end_kj
  )
}

.goal006_body_boundaries_kj <- function(hourly) {
  c(
    hourly$body_energy_reserve_start_kj[[1L]],
    hourly$body_energy_reserve_end_kj
  )
}

.goal006_daily_tolerances <- function(result, measurement_day) {
  hourly <- .goal006_day_hourly(result, measurement_day)
  daily <- .goal006_day_daily(result, measurement_day)
  measured_days <- lapply(
    1:2,
    function(day) .goal006_day_hourly(result, day)
  )
  measured_boundaries <- lapply(
    measured_days,
    .goal006_gut_boundaries_kj
  )
  cycle_tolerance_kj <- 100 * .Machine$double.eps * max(
    1,
    abs(measured_boundaries[[1L]]),
    abs(measured_boundaries[[2L]]),
    sum(abs(
      measured_days[[1L]]$prescribed_ingested_available_energy_kj
    )),
    sum(abs(measured_days[[1L]]$assimilated_energy_kj)),
    sum(abs(measured_days[[2L]]$assimilated_energy_kj))
  )
  gut_ledger_tolerance_kj <- 100 * .Machine$double.eps * max(
    1,
    abs(daily$gut_available_energy_initial_kj),
    abs(daily$gut_available_energy_final_kj),
    sum(abs(hourly$prescribed_ingested_available_energy_kj)),
    sum(abs(hourly$assimilated_energy_kj))
  )
  body_ledger_tolerance_kj <- 100 * .Machine$double.eps * max(
    1,
    abs(daily$body_energy_reserve_initial_kj),
    abs(daily$body_energy_reserve_final_kj),
    sum(abs(hourly$assimilated_energy_kj)),
    sum(abs(hourly$maintenance_expenditure_kj))
  )

  c(
    cycle_tolerance_kj = cycle_tolerance_kj,
    gut_ledger_tolerance_kj = gut_ledger_tolerance_kj,
    assimilation_total_tolerance_kj =
      cycle_tolerance_kj + gut_ledger_tolerance_kj,
    body_ledger_tolerance_kj = body_ledger_tolerance_kj,
    body_neutrality_tolerance_kj =
      cycle_tolerance_kj +
        gut_ledger_tolerance_kj +
        body_ledger_tolerance_kj
  )
}

.goal006_new_fixture <- function(
  scenario_id,
  reference_type,
  dry_matter_rates_kg_dm_h
) {
  dry_matter_schedule <-
    herbivoreTTR::new_dry_matter_intake_schedule(
      hour_of_day = 0:23,
      prescribed_dry_matter_intake_kg_dm_h =
        dry_matter_rates_kg_dm_h
    )
  energy_schedule <-
    herbivoreTTR::derive_ingested_available_energy_schedule(
      herbivoreTTR::new_food_energy_parameters(10000),
      dry_matter_schedule
    )
  result <- herbivoreTTR::run_gut_body_energy_reference_cycle(
    initial_gut_state = herbivoreTTR::new_gut_energy_state(0),
    measurement_body_state =
      herbivoreTTR::new_body_energy_state(10000),
    gut_parameters = herbivoreTTR::new_gut_energy_parameters(0.25),
    body_parameters = herbivoreTTR::new_body_energy_parameters(100),
    schedule = energy_schedule,
    gut_convergence_relative_tolerance =
      100 * .Machine$double.eps,
    max_burn_in_days = 100L
  )

  list(
    scenario_id = scenario_id,
    reference_type = reference_type,
    dry_matter_schedule = dry_matter_schedule,
    energy_schedule = energy_schedule,
    result = result
  )
}

.goal006_fixtures <- function() {
  list(
    mathematical_continuous = .goal006_new_fixture(
      scenario_id = "mathematical_continuous",
      reference_type = "mathematical",
      dry_matter_rates_kg_dm_h = rep(0.010, 24L)
    ),
    ecological_day_resting = .goal006_new_fixture(
      scenario_id = "ecological_day_resting",
      reference_type = "ecological",
      dry_matter_rates_kg_dm_h = c(
        rep(0.015, 8L),
        rep(0, 8L),
        rep(0.015, 8L)
      )
    )
  )
}

test_that(
  "energy-matched references retain daily balance and distinct phases",
  {
    fixtures <- .goal006_fixtures()
    expected_dry_matter_rates <- list(
      mathematical_continuous = rep(0.010, 24L),
      ecological_day_resting = c(
        rep(0.015, 8L),
        rep(0, 8L),
        rep(0.015, 8L)
      )
    )
    expected_energy_rates <- list(
      mathematical_continuous = rep(100, 24L),
      ecological_day_resting = c(
        rep(150, 8L),
        rep(0, 8L),
        rep(150, 8L)
      )
    )
    expected_reference_types <- c(
      mathematical_continuous = "mathematical",
      ecological_day_resting = "ecological"
    )
    expected_feeding_intervals <- c(
      mathematical_continuous = 24L,
      ecological_day_resting = 16L
    )
    expected_rest_intervals <- c(
      mathematical_continuous = 0L,
      ecological_day_resting = 8L
    )
    dry_matter_total_tolerance_kg_dm <-
      100 * .Machine$double.eps

    expect_identical(names(fixtures), names(expected_dry_matter_rates))

    for (scenario_id in names(fixtures)) {
      fixture <- fixtures[[scenario_id]]
      dry_matter_rates <-
        fixture$dry_matter_schedule$
          prescribed_dry_matter_intake_kg_dm_h
      energy_rates <-
        fixture$energy_schedule$
          prescribed_ingested_available_energy_kj_h
      convergence <- fixture$result$convergence
      comparison_rows <- seq.int(2L, nrow(convergence))
      final_cycle_tolerance_kj <- tail(
        convergence$realized_convergence_tolerance_kj,
        1L
      )

      expect_identical(fixture$scenario_id, scenario_id)
      expect_identical(
        fixture$reference_type,
        expected_reference_types[[scenario_id]]
      )
      expect_identical(
        fixture$dry_matter_schedule$hour_of_day,
        0:23
      )
      expect_identical(
        fixture$energy_schedule$hour_of_day,
        0:23
      )
      expect_identical(
        dry_matter_rates,
        expected_dry_matter_rates[[scenario_id]]
      )
      expect_identical(
        energy_rates,
        expected_energy_rates[[scenario_id]]
      )
      expect_identical(
        as.integer(sum(dry_matter_rates > 0)),
        expected_feeding_intervals[[scenario_id]]
      )
      expect_identical(
        as.integer(sum(dry_matter_rates == 0)),
        expected_rest_intervals[[scenario_id]]
      )
      expect_lte(
        abs(sum(dry_matter_rates) - 0.24),
        dry_matter_total_tolerance_kg_dm
      )
      expect_identical(sum(energy_rates), 2400)

      day_1_hourly <- .goal006_day_hourly(fixture$result, 1L)
      expect_identical(
        day_1_hourly$time_start_h,
        as.numeric(0:23)
      )
      expect_identical(
        day_1_hourly$time_end_h,
        as.numeric(1:24)
      )

      expect_identical(convergence$burn_in_day, seq_len(7L))
      expect_identical(
        convergence$converged,
        c(rep(FALSE, 6L), TRUE)
      )
      expect_true(all(is.finite(
        convergence$
          max_abs_previous_day_trajectory_difference_kj[
            comparison_rows
          ]
      )))
      expect_true(all(is.finite(
        convergence$realized_convergence_tolerance_kj[
          comparison_rows
        ]
      )))
      expect_true(all(
        convergence$realized_convergence_tolerance_kj[
          comparison_rows
        ] > 0
      ))
      expect_lte(
        abs(tail(convergence$cycle_boundary_change_kj, 1L)),
        final_cycle_tolerance_kj
      )
      expect_lte(
        tail(
          convergence$
            max_abs_previous_day_trajectory_difference_kj,
          1L
        ),
        final_cycle_tolerance_kj
      )

      day_2_hourly <- .goal006_day_hourly(fixture$result, 2L)
      expect_lte(
        max(abs(
          .goal006_gut_boundaries_kj(day_2_hourly) -
            .goal006_gut_boundaries_kj(day_1_hourly)
        )),
        final_cycle_tolerance_kj
      )
      expect_identical(
        fixture$result$hourly$gut_available_energy_start_kj[-1L],
        head(
          fixture$result$hourly$gut_available_energy_end_kj,
          -1L
        )
      )
      expect_identical(
        fixture$result$hourly$body_energy_reserve_start_kj[-1L],
        head(
          fixture$result$hourly$body_energy_reserve_end_kj,
          -1L
        )
      )

      for (measurement_day in 1:2) {
        hourly <- .goal006_day_hourly(
          fixture$result,
          measurement_day
        )
        daily <- .goal006_day_daily(
          fixture$result,
          measurement_day
        )
        body_boundaries_kj <-
          .goal006_body_boundaries_kj(hourly)
        tolerances <- .goal006_daily_tolerances(
          fixture$result,
          measurement_day
        )

        expect_true(all(is.finite(body_boundaries_kj)))
        expect_true(all(body_boundaries_kj >= 0))
        expect_true(all(is.finite(tolerances)))
        expect_true(all(tolerances > 0))
        expect_identical(
          tolerances[["cycle_tolerance_kj"]],
          final_cycle_tolerance_kj
        )
        expect_identical(
          daily$total_prescribed_ingested_available_energy_kj,
          2400
        )
        expect_identical(
          daily$total_maintenance_expenditure_kj,
          2400
        )
        expect_lte(
          abs(daily$observed_gut_energy_change_kj),
          tolerances[["cycle_tolerance_kj"]]
        )
        expect_lte(
          abs(daily$gut_energy_balance_residual_kj),
          tolerances[["gut_ledger_tolerance_kj"]]
        )
        expect_lte(
          abs(
            daily$total_assimilated_energy_kj -
              daily$total_prescribed_ingested_available_energy_kj
          ),
          tolerances[["assimilation_total_tolerance_kj"]]
        )
        expect_lte(
          abs(daily$body_energy_balance_residual_kj),
          tolerances[["body_ledger_tolerance_kj"]]
        )
        expect_lte(
          abs(daily$observed_body_energy_change_kj),
          tolerances[["body_neutrality_tolerance_kj"]]
        )
      }
    }

    ecological_day_1 <- .goal006_day_hourly(
      fixtures$ecological_day_resting$result,
      1L
    )
    rest_rows <-
      ecological_day_1$
        prescribed_ingested_available_energy_kj_h == 0
    feeding_rows <- !rest_rows
    expect_identical(
      ecological_day_1$time_start_h[rest_rows],
      as.numeric(8:15)
    )
    expect_identical(
      ecological_day_1$time_end_h[rest_rows],
      as.numeric(9:16)
    )
    expect_identical(
      ecological_day_1$time_start_h[feeding_rows],
      as.numeric(c(0:7, 16:23))
    )
    expect_identical(
      ecological_day_1$time_end_h[feeding_rows],
      as.numeric(c(1:8, 17:24))
    )

    mathematical_result <- fixtures$mathematical_continuous$result
    ecological_result <- fixtures$ecological_day_resting$result

    for (measurement_day in 1:2) {
      mathematical_hourly <- .goal006_day_hourly(
        mathematical_result,
        measurement_day
      )
      ecological_hourly <- .goal006_day_hourly(
        ecological_result,
        measurement_day
      )
      mathematical_daily <- .goal006_day_daily(
        mathematical_result,
        measurement_day
      )
      ecological_daily <- .goal006_day_daily(
        ecological_result,
        measurement_day
      )
      mathematical_tolerances <- .goal006_daily_tolerances(
        mathematical_result,
        measurement_day
      )
      ecological_tolerances <- .goal006_daily_tolerances(
        ecological_result,
        measurement_day
      )
      mathematical_gut_boundaries_kj <-
        .goal006_gut_boundaries_kj(mathematical_hourly)
      ecological_gut_boundaries_kj <-
        .goal006_gut_boundaries_kj(ecological_hourly)
      mathematical_body_boundaries_kj <-
        .goal006_body_boundaries_kj(mathematical_hourly)
      ecological_body_boundaries_kj <-
        .goal006_body_boundaries_kj(ecological_hourly)

      expect_identical(
        mathematical_daily$
          total_prescribed_ingested_available_energy_kj,
        ecological_daily$
          total_prescribed_ingested_available_energy_kj
      )
      expect_identical(
        mathematical_daily$total_maintenance_expenditure_kj,
        ecological_daily$total_maintenance_expenditure_kj
      )
      expect_lte(
        abs(
          mathematical_daily$total_assimilated_energy_kj -
            ecological_daily$total_assimilated_energy_kj
        ),
        mathematical_tolerances[[
          "assimilation_total_tolerance_kj"
        ]] +
          ecological_tolerances[[
            "assimilation_total_tolerance_kj"
          ]]
      )
      expect_lte(
        abs(
          mathematical_daily$observed_gut_energy_change_kj -
            ecological_daily$observed_gut_energy_change_kj
        ),
        mathematical_tolerances[["cycle_tolerance_kj"]] +
          ecological_tolerances[["cycle_tolerance_kj"]]
      )
      expect_lte(
        abs(
          mathematical_daily$observed_body_energy_change_kj -
            ecological_daily$observed_body_energy_change_kj
        ),
        mathematical_tolerances[[
          "body_neutrality_tolerance_kj"
        ]] +
          ecological_tolerances[[
            "body_neutrality_tolerance_kj"
          ]]
      )

      maximum_gut_difference_kj <- max(abs(
        mathematical_gut_boundaries_kj -
          ecological_gut_boundaries_kj
      ))
      maximum_assimilation_difference_kj <- max(abs(
        mathematical_hourly$assimilated_energy_kj -
          ecological_hourly$assimilated_energy_kj
      ))
      maximum_body_difference_kj <- max(abs(
        mathematical_body_boundaries_kj -
          ecological_body_boundaries_kj
      ))

      expect_gt(
        maximum_gut_difference_kj,
        mathematical_tolerances[["cycle_tolerance_kj"]] +
          ecological_tolerances[["cycle_tolerance_kj"]]
      )
      expect_gt(
        maximum_assimilation_difference_kj,
        mathematical_tolerances[[
          "assimilation_total_tolerance_kj"
        ]] +
          ecological_tolerances[[
            "assimilation_total_tolerance_kj"
          ]]
      )
      expect_gt(
        maximum_body_difference_kj,
        mathematical_tolerances[[
          "body_neutrality_tolerance_kj"
        ]] +
          ecological_tolerances[[
            "body_neutrality_tolerance_kj"
          ]]
      )
      expect_gte(maximum_gut_difference_kj, 340)
      expect_lte(maximum_gut_difference_kj, 341)
      expect_gte(maximum_assimilation_difference_kj, 85)
      expect_lte(maximum_assimilation_difference_kj, 86)
      expect_gte(maximum_body_difference_kj, 411)
      expect_lte(maximum_body_difference_kj, 412)

      expect_identical(
        which.max(ecological_gut_boundaries_kj) - 1L,
        8L
      )
      expect_identical(
        which.min(ecological_gut_boundaries_kj) - 1L,
        16L
      )
      expect_identical(
        ecological_hourly$hour_of_day[[
          which.max(ecological_hourly$assimilated_energy_kj)
        ]],
        8L
      )
      expect_identical(
        ecological_hourly$hour_of_day[[
          which.min(ecological_hourly$assimilated_energy_kj)
        ]],
        16L
      )
      expect_identical(
        which.max(ecological_body_boundaries_kj) - 1L,
        10L
      )
      expect_identical(
        which.min(ecological_body_boundaries_kj) - 1L,
        20L
      )
    }
  }
)
