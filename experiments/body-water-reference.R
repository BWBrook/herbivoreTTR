source("experiments/herbivore-core-fixtures.R")

normal_body_water_kg <- 28
critical_body_water_kg <- 24
daily_ordinary_water_loss_kg <- 1.56
parameters <- herbivoreTTR::new_body_water_parameters(
  normal_body_water_kg,
  critical_body_water_kg,
  daily_ordinary_water_loss_kg / 24
)

run_case <- function(case, daily_food_derived_water_kg) {
  result <- herbivoreTTR::run_body_water_day(
    herbivoreTTR::new_body_water_state(normal_body_water_kg),
    parameters,
    herbivoreTTR::new_body_water_schedule(
      0:23,
      rep(daily_food_derived_water_kg / 24, 24L),
      rep(0, 24L),
      rep(0, 24L)
    )
  )

  data.frame(
    case = case,
    food_derived_water_kg =
      result$daily$total_food_derived_water_kg,
    ordinary_water_loss_kg =
      result$daily$total_ordinary_water_loss_kg,
    excess_water_elimination_kg =
      result$daily$total_excess_water_elimination_kg,
    body_water_change_kg = result$daily$observed_body_water_change_kg,
    closing_body_water_kg = result$daily$body_water_final_kg,
    balance_residual_kg = result$daily$body_water_balance_residual_kg,
    row.names = NULL
  )
}

summary_table <- rbind(
  run_case("deficit", 1.00),
  run_case("neutral", daily_ordinary_water_loss_kg),
  run_case("surplus", 1.80)
)

assert_that(
  near(summary_table$closing_body_water_kg, c(27.44, 28, 28)) &&
    near(summary_table$body_water_change_kg, c(-0.56, 0, 0)),
  "water state follows the controlled deficit-neutral-surplus ordering"
)
assert_that(
  near(summary_table$excess_water_elimination_kg, c(0, 0, 0.24)) &&
    max(abs(summary_table$balance_residual_kg)) < 1e-12,
  "surplus water is explicit and every daily account closes"
)

cat("Body-water reference diagnostic passed.\n")
print(transform(
  summary_table,
  food_derived_water_kg = round(food_derived_water_kg, 2),
  ordinary_water_loss_kg = round(ordinary_water_loss_kg, 2),
  excess_water_elimination_kg = round(excess_water_elimination_kg, 2),
  body_water_change_kg = round(body_water_change_kg, 2),
  closing_body_water_kg = round(closing_body_water_kg, 2)
), row.names = FALSE)
