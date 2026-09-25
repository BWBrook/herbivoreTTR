#' Calculate cell areas overlapped by a rectangular feeding footprint
#'
#' Calculate the geometric intersection area between each independent cell and
#' one rectangular feeding footprint. Coordinates are in metres, and the
#' returned areas are in square metres. Rectangles are treated as ordinary
#' bounded Cartesian rectangles; no periodic wrapping is applied.
#'
#' @param cells A data frame containing exactly `xmin_m`, `xmax_m`, `ymin_m`,
#'   and `ymax_m`. Every bound must be finite and non-negative, with each
#'   maximum strictly greater than its corresponding minimum. Cell rectangles
#'   must not overlap one another over a positive area.
#' @param footprint A named numeric vector containing exactly `xmin_m`,
#'   `xmax_m`, `ymin_m`, and `ymax_m`, with the same rectangle constraints as
#'   `cells`.
#'
#' @return A numeric vector of one overlap area in square metres per row of
#'   `cells`.
#' @export
rectangle_overlap_m2 <- function(cells, footprint) {
  .validate_feeding_cells(cells)
  .validate_feeding_rectangle(footprint, "`footprint`")

  cell_count <- nrow(cells)
  if (cell_count > 1L) {
    .reject_overlapping_feeding_cells(cells)
  }

  xmin_m <- as.double(cells$xmin_m)
  xmax_m <- as.double(cells$xmax_m)
  ymin_m <- as.double(cells$ymin_m)
  ymax_m <- as.double(cells$ymax_m)
  footprint_xmin_m <- as.double(footprint[["xmin_m"]])
  footprint_xmax_m <- as.double(footprint[["xmax_m"]])
  footprint_ymin_m <- as.double(footprint[["ymin_m"]])
  footprint_ymax_m <- as.double(footprint[["ymax_m"]])

  overlap_width_m <- pmax(
    0,
    pmin(xmax_m, footprint_xmax_m) -
      pmax(xmin_m, footprint_xmin_m)
  )
  overlap_height_m <- pmax(
    0,
    pmin(ymax_m, footprint_ymax_m) -
      pmax(ymin_m, footprint_ymin_m)
  )
  overlap_area_m2 <- overlap_width_m * overlap_height_m
  if (any(!is.finite(overlap_area_m2))) {
    stop("Rectangle overlap areas must remain finite.", call. = FALSE)
  }

  as.double(overlap_area_m2)
}

