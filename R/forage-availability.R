#' Derive accessible forage biomass
#'
#' Apply a fixed residual threshold to standing edible forage biomass. Biomass
#' at or below the threshold is unavailable for acquisition; biomass above it
#' is accessible one-for-one. This pure transformation does not consume forage
#' or define an acquisition rate.
#'
#' @param forage_biomass_kg_dm_ha A non-empty finite, non-negative numeric
#'   vector giving standing forage biomass in kilograms dry matter per hectare.
#' @param residual_unavailable_forage_threshold_kg_dm_ha One finite,
#'   non-negative numeric value giving the standing-biomass threshold below
#'   which forage is unavailable for acquisition.
#'
#' @return A base data frame containing standing forage biomass, the residual
#'   threshold, and derived accessible forage biomass, all in kilograms dry
#'   matter per hectare.
#' @export
derive_accessible_forage_biomass <- function(
  forage_biomass_kg_dm_ha,
  residual_unavailable_forage_threshold_kg_dm_ha
) {
  .validate_forage_biomass_vector(forage_biomass_kg_dm_ha)
  .validate_nonnegative_numeric_scalar(
    residual_unavailable_forage_threshold_kg_dm_ha,
    "residual_unavailable_forage_threshold_kg_dm_ha"
  )

  forage_biomass_kg_dm_ha <- as.double(forage_biomass_kg_dm_ha)
  residual_threshold_kg_dm_ha <- as.double(
    residual_unavailable_forage_threshold_kg_dm_ha
  )

  data.frame(
    forage_biomass_kg_dm_ha = forage_biomass_kg_dm_ha,
    residual_unavailable_forage_threshold_kg_dm_ha = rep.int(
      residual_threshold_kg_dm_ha,
      length(forage_biomass_kg_dm_ha)
    ),
    accessible_forage_biomass_kg_dm_ha = pmax(
      0,
      forage_biomass_kg_dm_ha - residual_threshold_kg_dm_ha
    )
  )
}

.validate_forage_biomass_vector <- function(forage_biomass_kg_dm_ha) {
  if (
    !.is_numeric_vector(forage_biomass_kg_dm_ha) ||
      length(forage_biomass_kg_dm_ha) < 1L ||
      any(!is.finite(as.double(forage_biomass_kg_dm_ha))) ||
      any(as.double(forage_biomass_kg_dm_ha) < 0)
  ) {
    stop(
      paste0(
        "`forage_biomass_kg_dm_ha` must be a non-empty finite, ",
        "non-negative numeric vector."
      ),
      call. = FALSE
    )
  }

  invisible(NULL)
}
