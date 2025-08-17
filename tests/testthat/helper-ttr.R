local({
  # Source only the TTR helper files for unit tests, without loading the full package
  suppressWarnings(suppressMessages({
    src1 <- file.path(testthat::test_path("..", ".."), "R", "ttr_forcing.R") # need to update, this file no longer exists because helpers have been split into individual scripts
    src2 <- file.path(testthat::test_path("..", ".."), "R", "ttr_resistance.R") # need to update, this file no longer exists because helpers have been split into individual scripts
    if (file.exists(src1)) sys.source(src1, envir = topenv())
    if (file.exists(src2)) sys.source(src2, envir = topenv())
  }))
})

