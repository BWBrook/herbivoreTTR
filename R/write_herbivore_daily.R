#' Write daily herbivore outputs to CSV (semicolon-delimited)
#'
#' Produces a one-day snapshot compatible with diff-based parity checks
#' against the reference C++ output. Validates required fields and
#' finite values before writing.
#'
#' @param herbivore list-like herbivore object.
#' @param day integer day-of-year.
#' @param year integer simulation year.
#' @param path file path for output CSV; overwritten if exists.
#' @return Invisibly TRUE on success; errors on validation failure.
write_herbivores_daily <- function(herbivore, day, year, path) {
  required <- c(
    "herb_type","mass","xcor","ycor","distance_moved","intake_PE_day",
    "intake_NPE_day","intake_total_day","intake_water_forage","intake_total",
    "water_balance","energy_balance"
  )
  missing <- setdiff(required, names(herbivore))
  if (length(missing)) stop(sprintf("Missing herbivore fields: %s", paste(missing, collapse = ", ")))

  out <- data.frame(
    Year            = as.integer(year),
    Day             = as.integer(day),
    HerbType        = herbivore$herb_type,
    Mass            = herbivore$mass,
    xcor            = herbivore$xcor,
    ycor            = herbivore$ycor,
    DailyDistMoved  = herbivore$distance_moved,
    DailyPEI        = herbivore$intake_PE_day,
    DailyNPEI       = herbivore$intake_NPE_day,
    DailyDMI        = herbivore$intake_total_day,
    DailyForageWater= herbivore$intake_water_forage,
    TotalDMI        = herbivore$intake_total,
    WaterBalance    = herbivore$water_balance,
    EnergyBalance   = herbivore$energy_balance,
    check.names = FALSE
  )

  # Validation: finite numerics, no NA/Inf/NaN
  if (any(!vapply(out, is.numeric, logical(1L)))) stop("Non-numeric values in herbivore output")
  if (any(!is.finite(as.numeric(as.matrix(out))))) stop("Non-finite values in herbivore output")

  utils::write.table(out, file = path, sep = ";", row.names = FALSE, col.names = TRUE,
                     quote = FALSE, fileEncoding = "UTF-8", eol = "\n")

  header_expected <- paste(colnames(out), collapse = ";")
  hdr <- readLines(path, n = 1L, warn = FALSE)
  if (!identical(hdr, header_expected)) stop("Header mismatch after write")
  invisible(TRUE)
}
