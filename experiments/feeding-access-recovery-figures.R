# Optional standalone figure; sourcing writes nothing.
plot_feeding_access_recovery <- function(result, file) {
  stopifnot(is.list(result), nrow(result$design) == 5L,
    is.character(file), length(file) == 1L, nzchar(file))
  grDevices::pdf(file, width = 9, height = 8.8, useDingbats = FALSE)
  on.exit(grDevices::dev.off())
  par(mfrow = c(3, 2), mar = c(4.7, 5.2, 2.4, .8), las = 1,
    mgp = c(3.8, 1, 0), cex.axis = .85, cex.lab = .9)
  colours <- c(old_full = "#545454", repaired = "#0072B2", informed = "#D55E00")
  styles <- c(old_full = 2, repaired = 1, informed = 3)
  for (i in seq_len(nrow(result$design))) {
    d <- result$design[i,]
    runs <- result$runs[[d$id]][names(colours)]
    runs <- Filter(Negate(is.null), runs)
    top <- 1.05 * max(40000, unlist(lapply(runs, function(x) x$daily$body_energy_kj)))
    plot(NA, xlim = c(1, 228), ylim = c(0, top), xlab = "Day",
      ylab = "Body energy reserve (kJ)",
      main = paste(d$configuration, " | q =", d$coefficient_m2_h))
    if (d$profile == "sustained") {
      rect(60, 0, 144, top, col = "#ECECEC", border = NA)
      text(102, top * .06, "Reduced growth", cex = .75)
    }
    abline(v = 60, col = "#AAAAAA", lty = 3)
    for (nm in names(runs)) {
      run <- runs[[nm]]
      lines(run$daily$day, run$daily$body_energy_kj,
        col = colours[[nm]], lty = styles[[nm]], lwd = 1.7)
      if (!is.na(run$stop_day)) points(tail(run$daily$day, 1),
        tail(run$daily$body_energy_kj, 1), pch = 4, col = colours[[nm]], lwd = 1.6)
    }
  }
  plot.new()
  legend("top", c("Original two-day expectation", "Plant-matched baseline belief",
    "Informed comparator"), col = colours, lty = styles, lwd = 1.7,
    bty = "n", cex = .95)
  text(.05, .48, paste("Five fixed scenarios; near water throughout.",
    "q: effective search area (m2 per feeding hour).",
    "Identical states at day 60 within each scenario.",
    "Grey shading: growth reduced on days 61-144.",
    "Crosses: model-domain exits, not observed deaths.",
    "Informed continuous/undisturbed case was not run.",
    "Completion is a finite-horizon outcome.", sep = "\n"),
    adj = c(0, 1), cex = .85)
  invisible(file)
}
