.goal008_scenario_ids <- c(
  "ecological_day_resting",
  "ecological_activity_uncompensated",
  "ecological_activity_prescribed_balance"
)

.goal008_active_hours <- c(0:7, 16:23)

.goal008_dry_matter_rates <- list(
  ecological_day_resting = c(
    rep(0.015, 8L),
    rep(0, 8L),
    rep(0.015, 8L)
  ),
  ecological_activity_uncompensated = c(
    rep(0.015, 8L),
    rep(0, 8L),
    rep(0.015, 8L)
  ),
  ecological_activity_prescribed_balance = c(
    rep(0.020, 8L),
    rep(0, 8L),
    rep(0.020, 8L)
  )
)

.goal008_energy_rates <- list(
  ecological_day_resting = c(
    rep(150, 8L),
    rep(0, 8L),
    rep(150, 8L)
  ),
  ecological_activity_uncompensated = c(
    rep(150, 8L),
    rep(0, 8L),
    rep(150, 8L)
  ),
  ecological_activity_prescribed_balance = c(
    rep(200, 8L),
    rep(0, 8L),
    rep(200, 8L)
  )
)

.goal008_activity_rates <- list(
  ecological_day_resting = rep(0, 24L),
  ecological_activity_uncompensated = c(
    rep(50, 8L),
    rep(0, 8L),
    rep(50, 8L)
  ),
  ecological_activity_prescribed_balance = c(
    rep(50, 8L),
    rep(0, 8L),
    rep(50, 8L)
  )
)

.goal008_gut_fields <- c(
  "measurement_day",
  "hour_of_day",
  "time_start_h",
  "time_end_h",
  "gut_available_energy_start_kj",
  "prescribed_ingested_available_energy_kj_h",
  "gut_release_fraction_h",
  "assimilated_energy_kj_h",
  "prescribed_ingested_available_energy_kj",
  "assimilated_energy_kj",
  "gut_energy_change_kj",
  "gut_available_energy_end_kj",
  "gut_energy_balance_residual_kj"
)

.goal008_new_fixture <- function(scenario_id) {
  dry_matter_schedule <-
    herbivoreTTR::new_dry_matter_intake_schedule(
      hour_of_day = 0:23,
      prescribed_dry_matter_intake_kg_dm_h =
        .goal008_dry_matter_rates[[scenario_id]]
    )
  energy_schedule <-
    herbivoreTTR::derive_ingested_available_energy_schedule(
      herbivoreTTR::new_food_energy_parameters(10000),
      dry_matter_schedule
    )
  routine_activity_schedule <-
    herbivoreTTR::new_routine_activity_expenditure_schedule(
      hour_of_day = 0:23,
      prescribed_routine_activity_expenditure_kj_h =
        .goal008_activity_rates[[scenario_id]]
    )
  result <- herbivoreTTR::run_gut_body_energy_reference_cycle(
    initial_gut_state = herbivoreTTR::new_gut_energy_state(0),
    measurement_body_state =
      herbivoreTTR::new_body_energy_state(10000),
    gut_parameters = herbivoreTTR::new_gut_energy_parameters(0.25),
    body_parameters = herbivoreTTR::new_body_energy_parameters(100),
    schedule = energy_schedule,
    routine_activity_schedule = routine_activity_schedule,
    gut_convergence_relative_tolerance =
      100 * .Machine$double.eps,
    max_burn_in_days = 100L
  )

  list(
    scenario_id = scenario_id,
    dry_matter_schedule = dry_matter_schedule,
    energy_schedule = energy_schedule,
    routine_activity_schedule = routine_activity_schedule,
    result = result
  )
}

.goal008_fixtures <- function() {
  fixtures <- lapply(.goal008_scenario_ids, .goal008_new_fixture)
  names(fixtures) <- .goal008_scenario_ids
  fixtures
}

.goal008_day_rows <- function(result, table_name, measurement_day) {
  table <- result[[table_name]]
  table[
    table$measurement_day == measurement_day,
    ,
    drop = FALSE
  ]
}

.goal008_gut_boundaries_kj <- function(hourly) {
  c(
    hourly$gut_available_energy_start_kj[[1L]],
    hourly$gut_available_energy_end_kj
  )
}

.goal008_body_boundaries_kj <- function(hourly) {
  c(
    hourly$body_energy_reserve_start_kj[[1L]],
    hourly$body_energy_reserve_end_kj
  )
}

