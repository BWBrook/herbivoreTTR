# Plot only on an explicitly opened device; no sourcing side effects.
plot_red_kangaroo_water <- function(budget) {
  old <- par(mfrow = c(1, 2), mar = c(5, 4.5, 4.5, 1),
    oma = c(3, 0, 2, 0), las = 1)
  on.exit(par(old))
  x <- seq(0, 3.5, length.out = 301)
  for (i in seq_len(nrow(budget$energy))) {
    intake <- budget$energy$derived_intake_kg_dm_day[[i]]
    plot(NA, xlim = c(0, 3.5), ylim = c(-0.6, 1.6),
      xlab = "Food-water yield (kg water / kg DM)",
      ylab = "Required drinking water (kg/day)",
      main = if (i == 1) "Published DE conversion" else "Assumed ME:DE = 0.9",
      cex.main = 1)
    rect(-0.1, -1, 4, 0, col = "#FCE8E6", border = NA)
    abline(h = 0, col = "#999999")
    lines(x, 1.5 - intake * x, col = "#245A81", lwd = 2)
    lines(x, 1.5 - 0.15 - intake * x, col = "#C4762B", lwd = 2, lty = 2)
    abline(v = 3.28, col = "#777777", lty = 3)
    points(rep(3.28, 2), 1.5 - intake * 3.28 - c(0, 0.15),
      pch = c(16, 17), col = c("#245A81", "#C4762B"))
    mtext(sprintf("Derived intake %.0f g DM/day", 1000 * intake),
      side = 3, line = 0.4, cex = 0.85)
    text(0.15, -0.48, "Negative drinking: infeasible combination", adj = 0,
      col = "#8B352D", cex = 0.7)
    legend("topright", c("Metabolic water = 0", "Illustrative 0.15 kg/day"),
      col = c("#245A81", "#C4762B"), lty = c(1, 2), lwd = 2,
      bty = "n", cex = 0.74)
  }
  mtext("Munn: daily energy and water accounting", outer = TRUE,
    side = 3, line = 0.4, font = 2, cex = 1.1)
  mtext("Turnover = 1.5 kg/day; FMR = 4,872 kJ/day. Vertical line: synthetic food-water yield 3.28.",
    outer = TRUE, side = 1, line = 0.4, cex = 0.75)
  mtext("Steady mean stocks assumed. These are feasible combinations, not measured moisture or validation.",
    outer = TRUE, side = 1, line = 1.5, cex = 0.75)
}