#' Advance grazing over a fixed rectangular feeding footprint
#'
#' Calculate one pure grazing transition over a fixed footprint. Accessible
#' mass is sampled uniformly within the footprint at the declared search rate,
#' with replacement across hours. Intake is capped by the encountered
#' accessible mass, and removals are distributed across cells in proportion to
#' their accessible mass. Removal is spread over each whole cell, so the
#' residual density remains unavailable and cannot be removed.
#'
#' @param biomass_kg_dm_ha Finite, non-negative opening biomass density, in
#'   kilograms dry matter per hectare, with one value per cell.
#' @param cell_area_ha Finite, strictly positive cell area in hectares, with
#'   one value per biomass value.
#' @param overlap_area_m2 Finite, non-negative footprint overlap area in square
#'   metres, with one value per cell and no value greater than its cell area in
#'   square metres.
#' @param requested_intake_kg_dm One finite, non-negative requested intake in
#'   kilograms dry matter.
#' @param search_area_m2_h One finite, strictly positive search area rate in
#'   square metres per hour.
#' @param feeding_duration_h One finite duration in hours in `[0, 1]`.
#' @param residual_kg_dm_ha One finite, non-negative unavailable residual
#'   biomass density in kilograms dry matter per hectare.
#'
#' @return A plain named list containing numeric-vector `state` (closing
#' biomass density) and `fluxes`, with `realized_intake_kg_dm`,
#' `encounter_ceiling_kg_dm`, and `balance_residual_kg_dm` scalar quantities,
#' and numeric vectors `accessible_mass_kg_dm` and `removal_kg_dm`.
#' @export
step_footprint_grazing <- function(
  biomass_kg_dm_ha,
  cell_area_ha,
  overlap_area_m2,
  requested_intake_kg_dm,
  search_area_m2_h,
  feeding_duration_h,
  residual_kg_dm_ha = 200
) {
  .validate_footprint_grazing_inputs(
    biomass_kg_dm_ha,
    cell_area_ha,
    overlap_area_m2,
    requested_intake_kg_dm,
    search_area_m2_h,
    feeding_duration_h,
    residual_kg_dm_ha
  )

  biomass <- as.double(biomass_kg_dm_ha)
  cell_area_ha <- as.double(cell_area_ha)
  overlap_area_m2 <- as.double(overlap_area_m2)
  requested <- as.double(requested_intake_kg_dm)
  search_rate <- as.double(search_area_m2_h)
  duration_h <- as.double(feeding_duration_h)
  residual <- as.double(residual_kg_dm_ha)

  accessible_density_kg_dm_ha <- pmax(biomass - residual, 0)
  accessible_area_ha <- overlap_area_m2 / 10000
  accessible_mass_kg_dm <-
    accessible_density_kg_dm_ha * accessible_area_ha
  if (any(!is.finite(accessible_mass_kg_dm))) {
    stop("Accessible forage mass arithmetic must remain finite.", call. = FALSE)
  }

  footprint_area_m2 <- sum(overlap_area_m2)
  if (!is.finite(footprint_area_m2)) {
    stop("The footprint overlap area must remain finite.", call. = FALSE)
  }
  searched_area_m2 <- search_rate * duration_h
  if (!is.finite(searched_area_m2)) {
    stop("Searched area arithmetic must remain finite.", call. = FALSE)
  }
  searched_fraction <- if (footprint_area_m2 == 0) {
    0
  } else {
    min(searched_area_m2 / footprint_area_m2, 1)
  }
  accessible_total_kg_dm <- sum(accessible_mass_kg_dm)
  if (!is.finite(accessible_total_kg_dm)) {
    stop("Accessible forage mass total must remain finite.", call. = FALSE)
  }
  encounter_ceiling_kg_dm <- searched_fraction * accessible_total_kg_dm
  if (!is.finite(encounter_ceiling_kg_dm)) {
    stop("Encounter-ceiling arithmetic must remain finite.", call. = FALSE)
  }
  realized_intake_kg_dm <- min(requested, encounter_ceiling_kg_dm)

  removal_kg_dm <- numeric(length(biomass))
  if (accessible_total_kg_dm > 0 && realized_intake_kg_dm > 0) {
    removal_kg_dm <- realized_intake_kg_dm *
      (accessible_mass_kg_dm / accessible_total_kg_dm)
  }
  if (any(!is.finite(removal_kg_dm))) {
    stop("Grazing removal arithmetic must remain finite.", call. = FALSE)
  }

  closing_biomass_kg_dm_ha <- biomass - removal_kg_dm / cell_area_ha
  if (any(!is.finite(closing_biomass_kg_dm_ha))) {
    stop("Closing biomass arithmetic must remain finite.", call. = FALSE)
  }

  opening_mass_kg_dm <- sum(biomass * cell_area_ha)
  stock_change_kg_dm <- sum(
    (closing_biomass_kg_dm_ha - biomass) * cell_area_ha
  )
  balance_residual_kg_dm <- stock_change_kg_dm + realized_intake_kg_dm
  if (
    !is.finite(opening_mass_kg_dm) ||
      !is.finite(stock_change_kg_dm) ||
      !is.finite(balance_residual_kg_dm)
  ) {
    stop("Grazing stock arithmetic must remain finite.", call. = FALSE)
  }
  balance_tolerance_kg_dm <- 100 * .Machine$double.eps * max(
    1,
    abs(opening_mass_kg_dm),
    abs(realized_intake_kg_dm)
  )
  if (abs(balance_residual_kg_dm) > balance_tolerance_kg_dm) {
    stop("The footprint-grazing stock balance does not close.", call. = FALSE)
  }

  list(
    state = closing_biomass_kg_dm_ha,
    fluxes = list(
      realized_intake_kg_dm = realized_intake_kg_dm,
      encounter_ceiling_kg_dm = encounter_ceiling_kg_dm,
      accessible_mass_kg_dm = accessible_mass_kg_dm,
      removal_kg_dm = removal_kg_dm,
      balance_residual_kg_dm = balance_residual_kg_dm
    )
  )
}

.validate_feeding_cells <- function(cells) {
  expected_names <- c("xmin_m", "xmax_m", "ymin_m", "ymax_m")
  if (
    !is.data.frame(cells) ||
      length(names(cells)) != length(expected_names) ||
      anyDuplicated(names(cells)) ||
      !setequal(names(cells), expected_names)
  ) {
    stop(
      paste0(
        "`cells` must be a data frame containing only `xmin_m`, `xmax_m`, ",
        "`ymin_m`, and `ymax_m`."
      ),
      call. = FALSE
    )
  }

  for (field_name in expected_names) {
    field <- cells[[field_name]]
    if (
      !.is_numeric_vector(field) ||
        any(!is.finite(as.double(field))) ||
        any(as.double(field) < 0)
    ) {
      stop(
        sprintf("`cells$%s` must contain finite, non-negative numeric bounds.", field_name),
        call. = FALSE
      )
    }
  }

  xmin_m <- as.double(cells$xmin_m)
  xmax_m <- as.double(cells$xmax_m)
  ymin_m <- as.double(cells$ymin_m)
  ymax_m <- as.double(cells$ymax_m)
  if (any(!is.finite(xmax_m - xmin_m)) || any(!is.finite(ymax_m - ymin_m))) {
    stop("Cell rectangle widths and heights must remain finite.", call. = FALSE)
  }
  if (any(xmax_m <= xmin_m) || any(ymax_m <= ymin_m)) {
    stop(
      "Each cell rectangle must have maxima strictly greater than minima.",
      call. = FALSE
    )
  }

  invisible(NULL)
}

