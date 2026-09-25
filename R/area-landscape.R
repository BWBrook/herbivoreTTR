#' Create an area-based patch landscape
#'
#' Create a validated landscape of named forage-support patches in a
#' rectangular domain. Patch coordinates are in metres and patch areas are in
#' hectares. A patch area describes ecological feeding support; splitting a
#' support into coordinate-distinct rows is not assumed to be behaviourally
#' invariant. The domain may also contain non-forage matrix, so patch areas
#' need not sum to the domain area.
#'
#' @param patches A data frame containing exactly `patch_id`, `x_m`, `y_m`,
#'   `area_ha`, and `residual_kg_dm_ha`. Coordinates must be finite and lie in
#'   the half-open domain; patch areas must be positive; and residual forage
#'   densities must be finite and non-negative.
#' @param domain_width_m Finite, strictly positive domain width in metres.
#' @param domain_height_m Finite, strictly positive domain height in metres.
#' @param boundary One of the character values `"periodic"` or `"bounded"`.
#'   Periodic domains use minimal-image distances across each edge.
#'
#' @return A plain named list containing the canonical `patches` data frame,
#'   domain dimensions, and boundary condition.
#' @export
new_area_landscape <- function(
  patches,
  domain_width_m,
  domain_height_m,
  boundary
) {
  .validate_area_landscape_patch_frame(patches)
  .validate_positive_numeric_scalar(domain_width_m, "domain_width_m")
  .validate_positive_numeric_scalar(domain_height_m, "domain_height_m")
  .validate_area_landscape_boundary(boundary)

  width_m <- as.double(domain_width_m)
  height_m <- as.double(domain_height_m)
  patch_count <- nrow(patches)
  canonical_patches <- data.frame(
    patch_id = as.character(patches$patch_id),
    x_m = as.double(patches$x_m),
    y_m = as.double(patches$y_m),
    area_ha = as.double(patches$area_ha),
    residual_kg_dm_ha = as.double(patches$residual_kg_dm_ha),
    stringsAsFactors = FALSE
  )

  .validate_area_landscape_patch_values(
    canonical_patches,
    width_m,
    height_m
  )

  landscape <- list(
    patches = canonical_patches,
    domain_width_m = width_m,
    domain_height_m = height_m,
    boundary = as.character(boundary)
  )
  .validate_area_landscape(landscape)
  landscape
}

#' Calculate distance between two area-landscape patches
#'
#' Calculate the Euclidean distance between patch centres in metres. On a
#' periodic domain, the minimal image across each domain edge is used. On a
#' bounded domain, the direct coordinate difference is used.
#'
#' @param landscape An area landscape created by [new_area_landscape()].
#' @param from_patch_id One patch identifier present in `landscape`.
#' @param to_patch_id One patch identifier present in `landscape`.
#'
#' @return One finite or representable non-negative distance in metres.
#' @export
landscape_distance_m <- function(landscape, from_patch_id, to_patch_id) {
  .validate_area_landscape(landscape)
  .validate_patch_ids(from_patch_id, "from_patch_id", minimum_length = 1L)
  .validate_patch_ids(to_patch_id, "to_patch_id", minimum_length = 1L)
  if (length(from_patch_id) != 1L || length(to_patch_id) != 1L) {
    stop(
      "`from_patch_id` and `to_patch_id` must each contain one identifier.",
      call. = FALSE
    )
  }

  patch_ids <- landscape$patches$patch_id
  from_index <- match(from_patch_id, patch_ids)
  to_index <- match(to_patch_id, patch_ids)
  if (is.na(from_index) || is.na(to_index)) {
    stop(
      "Both patch identifiers must be present in `landscape`.",
      call. = FALSE
    )
  }

  delta_x_m <- abs(
    landscape$patches$x_m[[from_index]] -
      landscape$patches$x_m[[to_index]]
  )
  delta_y_m <- abs(
    landscape$patches$y_m[[from_index]] -
      landscape$patches$y_m[[to_index]]
  )
  if (identical(landscape$boundary, "periodic")) {
    delta_x_m <- min(delta_x_m, landscape$domain_width_m - delta_x_m)
    delta_y_m <- min(delta_y_m, landscape$domain_height_m - delta_y_m)
  }

  components_m <- c(delta_x_m, delta_y_m)
  largest_component_m <- max(components_m)
  if (largest_component_m == 0) {
    return(0)
  }
  largest_component_m *
    sqrt(sum((components_m / largest_component_m)^2))
}