.goal008_canonical_equal <- function(left, right) {
  row.names(left) <- NULL
  row.names(right) <- NULL
  identical(left, right)
}

.goal008_scale_tolerance <- function(observed, predicted) {
  100 * .Machine$double.eps *
    pmax(1, abs(observed), abs(predicted))
}

.goal008_daily_tolerances <- function(result, measurement_day) {
  hourly <- .goal008_day_rows(
    result,
    "hourly",
    measurement_day
  )
  daily <- .goal008_day_rows(
    result,
    "daily",
    measurement_day
  )
  cycle_tolerance_kj <- tail(
    result$convergence$realized_convergence_tolerance_kj,
    1L
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
    sum(abs(hourly$maintenance_expenditure_kj)),
    sum(abs(hourly$prescribed_routine_activity_expenditure_kj))
  )
  system_ledger_tolerance_kj <- 100 * .Machine$double.eps * max(
    1,
    abs(daily$total_system_energy_initial_kj),
    abs(daily$total_system_energy_final_kj),
    sum(abs(hourly$prescribed_ingested_available_energy_kj)),
    sum(abs(hourly$assimilated_energy_kj)),
    sum(abs(hourly$maintenance_expenditure_kj)),
    sum(abs(hourly$prescribed_routine_activity_expenditure_kj))
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
        body_ledger_tolerance_kj,
    system_ledger_tolerance_kj = system_ledger_tolerance_kj
  )
}

test_that(
  "ecological-activity-intake-balance fixes the three prescribed schedules",
  {
    fixtures <- .goal008_fixtures()
    expected_dry_matter_totals <- c(0.24, 0.24, 0.32)
    expected_energy_totals <- c(2400, 2400, 3200)
    expected_activity_totals <- c(0, 800, 800)

    expect_identical(names(fixtures), .goal008_scenario_ids)

    for (index in seq_along(fixtures)) {
      scenario_id <- .goal008_scenario_ids[[index]]
      fixture <- fixtures[[scenario_id]]
      dry_matter <- fixture$dry_matter_schedule
      energy <- fixture$energy_schedule
      activity <- fixture$routine_activity_schedule
      result <- fixture$result

      expect_identical(fixture$scenario_id, scenario_id)
      expect_identical(dry_matter$hour_of_day, 0:23)
      expect_identical(energy$hour_of_day, 0:23)
      expect_identical(activity$hour_of_day, 0:23)
      expect_identical(
        dry_matter$prescribed_dry_matter_intake_kg_dm_h,
        .goal008_dry_matter_rates[[scenario_id]]
      )
      expect_identical(
        energy$prescribed_ingested_available_energy_kj_h,
        .goal008_energy_rates[[scenario_id]]
      )
      expect_identical(
        activity$prescribed_routine_activity_expenditure_kj_h,
        .goal008_activity_rates[[scenario_id]]
      )
      expect_identical(
        as.integer(which(
          energy$prescribed_ingested_available_energy_kj_h > 0
        ) - 1L),
        .goal008_active_hours
      )
      expect_identical(
        as.integer(which(
          energy$prescribed_ingested_available_energy_kj_h == 0
        ) - 1L),
        8:15
      )
      expect_lte(
        abs(
          sum(dry_matter$prescribed_dry_matter_intake_kg_dm_h) -
            expected_dry_matter_totals[[index]]
        ),
        100 * .Machine$double.eps
      )
      expect_identical(
        sum(energy$prescribed_ingested_available_energy_kj_h),
        expected_energy_totals[[index]]
      )
      expect_identical(
        sum(activity$prescribed_routine_activity_expenditure_kj_h),
        expected_activity_totals[[index]]
      )
      expect_identical(
        result$hourly$prescribed_ingested_available_energy_kj_h,
        rep(.goal008_energy_rates[[scenario_id]], 2L)
      )
      expect_identical(
        result$hourly$
          prescribed_routine_activity_expenditure_kj_h,
        rep(.goal008_activity_rates[[scenario_id]], 2L)
      )
      expect_identical(
        result$daily$
          total_prescribed_ingested_available_energy_kj,
        rep(expected_energy_totals[[index]], 2L)
      )
      expect_identical(
        result$daily$
          total_prescribed_routine_activity_expenditure_kj,
        rep(expected_activity_totals[[index]], 2L)
      )
      expect_identical(
        result$daily$total_maintenance_expenditure_kj,
        rep(2400, 2L)
      )
    }
  }
)

