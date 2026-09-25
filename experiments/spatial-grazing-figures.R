# Explicit rendering helper; sourcing writes nothing.
plot_spatial_grazing_study <- function(result, path) {
  stopifnot(is.character(path), length(path) == 1L, nzchar(path))
  grDevices::pdf(path, width = 11, height = 8.5, onefile = TRUE)
  on.exit(grDevices::dev.off())
  old <- par(mfrow = c(2, 2), mar = c(4, 4, 3, 1), oma = c(0, 0, 3, 0))
  on.exit(par(old), add = TRUE, after = FALSE)
  for (area in c(.08, .04)) {
    d <- subset(result$design, area_ha == area & grepl("^factorial", id))
    col <- ifelse(d$growth_multiplier == 1, "#17665B", "#AF4A32")
    lty <- ifelse(d$water_duration_h == .5, 1, 2)
    lwd <- ifelse(d$water_cost_kj == 0, 1, 2.6)
    for (variable in c("body_energy_kj", "forage_mass_kg_dm")) {
      ylim <- range(c(0, unlist(lapply(result$runs[d$id], function(x)
        x$daily[[variable]]))))
      if (variable == "body_energy_kj") ylim <- ylim / 1000
      plot(NA, xlim = c(0, 204), ylim = ylim, xlab = "Day",
        ylab = if (variable == "body_energy_kj") "Body energy reserve (MJ)" else
          "Landscape standing forage (kg DM)", main = paste(area, "ha of forage"))
      rect(60, par("usr")[3], 144, par("usr")[4],
        col = "#EEEAE2", border = NA)
      for (i in seq_len(nrow(d))) {
        x <- result$runs[[d$id[i]]]$daily
        y <- x[[variable]] / if (variable == "body_energy_kj") 1000 else 1
        lines(x$day, y, col = col[i], lty = lty[i], lwd = lwd[i])
        if (!is.na(result$runs[[d$id[i]]]$stop_day))
          points(tail(x$day, 1), tail(y, 1), pch = 4, col = col[i])
      }
      if (area == .08 && variable == "body_energy_kj") {
        legend("bottomleft", c("Growth 1", "Growth 0.6", "Trip 0.5 h", "Trip 3 h",
          "Cost 0 kJ", "Cost 900 kJ"), col = c("#17665B", "#AF4A32", rep("grey30",4)),
          lty = c(1,1,1,2,1,1), lwd = c(2,2,1,1,1,2.6), bty = "n", cex = .7)
      }
    }
  }
  mtext("One focal herbivore: independent supply and water-access contrasts", outer = TRUE, cex = 1.15)
  par(mfrow = c(2, 2), oma = c(0, 0, 3, 0))
  ids <- c("factorial_15", "informed", "homogeneous", "subdivide_periodic", "subdivide_bounded")
  colors <- c("#222222", "#326C9B", "#946D1A", "#B75135", "#72579C")
  labels <- c("Four supports, local", "Four supports, informed", "Homogeneous plants",
    "16 supports, periodic", "16 supports, bounded")
  for (variable in c("body_energy_kj", "forage_mass_kg_dm", "min_water_kg", "forage_travel_h")) {
    ylim <- range(unlist(lapply(result$runs[ids], function(x) x$daily[[variable]])))
    plot(NA, xlim = c(0,204), ylim = ylim, xlab = "Day", ylab = switch(variable,
      body_energy_kj = "Body energy reserve (kJ)", forage_mass_kg_dm = "Standing forage (kg DM)",
      min_water_kg = "Daily minimum body water (kg)", forage_travel_h = "Forage travel (h/day)"))
    rect(60, par("usr")[3], 144, par("usr")[4], col = "#EEEAE2", border = NA)
    for (i in seq_along(ids)) {
      x <- result$runs[[ids[i]]]$daily
      lines(x$day, x[[variable]], col = colors[i], lwd = 1.4)
    }
    if (variable == "body_energy_kj") legend("bottomleft", labels, col = colors,
      lty = 1, bty = "n", cex = .7)
  }
  mtext("Structural sensitivity: 0.08 ha, growth 0.6, water trip 3 h / 900 kJ", outer = TRUE, cex = 1.1)
  invisible(path)
}