#' Remove area-based forage for one focal animal
#'
#' Withdraw a requested dry-matter intake from one occupied patch. Biomass is
#' represented as a density in kilograms dry matter per hectare, so accessible
#' stock is `(biomass - residual) * area` in kilograms dry matter. The request
#' is capped by that stock, and no animal-density multiplier is applied.
#'
#' @param biomass_kg_dm_ha Finite, non-negative biomass density vector with one
#'   value per patch in `landscape`.
#' @param landscape An area landscape created by [new_area_landscape()].
#' @param patch_id One occupied patch identifier present in `landscape`.
#' @param requested_intake_kg_dm One finite, non-negative requested intake in
#'   kilograms dry matter for the focal animal during the interval.
#'
#' @return A plain list containing the closing biomass density vector `state`
#'   and `fluxes`. `fluxes$removal_kg_dm` is a vector of total kilograms dry
#'   matter removed from each patch. `fluxes$balance_residual_kg_dm` is the
#'   stock-change plus removal conservation residual; all other flux quantities
#'   are totals for the focal animal.
#' @export
remove_area_forage <- function(
  biomass_kg_dm_ha,
  landscape,
  patch_id,
  requested_intake_kg_dm
) {
  .validate_area_landscape(landscape)
  patch_count <- nrow(landscape$patches)
  if (
    !.is_numeric_vector(biomass_kg_dm_ha) ||
      length(biomass_kg_dm_ha) != patch_count ||
      any(!is.finite(as.double(biomass_kg_dm_ha))) ||
      any(as.double(biomass_kg_dm_ha) < 0)
  ) {
    stop(
      paste0(
        "`biomass_kg_dm_ha` must contain one finite, non-negative numeric ",
        "value per landscape patch."
      ),
      call. = FALSE
    )
  }
  .validate_patch_ids(patch_id, "patch_id", minimum_length = 1L)
  if (length(patch_id) != 1L) {
    stop("`patch_id` must contain exactly one identifier.", call. = FALSE)
  }
  .validate_nonnegative_numeric_scalar(
    requested_intake_kg_dm,
    "requested_intake_kg_dm"
  )

  biomass <- as.double(biomass_kg_dm_ha)
  requested <- as.double(requested_intake_kg_dm)
  patch_index <- match(patch_id, landscape$patches$patch_id)
  if (is.na(patch_index)) {
    stop("`patch_id` must be present in `landscape`.", call. = FALSE)
  }

  accessible_density_kg_dm_ha <- max(
    biomass[[patch_index]] -
      landscape$patches$residual_kg_dm_ha[[patch_index]],
    0
  )
  accessible_stock_kg_dm <-
    accessible_density_kg_dm_ha * landscape$patches$area_ha[[patch_index]]
  if (!is.finite(accessible_stock_kg_dm)) {
    stop(
      "Area-forage stock arithmetic must remain finite.",
      call. = FALSE
    )
  }
  realized <- min(requested, accessible_stock_kg_dm)

  removal_kg_dm <- numeric(patch_count)
  removal_kg_dm[[patch_index]] <- realized
  closing_biomass <- biomass
  if (
    is.finite(accessible_stock_kg_dm) &&
      realized >= accessible_stock_kg_dm
  ) {
    closing_biomass[[patch_index]] <- if (accessible_density_kg_dm_ha > 0) {
      landscape$patches$residual_kg_dm_ha[[patch_index]]
    } else {
      biomass[[patch_index]]
    }
  } else {
    closing_biomass[[patch_index]] <-
      biomass[[patch_index]] -
      realized / landscape$patches$area_ha[[patch_index]]
  }

  stock_change_kg_dm <- sum(
    (closing_biomass - biomass) * landscape$patches$area_ha
  )
  balance_residual_kg_dm <- stock_change_kg_dm + sum(removal_kg_dm)
  balance_tolerance_kg_dm <- 100 * .Machine$double.eps * max(
    1,
    abs(stock_change_kg_dm),
    abs(sum(removal_kg_dm)),
    abs(biomass[[patch_index]] * landscape$patches$area_ha[[patch_index]])
  )
  if (
    !is.finite(balance_residual_kg_dm) ||
      abs(balance_residual_kg_dm) > balance_tolerance_kg_dm
  ) {
    stop("The area-forage stock balance does not close.", call. = FALSE)
  }

  list(
    state = closing_biomass,
    fluxes = list(
      requested_intake_kg_dm = requested,
      realized_intake_kg_dm = realized,
      removal_kg_dm = removal_kg_dm,
      balance_residual_kg_dm = balance_residual_kg_dm
    )
  )
}