test_that(
  "ecological-activity-intake-balance converges and carries measured states",
  {
    fixtures <- .goal008_fixtures()
    expected_status <- list(
      ecological_day_resting = rep("neutral", 2L),
      ecological_activity_uncompensated = rep("deficit", 2L),
      ecological_activity_prescribed_balance = rep("neutral", 2L)
    )

    for (scenario_id in .goal008_scenario_ids) {
      result <- fixtures[[scenario_id]]$result
      convergence <- result$convergence
      final_tolerance_kj <- tail(
        convergence$realized_convergence_tolerance_kj,
        1L
      )
      day_1 <- .goal008_day_rows(result, "hourly", 1L)
      day_2 <- .goal008_day_rows(result, "hourly", 2L)

      expect_identical(convergence$burn_in_day, seq_len(7L))
      expect_identical(
        convergence$converged,
        c(rep(FALSE, 6L), TRUE)
      )
      expect_true(all(is.finite(
        convergence$
          max_abs_previous_day_trajectory_difference_kj[-1L]
      )))
      expect_true(all(is.finite(
        convergence$realized_convergence_tolerance_kj[-1L]
      )))
      expect_true(all(
        convergence$realized_convergence_tolerance_kj[-1L] > 0
      ))
      expect_lte(
        abs(tail(convergence$cycle_boundary_change_kj, 1L)),
        final_tolerance_kj
      )
      expect_lte(
        tail(
          convergence$
            max_abs_previous_day_trajectory_difference_kj,
          1L
        ),
        final_tolerance_kj
      )
      expect_lte(
        max(abs(
          .goal008_gut_boundaries_kj(day_2) -
            .goal008_gut_boundaries_kj(day_1)
        )),
        final_tolerance_kj
      )
      expect_true(.goal008_canonical_equal(
        day_1[
          setdiff(
            .goal008_gut_fields,
            c("measurement_day", "time_start_h", "time_end_h")
          )
        ],
        day_2[
          setdiff(
            .goal008_gut_fields,
            c("measurement_day", "time_start_h", "time_end_h")
          )
        ]
      ))
      expect_identical(
        result$hourly$gut_available_energy_start_kj[-1L],
        head(result$hourly$gut_available_energy_end_kj, -1L)
      )
      expect_identical(
        result$hourly$body_energy_reserve_start_kj[-1L],
        head(result$hourly$body_energy_reserve_end_kj, -1L)
      )
      expect_identical(
        result$hourly$total_system_energy_start_kj[-1L],
        head(result$hourly$total_system_energy_end_kj, -1L)
      )
      expect_true(all(is.finite(unlist(
        result$hourly[c(
          "gut_available_energy_start_kj",
          "gut_available_energy_end_kj",
          "body_energy_reserve_start_kj",
          "body_energy_reserve_end_kj"
        )],
        use.names = FALSE
      ))))
      expect_true(all(unlist(
        result$hourly[c(
          "gut_available_energy_start_kj",
          "gut_available_energy_end_kj",
          "body_energy_reserve_start_kj",
          "body_energy_reserve_end_kj"
        )],
        use.names = FALSE
      ) >= 0))
      expect_identical(
        result$daily$body_energy_status,
        expected_status[[scenario_id]]
      )
    }
  }
)