plot_short_kangaroo_response <- function(short) {
  old <- par(mfrow = c(2, 2), mar = c(4, 4.3, 2.3, 0.8),
    oma = c(4.5, 0, 2, 0), las = 1)
  on.exit(par(old))
  points <- short$observations
  primary <- "S1.0_R0_phi0.0"
  blue <- "#245A81"
  orange <- "#C4762B"
  green <- "#318268"
  panel <- function(title) {
    plot(NA, xlim = c(0, 600), ylim = c(0, 1000),
      xlab = "Combined vegetation (kg DM/ha)",
      ylab = "Stock-loss intake (g DM/animal/day)", main = title,
      cex.main = 0.9, cex.lab = 0.85, cex.axis = 0.8)
    segments(points$vegetation_kg_dm_ha - points$x_reading_allowance_kg_dm_ha,
      points$intake_g_dm_day,
      points$vegetation_kg_dm_ha + points$x_reading_allowance_kg_dm_ha,
      points$intake_g_dm_day, col = "#B4B4B4")
    segments(points$vegetation_kg_dm_ha,
      points$intake_g_dm_day - points$y_reading_allowance_g_dm_day,
      points$vegetation_kg_dm_ha,
      points$intake_g_dm_day + points$y_reading_allowance_g_dm_day,
      col = "#B4B4B4")
    graphics::points(points$vegetation_kg_dm_ha, points$intake_g_dm_day,
      pch = ifelse(points$yard == 1, 16, 1), cex = 0.8, col = "#555555")
  }
  locus <- function(id = primary, pairing = "midpoint", j = 0,
    col = blue, lty = 1, lwd = 1.6) {
    d <- short$response_transforms
    d <- d[d$scenario_id == id & d$x_pairing == pairing &
      d$j_offset_kg_dm_ha == j, ]
    lines(d$model_x_combined_vegetation_kg_dm_ha,
      d$smoothed_stock_loss_g_dm_animal_day, col = col, lty = lty, lwd = lwd)
  }
  panel("A. Declared primary comparison")
  locus()
  x <- seq(0, 600, length.out = 301)
  lines(x, 709 * (1 - exp(-x / 84)), col = orange, lty = 2, lwd = 1.6)
  lines(short$r200_control$V2_kg_dm_ha,
    short$r200_control$smoothed_stock_loss_g_dm_animal_day,
    col = "#8A597B", lty = 3, lwd = 1.6)
  legend("bottomright", c("Primary: R = J = 0, no plant flux",
    "Published fitted curve (in-sample)", "R = 200 threshold control"),
    col = c(blue, orange, "#8A597B"), lty = 1:3, lwd = 1.6,
    cex = 0.67, bty = "n")

  panel("B. Unknown biomass timestamp")
  pairings <- c("opening", "midpoint", "closing", "endpoint_weighted")
  colors <- c(orange, blue, green, "#8A597B")
  for (i in seq_along(pairings)) locus(pairing = pairings[[i]],
    col = colors[[i]], lty = i)
  legend("bottomright", c("Opening V0", "Midpoint V2 (primary)",
    "Closing V4", "Endpoint-weighted sensitivity"),
    col = colors, lty = 1:4, lwd = 1.6, cex = 0.67, bty = "n")

  panel("C. Search exposure, other settings primary")
  ids <- c("S0.5_R0_phi0.0", primary, "S2.0_R0_phi0.0")
  for (i in seq_along(ids)) locus(id = ids[[i]],
    col = colors[[i]], lty = i)
  legend("bottomright", c("0.5 x reference S", "Reference S = 84.4 m2/day",
    "2 x reference S"), col = colors[1:3], lty = 1:3, lwd = 1.6,
    cex = 0.67, bty = "n")

  panel("D. Separate observation and stock assumptions")
  locus()
  locus(id = "S1.0_R0_phi-2.5", col = orange, lty = 2)
  locus(id = "S1.0_R0_phi2.5", col = green, lty = 3)
  locus(j = 84, col = "#8A597B", lty = 4)
  locus(id = "S1.0_R20_phi0.0", col = "#555555", lty = 5)
  legend("bottomright", c("Primary", "Net plant loss 2.5 kg/ha/day",
    "Net plant gain 2.5 kg/ha/day", "Rejected offset J = 84 kg/ha",
    "Edible residual R = 20 kg/ha"), col = c(blue, orange, green, "#8A597B", "#555555"),
    lty = 1:5, lwd = 1.6, cex = 0.63, bty = "n")

  mtext("Short (1985): conditional acquisition and observation comparison",
    outer = TRUE, side = 3, line = 0.4, font = 2, cex = 1)
  mtext("Filled/open points: yards 1/2. Bars: digitization allowances only. Two yards; smoothed points are dependent.",
    outer = TRUE, side = 1, line = 0.4, cex = 0.68)
  mtext("Independent four-day response loci; lines are declared scenarios, not fitted trajectories. Full crossed grid is in the tables.",
    outer = TRUE, side = 1, line = 1.5, cex = 0.68)
  mtext("No growth correction is available in the original intake estimator. R, J and plant-flux sensitivities are not empirical bounds.",
    outer = TRUE, side = 1, line = 2.6, cex = 0.68)
}

write_red_kangaroo_benchmark_pdf <- function(budget, short, path) {
  if (!is.character(path) || length(path) != 1L || is.na(path) || !nzchar(path)) {
    stop("Supply one explicit PDF path.", call. = FALSE)
  }
  grDevices::pdf(path, width = 10, height = 8, useDingbats = FALSE,
    title = "Red-kangaroo budget and acquisition benchmark 065")
  on.exit(grDevices::dev.off())
  plot_red_kangaroo_water(budget)
  plot_short_kangaroo_response(short)
  invisible(path)
}
