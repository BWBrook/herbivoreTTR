test_that("pipeline manifest lists expected targets and file formats", {
  manifest <- withr::with_dir(testthat::test_path("..", ".."), {
    targets::tar_manifest(callr_function = NULL)
  })
  expect_true(all(c(
    "conditions",
    "plants0",
    "herb0",
    "day_after_spinup",
    "sim_day1",
    "plants_day1_csv",
    "herb_day1_csv",
    "sim_day7",
    "plants_day7_csv",
    "herb_day7_csv"
  ) %in% manifest$name))

  meta <- withr::with_dir(testthat::test_path("..", ".."), {
    targets::tar_meta(fields = "format")
  })
  file_targets <- meta[meta$name %in% c("plants_day1_csv", "herb_day1_csv", "plants_day7_csv", "herb_day7_csv"), ]
  expect_true(all(file_targets$format == "file"))
})
