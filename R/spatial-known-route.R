#' Create a known-route patch landscape
#'
#' Create a minimal fixed landscape containing named patches, one static
#' non-depleting forage-acquisition capacity and metabolizable-energy density
#' per patch, and directed one-hour routes known to the focal animal. Route
#' choice and multi-hour transit are outside this record.
#'
#' @param patch_id Character vector of at least two unique, non-empty patch
#'   identifiers.
#' @param forage_acquisition_ceiling_kg_dm_h Finite, non-negative numeric
#'   vector giving one static acquisition ceiling per patch, in kilograms dry
#'   matter per hour.
#' @param route_origin_patch_id Character vector giving the origin patch for
#'   each directed route.
#' @param route_destination_patch_id Character vector giving the destination
#'   patch for each directed route.
#' @param incremental_movement_expenditure_kj Finite, non-negative numeric
#'   vector giving the energy expenditure added by each one-hour route, in
#'   kilojoules.
#' @param metabolizable_energy_density_kj_kg_dm Finite, strictly positive
#'   numeric vector giving one metabolizable-energy density per patch, in
#'   kilojoules per kilogram dry matter.
#'
#' @return A plain named list containing `patches` and `routes` data frames.
#' @export
new_known_route_landscape <- function(
  patch_id,
  forage_acquisition_ceiling_kg_dm_h,
  route_origin_patch_id,
  route_destination_patch_id,
  incremental_movement_expenditure_kj,
  metabolizable_energy_density_kj_kg_dm
) {
  .validate_patch_ids(patch_id, "patch_id", minimum_length = 2L)
  .validate_patch_acquisition_capacities(
    forage_acquisition_ceiling_kg_dm_h,
    length(patch_id),
    "forage_acquisition_ceiling_kg_dm_h"
  )
  .validate_known_route_fields(
    patch_id,
    route_origin_patch_id,
    route_destination_patch_id,
    incremental_movement_expenditure_kj
  )
  .validate_patch_energy_densities(
    metabolizable_energy_density_kj_kg_dm,
    length(patch_id),
    "metabolizable_energy_density_kj_kg_dm"
  )

  list(
    patches = data.frame(
      patch_id = as.character(patch_id),
      forage_acquisition_ceiling_kg_dm_h = as.double(
        forage_acquisition_ceiling_kg_dm_h
      ),
      metabolizable_energy_density_kj_kg_dm = as.double(
        metabolizable_energy_density_kj_kg_dm
      ),
      stringsAsFactors = FALSE
    ),
    routes = data.frame(
      origin_patch_id = as.character(route_origin_patch_id),
      destination_patch_id = as.character(route_destination_patch_id),
      travel_duration_h = rep(1, length(route_origin_patch_id)),
      incremental_movement_expenditure_kj = as.double(
        incremental_movement_expenditure_kj
      ),
      stringsAsFactors = FALSE
    )
  )
}

#' Create an animal patch-location state
#'
#' Create the explicit patch occupied by the focal animal at one hourly
#' boundary. Membership in a particular landscape is checked by the movement
#' transition.
#'
#' @param patch_id One non-empty character patch identifier.
#'
#' @return A plain named list containing `patch_id`.
#' @export
new_patch_location_state <- function(patch_id) {
  .validate_patch_ids(patch_id, "patch_id", minimum_length = 1L)
  if (length(patch_id) != 1L) {
    stop("`patch_id` must contain exactly one patch identifier.", call. = FALSE)
  }

  list(patch_id = as.character(patch_id))
}

