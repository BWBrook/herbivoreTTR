source_all_R <- function() {
  # Source all R/ files to make internal helpers available to tests.
  # This avoids brittle per-file sourcing after refactors.
  base <- testthat::test_path("..", "..")
  rdir <- file.path(base, "R")
  files <- list.files(rdir, pattern = "\\.R$", full.names = TRUE)
  for (f in files) {
    sys.source(f, envir = topenv())
  }
  # Ensure the magrittr pipe is available for any sourced code using %>%.
  if (!exists("%>%", inherits = TRUE)) {
    if (requireNamespace("magrittr", quietly = TRUE)) {
      `%>%` <<- magrittr::`%>%`
    }
  }
  invisible(TRUE)
}

# Automatically source all R files when tests start.
load_pkg_or_source <- function() {
  if (requireNamespace("pkgload", quietly = TRUE)) {
    # Try to load the package in dev mode; fall back to sourcing on error
    ok <- TRUE
    tryCatch({
      pkgload::load_all(".", quiet = TRUE, helpers = FALSE)
    }, error = function(e) {
      ok <<- FALSE
    })
    if (ok) return(invisible(TRUE))
  }
  source_all_R()
}

# Prefer dev-mode load; otherwise source R/ directly
load_pkg_or_source()
