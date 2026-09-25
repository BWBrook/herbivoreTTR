# Explicit three-page PDF renderer for 063; sourcing this helper writes nothing.

plot_feeding_access_sensitivity <- function(result, path) {
  stopifnot(is.list(result), length(path) == 1L, nzchar(path))
  d <- result$summary[result$summary$branch_evaluable, , drop = FALSE]
  if (!nrow(d)) stop("No evaluable sensitivity branches to plot.")
  grDevices::pdf(path, width = 12, height = 8.5, onefile = TRUE)
  on.exit(grDevices::dev.off())
  cols <- c(experienced = "#222222", informed = "#326C9B", cyclic = "#B27B23")
  coeff <- sort(unique(d$coefficient_m2_h))

  draw_panel <- function(x, value, ylab, title, y_limits, complete_as_228 = FALSE) {
    plot(NA, xlim = range(coeff), ylim = y_limits, xaxt = "n",
      xlab = expression("Encounter coefficient ("*m^2*" "*h^{-1}*")"),
      ylab = ylab, main = title)
    axis(1, at = coeff, labels = coeff, gap.axis = -1, cex.axis = .85)
    for (policy in intersect(names(cols), unique(x$policy))) {
      z <- x[x$policy == policy,,drop = FALSE]
      z <- z[order(z$coefficient_m2_h),,drop = FALSE]
      zvalues <- z[[value]]
      if (complete_as_228) zvalues[is.na(zvalues) & z$completed] <- 228
      lines(z$coefficient_m2_h, zvalues, col = cols[[policy]], lwd = 1.8)
      pch <- if (complete_as_228) ifelse(z$completed, 16, 4) else 16
      points(z$coefficient_m2_h, zvalues, col = cols[[policy]], pch = pch)
    }
    abline(v = .6, lty = 3, col = "grey50")
  }

  draw_page <- function(x, label, configurations) {
    x <- x[x$configuration %in% configurations,,drop = FALSE]
    x$exit_plot_day <- x$exit_day
    x$exit_plot_day[is.na(x$exit_plot_day) & x$completed] <- 228
    exit_limits <- range(x$exit_plot_day, finite = TRUE)
    if (!length(exit_limits) || diff(exit_limits) == 0) exit_limits <- c(0, 1)
    reserve_limits <- range(x$energy_end_kj, finite = TRUE)
    if (!length(reserve_limits) || diff(reserve_limits) == 0) reserve_limits <- c(0, 1)
    par(mfrow = c(2, length(configurations)), mar = c(4, 4, 3, 1),
      oma = c(2, 0, 3, 0))
    for (configuration in configurations) {
      z <- x[x$configuration == configuration,,drop = FALSE]
      if (nrow(z)) draw_panel(z, "exit_day", "Last observed day / exit day",
        configuration, exit_limits, complete_as_228 = TRUE)
      else { plot.new(); title(main = paste(label, configuration, "exit")) }
    }
    for (configuration in configurations) {
      z <- x[x$configuration == configuration,,drop = FALSE]
      if (nrow(z)) draw_panel(z, "energy_end_kj", "Reserve before exit or at day 228 (kJ)",
        configuration, reserve_limits)
      else { plot.new(); title(main = paste(label, configuration, "reserve")) }
    }
    present <- intersect(names(cols), unique(x$policy))
    legend("right", present, col = cols[present], lty = 1,
      bty = "n", cex = .9)
    mtext(label, side = 3, outer = TRUE, line = 1, font = 2)
    mtext("Top: cross = domain exit; dot at 228 = completed horizon. Lines join tested points only.",
      side = 1, outer = TRUE, line = .5, cex = .8)
  }

  sustained <- d[d$comparison == "sustained",,drop = FALSE]
  draw_page(sustained[sustained$water == "near",,drop = FALSE],
    "Sustained near", feeding_access_sensitivity_layouts)
  draw_page(sustained[sustained$water == "far",,drop = FALSE],
    "Sustained far", feeding_access_sensitivity_layouts)
  undisturbed <- d[d$comparison == "undisturbed",,drop = FALSE]
  draw_page(undisturbed, "Undisturbed near", c("clustered", "fragmented"))
  invisible(path)
}