test_that(
  "ecological-activity-intake-balance reconstructs every energy ledger",
  {
    fixtures <- .goal008_fixtures()

    for (scenario_id in .goal008_scenario_ids) {
      result <- fixtures[[scenario_id]]$result

      for (measurement_day in 1:2) {
        hourly <- .goal008_day_rows(
          result,
          "hourly",
          measurement_day
        )
        daily <- .goal008_day_rows(
          result,
          "daily",
          measurement_day
        )
        tolerances <- .goal008_daily_tolerances(
          result,
          measurement_day
        )
        hourly_gut_expected <-
          hourly$prescribed_ingested_available_energy_kj -
            hourly$assimilated_energy_kj
        hourly_gut_observed <-
          hourly$gut_available_energy_end_kj -
            hourly$gut_available_energy_start_kj
        hourly_body_expected <-
          hourly$assimilated_energy_kj -
            hourly$maintenance_expenditure_kj -
            hourly$prescribed_routine_activity_expenditure_kj
        hourly_body_observed <-
          hourly$body_energy_reserve_end_kj -
            hourly$body_energy_reserve_start_kj
        hourly_system_expected <-
          hourly$prescribed_ingested_available_energy_kj -
            hourly$maintenance_expenditure_kj -
            hourly$prescribed_routine_activity_expenditure_kj
        hourly_system_observed <-
          hourly$total_system_energy_end_kj -
            hourly$total_system_energy_start_kj
        hourly_scale <- 100 * .Machine$double.eps * pmax(
          1,
          abs(hourly$total_system_energy_start_kj),
          abs(hourly$total_system_energy_end_kj),
          abs(hourly$prescribed_ingested_available_energy_kj),
          abs(hourly$assimilated_energy_kj),
          abs(hourly$maintenance_expenditure_kj),
          abs(hourly$prescribed_routine_activity_expenditure_kj)
        )

        expect_lte(
          max(abs(
            hourly$gut_energy_change_kj -
              hourly_gut_expected
          )),
          max(hourly_scale)
        )
        expect_lte(
          max(abs(
            hourly$gut_energy_balance_residual_kj -
              (hourly_gut_observed - hourly_gut_expected)
          )),
          max(hourly_scale)
        )
        expect_lte(
          max(abs(
            hourly$body_energy_change_kj -
              hourly_body_expected
          )),
          max(hourly_scale)
        )
        expect_lte(
          max(abs(
            hourly$body_energy_balance_residual_kj -
              (hourly_body_observed - hourly_body_expected)
          )),
          max(hourly_scale)
        )
        expect_lte(
          max(abs(
            hourly$system_energy_balance_residual_kj -
              (hourly_system_observed - hourly_system_expected)
          )),
          max(hourly_scale)
        )
        expect_lte(
          max(abs(
            hourly$net_body_energy_rate_kj_h -
              (
                hourly$assimilated_energy_kj_h -
                  hourly$maintenance_expenditure_kj_h -
                  hourly$
                    prescribed_routine_activity_expenditure_kj_h
              )
          )),
          max(hourly_scale)
        )

        daily_gut_expected <-
          sum(hourly$prescribed_ingested_available_energy_kj) -
            sum(hourly$assimilated_energy_kj)
        daily_gut_observed <-
          daily$gut_available_energy_final_kj -
            daily$gut_available_energy_initial_kj
        daily_body_expected <-
          sum(hourly$assimilated_energy_kj) -
            sum(hourly$maintenance_expenditure_kj) -
            sum(hourly$prescribed_routine_activity_expenditure_kj)
        daily_body_observed <-
          daily$body_energy_reserve_final_kj -
            daily$body_energy_reserve_initial_kj
        daily_system_expected <-
          sum(hourly$prescribed_ingested_available_energy_kj) -
            sum(hourly$maintenance_expenditure_kj) -
            sum(hourly$prescribed_routine_activity_expenditure_kj)
        daily_system_observed <-
          daily$total_system_energy_final_kj -
            daily$total_system_energy_initial_kj

        expect_identical(
          daily$expected_gut_energy_change_kj,
          daily_gut_expected
        )
        expect_identical(
          daily$observed_gut_energy_change_kj,
          daily_gut_observed
        )
        expect_lte(
          abs(
            daily$gut_energy_balance_residual_kj -
              (daily_gut_observed - daily_gut_expected)
          ),
          tolerances[["gut_ledger_tolerance_kj"]]
        )
        expect_lte(
          abs(daily$gut_energy_balance_residual_kj),
          tolerances[["gut_ledger_tolerance_kj"]]
        )
        expect_identical(
          daily$expected_body_energy_change_kj,
          daily_body_expected
        )
        expect_identical(
          daily$observed_body_energy_change_kj,
          daily_body_observed
        )
        expect_lte(
          abs(
            daily$body_energy_balance_residual_kj -
              (daily_body_observed - daily_body_expected)
          ),
          tolerances[["body_ledger_tolerance_kj"]]
        )
        expect_lte(
          abs(daily$body_energy_balance_residual_kj),
          tolerances[["body_ledger_tolerance_kj"]]
        )
        expect_identical(
          daily$expected_total_system_energy_change_kj,
          daily_system_expected
        )
        expect_identical(
          daily$observed_total_system_energy_change_kj,
          daily_system_observed
        )
        expect_lte(
          abs(
            daily$system_energy_balance_residual_kj -
              (daily_system_observed - daily_system_expected)
          ),
          tolerances[["system_ledger_tolerance_kj"]]
        )
        expect_lte(
          abs(daily$system_energy_balance_residual_kj),
          tolerances[["system_ledger_tolerance_kj"]]
        )

        if (scenario_id !=
          "ecological_activity_uncompensated") {
          expect_lte(
            abs(daily$observed_gut_energy_change_kj),
            tolerances[["cycle_tolerance_kj"]]
          )
          expect_lte(
            abs(
              daily$total_assimilated_energy_kj -
                daily$
                  total_prescribed_ingested_available_energy_kj
            ),
            tolerances[[
              "assimilation_total_tolerance_kj"
            ]]
          )
          expect_lte(
            abs(daily$observed_body_energy_change_kj),
            tolerances[["body_neutrality_tolerance_kj"]]
          )
          expect_lte(
            abs(daily$observed_total_system_energy_change_kj),
            tolerances[["system_ledger_tolerance_kj"]]
          )
        }
      }
    }
  }
)