.validate_area_landscape <- function(landscape) {
  expected_names <- c(
    "patches",
    "domain_width_m",
    "domain_height_m",
    "boundary"
  )
  if (!.has_exact_named_fields(landscape, expected_names)) {
    stop(
      paste0(
        "`landscape` must contain only `patches`, `domain_width_m`, ",
        "`domain_height_m`, and `boundary`."
      ),
      call. = FALSE
    )
  }
  .validate_positive_numeric_scalar(
    landscape$domain_width_m,
    "landscape$domain_width_m"
  )
  .validate_positive_numeric_scalar(
    landscape$domain_height_m,
    "landscape$domain_height_m"
  )
  .validate_area_landscape_boundary(landscape$boundary)
  .validate_area_landscape_patch_frame(landscape$patches)
  .validate_area_landscape_patch_values(
    landscape$patches,
    as.double(landscape$domain_width_m),
    as.double(landscape$domain_height_m)
  )

  invisible(NULL)
}

.validate_area_landscape_patch_frame <- function(patches) {
  expected_names <- c(
    "patch_id",
    "x_m",
    "y_m",
    "area_ha",
    "residual_kg_dm_ha"
  )
  if (
    !is.data.frame(patches) ||
      !.has_exact_named_fields(patches, expected_names)
  ) {
    stop(
      paste0(
        "`patches` must be a data frame containing only `patch_id`, `x_m`, ",
        "`y_m`, `area_ha`, and `residual_kg_dm_ha`."
      ),
      call. = FALSE
    )
  }

  invisible(NULL)
}

.validate_area_landscape_patch_values <- function(
  patches,
  domain_width_m,
  domain_height_m
) {
  patch_count <- nrow(patches)
  .validate_patch_ids(patches$patch_id, "patches$patch_id", minimum_length = 1L)
  numeric_fields <- c("x_m", "y_m", "area_ha", "residual_kg_dm_ha")
  for (field_name in numeric_fields) {
    field <- patches[[field_name]]
    if (
      !.is_numeric_vector(field) ||
        length(field) != patch_count ||
        any(!is.finite(as.double(field)))
    ) {
      stop(
        sprintf("`patches$%s` must contain one finite numeric value per patch.", field_name),
        call. = FALSE
      )
    }
  }

  x_m <- as.double(patches$x_m)
  y_m <- as.double(patches$y_m)
  area_ha <- as.double(patches$area_ha)
  residual_kg_dm_ha <- as.double(patches$residual_kg_dm_ha)
  if (any(x_m < 0) || any(x_m >= domain_width_m)) {
    stop(
      "`patches$x_m` must be at least 0 and strictly below `domain_width_m`.",
      call. = FALSE
    )
  }
  if (any(y_m < 0) || any(y_m >= domain_height_m)) {
    stop(
      "`patches$y_m` must be at least 0 and strictly below `domain_height_m`.",
      call. = FALSE
    )
  }
  if (any(area_ha <= 0)) {
    stop("`patches$area_ha` must be strictly positive.", call. = FALSE)
  }
  if (any(residual_kg_dm_ha < 0)) {
    stop(
      "`patches$residual_kg_dm_ha` must be non-negative.",
      call. = FALSE
    )
  }

  domain_area_ha <- domain_width_m * domain_height_m / 10000
  total_patch_area_ha <- sum(area_ha)
  if (!is.finite(domain_area_ha) || !is.finite(total_patch_area_ha)) {
    stop("Landscape areas must remain finite.", call. = FALSE)
  }
  tolerance_ha <- 100 * .Machine$double.eps * max(
    1,
    abs(domain_area_ha),
    abs(total_patch_area_ha)
  )
  if (total_patch_area_ha > domain_area_ha + tolerance_ha) {
    stop(
      "Total `patches$area_ha` must not exceed the domain area in hectares.",
      call. = FALSE
    )
  }

  invisible(NULL)
}

.validate_area_landscape_boundary <- function(boundary) {
  valid <- is.character(boundary) &&
    !is.object(boundary) &&
    is.null(dim(boundary)) &&
    length(boundary) == 1L &&
    !is.na(boundary) &&
    boundary %in% c("periodic", "bounded")
  if (!valid) {
    stop(
      '`boundary` must be one character value: "periodic" or "bounded".',
      call. = FALSE
    )
  }

  invisible(NULL)
}