#' Move along one known route
#'
#' Move the focal animal from its opening patch to a declared destination over
#' one hourly interval. Feeding is suspended during travel, and the route's
#' incremental movement expenditure is reported separately from maintenance
#' and ordinary routine activity.
#'
#' @param state A patch-location state created by
#'   [new_patch_location_state()].
#' @param landscape A known-route landscape created by
#'   [new_known_route_landscape()].
#' @param destination_patch_id One destination patch identifier.
#'
#' @return A plain list containing the closing location `state` and movement
#'   `fluxes`.
#' @export
step_known_route_movement <- function(
  state,
  landscape,
  destination_patch_id
) {
  .validate_patch_location_state(state)
  .validate_known_route_landscape(landscape)
  .validate_patch_ids(
    destination_patch_id,
    "destination_patch_id",
    minimum_length = 1L
  )
  if (length(destination_patch_id) != 1L) {
    stop(
      "`destination_patch_id` must contain exactly one patch identifier.",
      call. = FALSE
    )
  }

  current_patch_id <- state$patch_id
  patch_ids <- landscape$patches$patch_id
  if (!(current_patch_id %in% patch_ids)) {
    stop("The opening location is not present in `landscape`.", call. = FALSE)
  }
  if (!(destination_patch_id %in% patch_ids)) {
    stop("The destination is not present in `landscape`.", call. = FALSE)
  }

  route_index <- which(
    landscape$routes$origin_patch_id == current_patch_id &
      landscape$routes$destination_patch_id == destination_patch_id
  )
  if (length(route_index) != 1L) {
    stop(
      "No unique known route connects the opening location to the destination.",
      call. = FALSE
    )
  }

  travel_duration_h <- landscape$routes$travel_duration_h[[route_index]]
  incremental_expenditure_kj <-
    landscape$routes$incremental_movement_expenditure_kj[[route_index]]

  list(
    state = list(patch_id = as.character(destination_patch_id)),
    fluxes = list(
      origin_patch_id = current_patch_id,
      destination_patch_id = as.character(destination_patch_id),
      travel_duration_h = travel_duration_h,
      feeding_suspended_during_travel = TRUE,
      incremental_movement_expenditure_kj_h =
        incremental_expenditure_kj / travel_duration_h,
      incremental_movement_expenditure_kj = incremental_expenditure_kj
    )
  )
}

.validate_known_route_landscape <- function(landscape) {
  if (!.has_exact_named_fields(landscape, c("patches", "routes"))) {
    stop(
      "`landscape` must contain only `patches` and `routes`.",
      call. = FALSE
    )
  }
  if (
    !is.data.frame(landscape$patches) ||
      !.has_exact_named_fields(
        landscape$patches,
        c(
          "patch_id",
          "forage_acquisition_ceiling_kg_dm_h",
          "metabolizable_energy_density_kj_kg_dm"
        )
      )
  ) {
    stop(
      paste0(
        "`landscape$patches` must contain only `patch_id`, ",
        "`forage_acquisition_ceiling_kg_dm_h`, and ",
        "`metabolizable_energy_density_kj_kg_dm`."
      ),
      call. = FALSE
    )
  }

  route_names <- c(
    "origin_patch_id",
    "destination_patch_id",
    "travel_duration_h",
    "incremental_movement_expenditure_kj"
  )
  if (
    !is.data.frame(landscape$routes) ||
      !.has_exact_named_fields(landscape$routes, route_names)
  ) {
    stop(
      paste0(
        "`landscape$routes` must contain only `origin_patch_id`, ",
        "`destination_patch_id`, `travel_duration_h`, and ",
        "`incremental_movement_expenditure_kj`."
      ),
      call. = FALSE
    )
  }

  .validate_patch_ids(
    landscape$patches$patch_id,
    "landscape$patches$patch_id",
    minimum_length = 2L
  )
  .validate_patch_acquisition_capacities(
    landscape$patches$forage_acquisition_ceiling_kg_dm_h,
    nrow(landscape$patches),
    "landscape$patches$forage_acquisition_ceiling_kg_dm_h"
  )
  .validate_patch_energy_densities(
    landscape$patches$metabolizable_energy_density_kj_kg_dm,
    nrow(landscape$patches),
    "landscape$patches$metabolizable_energy_density_kj_kg_dm"
  )
  .validate_known_route_fields(
    landscape$patches$patch_id,
    landscape$routes$origin_patch_id,
    landscape$routes$destination_patch_id,
    landscape$routes$incremental_movement_expenditure_kj
  )
  if (
    !.is_numeric_vector(landscape$routes$travel_duration_h) ||
      length(landscape$routes$travel_duration_h) != nrow(landscape$routes) ||
      any(as.double(landscape$routes$travel_duration_h) != 1)
  ) {
    stop("All current known routes must have duration `1 h`.", call. = FALSE)
  }

  invisible(NULL)
}

