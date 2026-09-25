# Two explicitly post-main recovery contrasts, keeping the main matrix intact.
source("experiments/feeding-access-study.R")

run_feeding_access_recovery_followup <- function(main_result) {
  system <- main_result$systems$continuous_1_bounded
  baseline <- main_result$baselines$continuous_1_bounded
  runs <- setNames(lapply(c("near","far"),function(w) run_feeding_access(system,
    profile="short_pulse",water=w,baseline=baseline,
    return_forecast=feeding_two_day_expected_return)),c("near","far"))
  for(r in runs) {
    stopifnot(identical(r$initial_branch_state,baseline$final_state))
    assert_that(max(abs(r$hourly$plant_balance_kg_dm))<1e-9 &&
      max(abs(r$hourly$energy_balance_kj))<1e-8 &&
      max(abs(r$hourly$water_balance_kg))<1e-10,"follow-up conservation")
  }
  summary <- do.call(rbind,lapply(names(runs),function(w) cbind(
    water=w,feeding_access_summary(runs[[w]],system,"short_pulse"))))
  list(runs=runs,summary=summary)
}