test_that(
  "ecological-activity-intake-balance separates activity from added input",
  {
    fixtures <- .goal008_fixtures()
    baseline <- fixtures$ecological_day_resting$result
    unbalanced <-
      fixtures$ecological_activity_uncompensated$result
    balanced <-
      fixtures$ecological_activity_prescribed_balance$result
    expected_activity_difference <- rep(
      c(rep(50, 8L), rep(0, 8L), rep(50, 8L)),
      2L
    )

    expect_identical(unbalanced$convergence, baseline$convergence)
    expect_identical(
      unbalanced$hourly[.goal008_gut_fields],
      baseline$hourly[.goal008_gut_fields]
    )
    observed_net_rate_difference <-
      baseline$hourly$net_body_energy_rate_kj_h -
        unbalanced$hourly$net_body_energy_rate_kj_h
    observed_body_change_difference <-
      baseline$hourly$body_energy_change_kj -
        unbalanced$hourly$body_energy_change_kj
    expect_true(all(
      abs(
        observed_net_rate_difference -
          expected_activity_difference
      ) <= .goal008_scale_tolerance(
        observed_net_rate_difference,
        expected_activity_difference
      )
    ))
    expect_true(all(
      abs(
        observed_body_change_difference -
          expected_activity_difference
      ) <= .goal008_scale_tolerance(
        observed_body_change_difference,
        expected_activity_difference
      )
    )
    )
    expect_identical(
      baseline$daily$observed_body_energy_change_kj -
        unbalanced$daily$observed_body_energy_change_kj,
      c(800, 800)
    )
    expect_identical(
      baseline$daily$
        observed_total_system_energy_change_kj -
        unbalanced$daily$
          observed_total_system_energy_change_kj,
      c(800, 800)
    )

    baseline_boundaries <- .goal008_body_boundaries_kj(
      baseline$hourly
    )
    unbalanced_boundaries <- .goal008_body_boundaries_kj(
      unbalanced$hourly
    )
    landmark_indices <- c(1L, 9L, 17L, 25L, 33L, 41L, 49L)
    expect_identical(
      baseline_boundaries[landmark_indices] -
        unbalanced_boundaries[landmark_indices],
      c(0, 400, 400, 800, 1200, 1200, 1600)
    )
    expect_identical(
      baseline$daily$body_energy_reserve_final_kj -
        unbalanced$daily$body_energy_reserve_final_kj,
      c(800, 1600)
    )

    expect_identical(
      balanced$hourly$
        prescribed_routine_activity_expenditure_kj_h,
      unbalanced$hourly$
        prescribed_routine_activity_expenditure_kj_h
    )
    expect_identical(
      balanced$hourly$maintenance_expenditure_kj_h,
      unbalanced$hourly$maintenance_expenditure_kj_h
    )
    expect_identical(
      balanced$hourly$
        prescribed_ingested_available_energy_kj_h -
        unbalanced$hourly$
          prescribed_ingested_available_energy_kj_h,
      expected_activity_difference
    )
    expect_identical(
      balanced$daily$
        total_prescribed_ingested_available_energy_kj -
        unbalanced$daily$
          total_prescribed_ingested_available_energy_kj,
      c(800, 800)
    )

    for (measurement_day in 1:2) {
      balanced_daily <- .goal008_day_rows(
        balanced,
        "daily",
        measurement_day
      )
      unbalanced_daily <- .goal008_day_rows(
        unbalanced,
        "daily",
        measurement_day
      )
      balanced_tolerance <- .goal008_daily_tolerances(
        balanced,
        measurement_day
      )
      unbalanced_tolerance <- .goal008_daily_tolerances(
        unbalanced,
        measurement_day
      )

      expect_lte(
        abs(
          (
            balanced_daily$total_assimilated_energy_kj -
              unbalanced_daily$total_assimilated_energy_kj
          ) - 800
        ),
        balanced_tolerance[[
          "assimilation_total_tolerance_kj"
        ]] +
          unbalanced_tolerance[[
            "assimilation_total_tolerance_kj"
          ]]
      )
      expect_lte(
        abs(
          (
            balanced_daily$observed_body_energy_change_kj -
              unbalanced_daily$observed_body_energy_change_kj
          ) - 800
        ),
        balanced_tolerance[[
          "body_neutrality_tolerance_kj"
        ]] +
          unbalanced_tolerance[[
            "body_neutrality_tolerance_kj"
          ]]
      )
      expect_lte(
        abs(
          (
            balanced_daily$
              observed_total_system_energy_change_kj -
              unbalanced_daily$
                observed_total_system_energy_change_kj
          ) - 800
        ),
        balanced_tolerance[["system_ledger_tolerance_kj"]] +
          unbalanced_tolerance[["system_ledger_tolerance_kj"]]
      )
      expect_lte(
        abs(
          (
            balanced_daily$body_energy_reserve_final_kj -
              unbalanced_daily$body_energy_reserve_final_kj
          ) - 800 * measurement_day
        ),
        balanced_tolerance[[
          "body_neutrality_tolerance_kj"
        ]] +
          unbalanced_tolerance[[
            "body_neutrality_tolerance_kj"
          ]]
      )
    }
  }
)

