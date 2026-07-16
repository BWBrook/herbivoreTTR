test_that("package metadata defines the clean foundation", {
  description_path <- test_path("..", "..", "DESCRIPTION")
  if (!file.exists(description_path)) {
    description_path <- system.file("DESCRIPTION", package = "herbivoreTTR")
  }

  expect_true(file.exists(description_path))
  description_path <- normalizePath(description_path, mustWork = TRUE)

  metadata <- read.dcf(description_path)
  authors <- eval(
    parse(text = metadata[1, "Authors@R"]),
    envir = asNamespace("utils")
  )

  expect_identical(unname(metadata[1, "Package"]), "herbivoreTTR")
  expect_identical(unname(metadata[1, "Version"]), "0.0.0.9000")
  expect_identical(unname(metadata[1, "License"]), "MIT + file LICENSE")
  expect_false("Imports" %in% colnames(metadata))
  expect_identical(unname(metadata[1, "Suggests"]), "testthat (>= 3.0.0)")
  expect_length(authors, 1L)
  expect_identical(authors[[1]]$given, "Barry")
  expect_identical(authors[[1]]$family, "Brook")
  expect_identical(authors[[1]]$role, c("aut", "cre"))
})