.validate_feeding_rectangle <- function(rectangle, field_name) {
  expected_names <- c("xmin_m", "xmax_m", "ymin_m", "ymax_m")
  if (
    !.is_numeric_vector(rectangle) ||
      length(rectangle) != length(expected_names) ||
      is.null(names(rectangle)) ||
      anyDuplicated(names(rectangle)) ||
      !setequal(names(rectangle), expected_names)
  ) {
    stop(
      sprintf(
        "%s must be a named numeric vector containing exactly `xmin_m`, `xmax_m`, `ymin_m`, and `ymax_m`.",
        field_name
      ),
      call. = FALSE
    )
  }

  values <- as.double(rectangle[expected_names])
  if (any(!is.finite(values)) || any(values < 0)) {
    stop(
      sprintf("%s must contain finite, non-negative rectangle bounds.", field_name),
      call. = FALSE
    )
  }
  if (
    !is.finite(values[[2L]] - values[[1L]]) ||
      !is.finite(values[[4L]] - values[[3L]]) ||
      values[[2L]] <= values[[1L]] ||
      values[[4L]] <= values[[3L]]
  ) {
    stop(
      sprintf("Each %s rectangle maximum must be strictly greater than its minimum.", field_name),
      call. = FALSE
    )
  }

  invisible(NULL)
}

.reject_overlapping_feeding_cells <- function(cells) {
  xmin_m <- as.double(cells$xmin_m)
  xmax_m <- as.double(cells$xmax_m)
  ymin_m <- as.double(cells$ymin_m)
  ymax_m <- as.double(cells$ymax_m)
  cell_count <- nrow(cells)
  for (i in seq_len(cell_count - 1L)) {
    for (j in seq.int(i + 1L, cell_count)) {
      overlap_width_m <- min(xmax_m[[i]], xmax_m[[j]]) -
        max(xmin_m[[i]], xmin_m[[j]])
      overlap_height_m <- min(ymax_m[[i]], ymax_m[[j]]) -
        max(ymin_m[[i]], ymin_m[[j]])
      if (overlap_width_m > 0 && overlap_height_m > 0) {
        stop(
          "`cells` rectangles must not overlap over a positive area.",
          call. = FALSE
        )
      }
    }
  }

  invisible(NULL)
}

.validate_footprint_grazing_inputs <- function(
  biomass_kg_dm_ha,
  cell_area_ha,
  overlap_area_m2,
  requested_intake_kg_dm,
  search_area_m2_h,
  feeding_duration_h,
  residual_kg_dm_ha
) {
  if (
    !.is_numeric_vector(biomass_kg_dm_ha) ||
      length(biomass_kg_dm_ha) < 1L ||
      any(!is.finite(as.double(biomass_kg_dm_ha))) ||
      any(as.double(biomass_kg_dm_ha) < 0)
  ) {
    stop(
      "`biomass_kg_dm_ha` must contain a non-empty, finite, non-negative numeric vector.",
      call. = FALSE
    )
  }
  cell_count <- length(biomass_kg_dm_ha)
  if (
    !.is_numeric_vector(cell_area_ha) ||
      length(cell_area_ha) != cell_count ||
      any(!is.finite(as.double(cell_area_ha))) ||
      any(as.double(cell_area_ha) <= 0)
  ) {
    stop(
      "`cell_area_ha` must contain one finite, strictly positive value per biomass value.",
      call. = FALSE
    )
  }
  cell_area_m2 <- as.double(cell_area_ha) * 10000
  if (any(!is.finite(cell_area_m2))) {
    stop("`cell_area_ha` square-metre conversion must remain finite.", call. = FALSE)
  }
  if (
    !.is_numeric_vector(overlap_area_m2) ||
      length(overlap_area_m2) != cell_count ||
      any(!is.finite(as.double(overlap_area_m2))) ||
      any(as.double(overlap_area_m2) < 0) ||
      any(as.double(overlap_area_m2) > cell_area_m2)
  ) {
    stop(
      "`overlap_area_m2` must contain one finite, non-negative value per biomass value and not exceed its cell area in square metres.",
      call. = FALSE
    )
  }
  .validate_nonnegative_numeric_scalar(
    requested_intake_kg_dm,
    "requested_intake_kg_dm"
  )
  .validate_positive_numeric_scalar(search_area_m2_h, "search_area_m2_h")
  if (
    !.is_numeric_vector(feeding_duration_h) ||
      length(feeding_duration_h) != 1L ||
      !is.finite(as.double(feeding_duration_h)) ||
      as.double(feeding_duration_h) < 0 ||
      as.double(feeding_duration_h) > 1
  ) {
    stop(
      "`feeding_duration_h` must be one finite numeric value in [0, 1].",
      call. = FALSE
    )
  }
  .validate_nonnegative_numeric_scalar(residual_kg_dm_ha, "residual_kg_dm_ha")

  invisible(NULL)
}
