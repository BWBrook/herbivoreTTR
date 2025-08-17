source_all_R <- function() {
  # Source all R/ files to make internal helpers available to tests.
  # This avoids brittle per-file sourcing after refactors.
  base <- testthat::test_path("..", "..")
  rdir <- file.path(base, "R")
  files <- list.files(rdir, pattern = "\\.R$", full.names = TRUE)
  for (f in files) {
    sys.source(f, envir = topenv())
  }
  invisible(TRUE)
}

# Automatically source all R files when tests start.
source_all_R()