test_that(
  "ecological-activity-intake-balance verifies four-thirds scaling",
  {
    fixtures <- .goal008_fixtures()
    baseline <- fixtures$ecological_day_resting$result
    balanced <-
      fixtures$ecological_activity_prescribed_balance$result
    ratio <- 4 / 3

    expect_scaled <- function(observed, baseline_value) {
      predicted <- ratio * baseline_value
      expect_true(all(
        abs(observed - predicted) <=
          .goal008_scale_tolerance(observed, predicted)
      ))
    }

    expect_scaled(
      balanced$convergence$gut_available_energy_initial_kj,
      baseline$convergence$gut_available_energy_initial_kj
    )
    expect_scaled(
      balanced$convergence$gut_available_energy_final_kj,
      baseline$convergence$gut_available_energy_final_kj
    )
    expect_scaled(
      balanced$hourly$gut_available_energy_start_kj,
      baseline$hourly$gut_available_energy_start_kj
    )
    expect_scaled(
      balanced$hourly$gut_available_energy_end_kj,
      baseline$hourly$gut_available_energy_end_kj
    )
    expect_scaled(
      balanced$hourly$assimilated_energy_kj_h,
      baseline$hourly$assimilated_energy_kj_h
    )
    expect_scaled(
      balanced$hourly$assimilated_energy_kj,
      baseline$hourly$assimilated_energy_kj
    )

    expected_net_rate_contrast <-
      baseline$hourly$assimilated_energy_kj_h / 3 -
        balanced$hourly$
          prescribed_routine_activity_expenditure_kj_h
    observed_net_rate_contrast <-
      balanced$hourly$net_body_energy_rate_kj_h -
        baseline$hourly$net_body_energy_rate_kj_h
    expect_true(all(
      abs(
        observed_net_rate_contrast -
          expected_net_rate_contrast
      ) <= .goal008_scale_tolerance(
        observed_net_rate_contrast,
        expected_net_rate_contrast
      )
    ))
    expect_gt(max(abs(observed_net_rate_contrast)), 0)
    expect_gt(
      max(abs(
        .goal008_body_boundaries_kj(balanced$hourly) -
          .goal008_body_boundaries_kj(baseline$hourly)
      )),
      0
    )
  }
)
