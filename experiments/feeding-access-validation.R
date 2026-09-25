source("experiments/feeding-access-fixtures.R")
source("experiments/feeding-access-policy-validation.R")

validate_feeding_access <- function() {
  validate_feeding_access_policy()
  system <- new_feeding_access_system()
  run <- run_feeding_access(system,final_day=6,stationary=TRUE)
  reference <- run_appetite_days(system$fixture,number_of_days=6)
  assert_that(near(run$hourly$body_energy_kj,
    reference$hourly$body_energy_reserve_end_kj),"footprint abundant animal reference")
  assert_that(max(abs(run$hourly$plant_balance_kg_dm))<1e-9 &&
    max(abs(run$hourly$energy_balance_kj))<1e-8 &&
    max(abs(run$hourly$water_balance_kg))<1e-10,"footprint integrated balances")
  densities <- c(200,300,500,600,700,1000)
  old <- pmin(.025,spatial_acquisition_rate(densities))
  new <- pmin(.025,.6/10000*pmax(densities-200,0))
  assert_that(near(old,new),"physical search preserves accepted acquisition curve")
  state <- new_feeding_access_state(system)
  state$body$body_energy_reserve_kj <- 0
  state$gut$gut_available_energy_kj <- 0
  stopped <- step_feeding_access_hour(state,system,8,1,stationary=TRUE)
  assert_that(stopped$stopped && identical(stopped$state,state),"atomic footprint domain exit")
  # Nonlinear fixed half-block field, resolved at every tested mesh.
  resolutions <- lapply(c(2L,4L,8L),function(n) run_feeding_access(
    new_feeding_access_system(subdivisions=n,heterogeneous=TRUE),final_day=14))
  variables <- c("body_energy_kj","forage_mass_kg_dm","intake_kg_dm",
    "forage_travel_h","water_travel_h","plant_growth_kg_dm","plant_senescence_kg_dm")
  for (i in 2:3) for (v in variables) assert_that(
    near(resolutions[[1]]$daily[[v]],resolutions[[i]]$daily[[v]],1e-8),
    paste("fixed heterogeneous field refinement",v))
  invisible(TRUE)
}

if (sys.nframe()==0L) {
  validate_feeding_access()
  cat("Feeding-access integration and fixed-field refinement controls passed.\n")
}
