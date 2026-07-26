fixtures <- data.frame(
  scenario_id = c("neutral", "deficit", "surplus"),
  prescribed_assimilated_energy_kj_h = c(100, 90, 110),
  energy_status = c("neutral", "deficit", "surplus"),
  observed_body_energy_change_kj = c(0, -240, 240),
  body_energy_reserve_final_kj = c(5000, 4760, 5240),
  stringsAsFactors = FALSE
)

body_mass_ref_kg <- 50
initial_state <- herbivoreTTR::new_body_energy_state(5000)
parameters <- herbivoreTTR::new_body_energy_parameters(100)

scenario_rows <- lapply(seq_len(nrow(fixtures)), function(index) {
  schedule <- herbivoreTTR::new_assimilated_energy_schedule(
    hour_of_day = 0:23,
    prescribed_assimilated_energy_kj_h = rep(
      fixtures$prescribed_assimilated_energy_kj_h[[index]],
      24L
    )
  )
  result <- herbivoreTTR::run_body_energy_day(
    initial_state = initial_state,
    parameters = parameters,
    schedule = schedule
  )

  stopifnot(
    identical(nrow(result$hourly), 24L),
    identical(result$hourly$energy_balance_residual_kj, rep(0, 24L)),
    identical(result$daily$energy_balance_residual_kj, 0)
  )

  data.frame(
    scenario_id = fixtures$scenario_id[[index]],
    body_mass_ref_kg = body_mass_ref_kg,
    energy_status = result$daily$energy_status,
    observed_body_energy_change_kj =
      result$daily$observed_body_energy_change_kj,
    body_energy_reserve_final_kj =
      result$daily$body_energy_reserve_final_kj,
    stringsAsFactors = FALSE
  )
})

scenario_summary <- do.call(rbind, scenario_rows)
row.names(scenario_summary) <- NULL

expected_summary <- data.frame(
  scenario_id = fixtures$scenario_id,
  body_mass_ref_kg = rep(body_mass_ref_kg, 3L),
  energy_status = fixtures$energy_status,
  observed_body_energy_change_kj =
    fixtures$observed_body_energy_change_kj,
  body_energy_reserve_final_kj = fixtures$body_energy_reserve_final_kj,
  stringsAsFactors = FALSE
)

stopifnot(identical(scenario_summary, expected_summary))

write.table(
  scenario_summary,
  file = "",
  row.names = FALSE,
  quote = FALSE
)