.validate_patch_acquisition_capacities <- function(
  value,
  patch_count,
  field_name
) {
  if (
    !.is_numeric_vector(value) ||
      length(value) != patch_count ||
      any(!is.finite(as.double(value))) ||
      any(as.double(value) < 0)
  ) {
    stop(
      sprintf(
        "`%s` must contain one finite, non-negative numeric value per patch.",
        field_name
      ),
      call. = FALSE
    )
  }

  invisible(NULL)
}

.validate_patch_energy_densities <- function(
  value,
  patch_count,
  field_name
) {
  if (
    !.is_numeric_vector(value) ||
      length(value) != patch_count ||
      any(!is.finite(as.double(value))) ||
      any(as.double(value) <= 0)
  ) {
    stop(
      sprintf(
        paste0(
          "`%s` must contain one finite, strictly positive numeric value ",
          "per patch."
        ),
        field_name
      ),
      call. = FALSE
    )
  }

  invisible(NULL)
}

.validate_patch_location_state <- function(state) {
  if (!.has_exact_named_fields(state, "patch_id")) {
    stop("`state` must contain only `patch_id`.", call. = FALSE)
  }
  .validate_patch_ids(state$patch_id, "state$patch_id", minimum_length = 1L)
  if (length(state$patch_id) != 1L) {
    stop("`state$patch_id` must contain exactly one identifier.", call. = FALSE)
  }

  invisible(NULL)
}

.validate_known_route_fields <- function(
  patch_id,
  route_origin_patch_id,
  route_destination_patch_id,
  incremental_movement_expenditure_kj
) {
  .validate_patch_ids(
    route_origin_patch_id,
    "route_origin_patch_id",
    minimum_length = 1L,
    require_unique = FALSE
  )
  .validate_patch_ids(
    route_destination_patch_id,
    "route_destination_patch_id",
    minimum_length = 1L,
    require_unique = FALSE
  )
  route_count <- length(route_origin_patch_id)
  if (length(route_destination_patch_id) != route_count) {
    stop("Known-route fields must have equal lengths.", call. = FALSE)
  }
  if (
    !.is_numeric_vector(incremental_movement_expenditure_kj) ||
      length(incremental_movement_expenditure_kj) != route_count ||
      any(!is.finite(as.double(incremental_movement_expenditure_kj))) ||
      any(as.double(incremental_movement_expenditure_kj) < 0)
  ) {
    stop(
      paste0(
        "`incremental_movement_expenditure_kj` must contain one finite, ",
        "non-negative numeric value per route."
      ),
      call. = FALSE
    )
  }

  endpoints <- c(route_origin_patch_id, route_destination_patch_id)
  if (!all(endpoints %in% patch_id)) {
    stop("Every route endpoint must be present in `patch_id`.", call. = FALSE)
  }
  if (any(route_origin_patch_id == route_destination_patch_id)) {
    stop("Known routes must connect two different patches.", call. = FALSE)
  }
  route_key <- paste(route_origin_patch_id, route_destination_patch_id, sep = "\r")
  if (anyDuplicated(route_key)) {
    stop("Directed known routes must be unique.", call. = FALSE)
  }

  invisible(NULL)
}

.validate_patch_ids <- function(
  value,
  field_name,
  minimum_length,
  require_unique = TRUE
) {
  valid <- is.character(value) &&
    !is.object(value) &&
    is.null(dim(value)) &&
    length(value) >= minimum_length &&
    !anyNA(value) &&
    all(nzchar(trimws(value)))
  if (!valid || (require_unique && anyDuplicated(value))) {
    uniqueness <- if (require_unique) " unique," else ""
    stop(
      sprintf(
        "`%s` must contain at least %d%s non-empty character value(s).",
        field_name,
        minimum_length,
        uniqueness
      ),
      call. = FALSE
    )
  }

  invisible(NULL)
}
