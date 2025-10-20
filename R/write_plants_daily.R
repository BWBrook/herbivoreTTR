#' Write daily plant outputs to CSV (semicolon-delimited)
#'
#' Produces a one-day snapshot compatible with diff-based parity checks
#' against the reference C++ output. Validates required columns and
#' finite values before writing.
#'
#' @param plants data.frame of plants.
#' @param day integer day-of-year.
#' @param year integer simulation year.
#' @param path file path for output CSV; overwritten if exists.
#' @return Invisibly TRUE on success; errors on validation failure.
write_plants_daily <- function(plants, day, year, path) {
  required <- c(
    "plant_id","veg_type","height","bleaf","bstem","bdef",
    "ms","ns","cs","mr","cr","nr"
  )
  missing <- setdiff(required, names(plants))
  if (length(missing)) stop(sprintf("Missing plant columns: %s", paste(missing, collapse = ", ")))

  # Build ordered output frame
  out <- data.frame(
    Year   = as.integer(rep(year, nrow(plants))),
    Day    = as.integer(rep(day, nrow(plants))),
    Plant  = plants$plant_id,
    VegType= plants$veg_type,
    Height = plants$height,
    BLeaf  = plants$bleaf,
    BStem  = plants$bstem,
    BDef   = plants$bdef,
    Ms     = plants$ms,
    Ns     = plants$ns,
    Cs     = plants$cs,
    Mr     = plants$mr,
    Cr     = plants$cr,
    Nr     = plants$nr,
    check.names = FALSE
  )

  # Validation: finite numerics, no NA/Inf/NaN
  # Year/Day/Plant/VegType can be integer; coerce to numeric for finiteness check
  any_bad_numeric <- vapply(
    out,
    function(v) is.numeric(v) && any(!is.finite(v)),
    logical(1L)
  )
  if (anyNA(out) || any(any_bad_numeric)) {
    stop("Non-finite or NA values present in plant output; refusing to write")
  }

  # Overwrite file; write headers always; semicolon delimiter; UTF-8
  utils::write.table(out, file = path, sep = ";", row.names = FALSE, col.names = TRUE,
                     quote = FALSE, fileEncoding = "UTF-8", eol = "\n")

  # Post-validate header and column order
  header_expected <- paste(colnames(out), collapse = ";")
  hdr <- readLines(path, n = 1L, warn = FALSE)
  if (!identical(hdr, header_expected)) stop("Header mismatch after write")

  invisible(TRUE)
}
