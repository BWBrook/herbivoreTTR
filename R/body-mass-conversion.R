#' Create body-mass conversion parameters
#'
#' Create the fixed parameters used to interpret body-energy reserve as labile
#' reserve tissue and total body mass. These parameters do not alter any model
#' transition.
#'
#' @param structural_body_mass_kg Finite, strictly positive numeric scalar
#'   giving fixed structural body mass in kilograms.
#' @param reserve_tissue_energy_density_kj_kg Finite, strictly positive numeric
#'   scalar giving the effective energy density of labile reserve tissue in
#'   kilojoules per kilogram.
#'
#' @return A plain named list containing `structural_body_mass_kg` and
#'   `reserve_tissue_energy_density_kj_kg`.
#' @export
new_body_mass_parameters <- function(
  structural_body_mass_kg,
  reserve_tissue_energy_density_kj_kg
) {
  .validate_body_mass_positive_scalar(
    structural_body_mass_kg,
    "structural_body_mass_kg"
  )
  .validate_body_mass_positive_scalar(
    reserve_tissue_energy_density_kj_kg,
    "reserve_tissue_energy_density_kj_kg"
  )

  list(
    structural_body_mass_kg =
      as.double(structural_body_mass_kg),
    reserve_tissue_energy_density_kj_kg =
      as.double(reserve_tissue_energy_density_kj_kg)
  )
}

#' Derive body mass from body-energy reserve
#'
#' Convert one or more body-energy reserves to labile reserve-tissue mass and
#' modeled total body mass. Unrepresented gut contents are not included. The
#' conversion is pure and has no feedback on model state or transitions.
#'
#' @param parameters A body-mass parameter record created by
#'   [new_body_mass_parameters()].
#' @param body_energy_reserve_kj A finite, non-negative numeric vector giving
#'   body-energy reserves in kilojoules.
#'
#' @return A base data frame containing body-energy reserve, derived reserve-
#'   tissue mass, and derived modeled total body mass.
#' @export
derive_body_mass_from_energy_reserve <- function(
  parameters,
  body_energy_reserve_kj
) {
  .validate_body_mass_parameters(parameters)
  .validate_body_energy_reserve_vector(body_energy_reserve_kj)

  body_energy_reserve_kj <- as.double(body_energy_reserve_kj)
  reserve_tissue_mass_kg <-
    body_energy_reserve_kj /
      as.double(parameters$reserve_tissue_energy_density_kj_kg)
  total_body_mass_kg <-
    as.double(parameters$structural_body_mass_kg) +
      reserve_tissue_mass_kg
  if (any(!is.finite(total_body_mass_kg))) {
    stop("Derived body masses must all be finite.", call. = FALSE)
  }

  data.frame(
    body_energy_reserve_kj = body_energy_reserve_kj,
    reserve_tissue_mass_kg = reserve_tissue_mass_kg,
    total_body_mass_kg = total_body_mass_kg
  )
}

.validate_body_mass_positive_scalar <- function(value, field_name) {
  if (
    !.is_numeric_vector(value) ||
      length(value) != 1L ||
      !is.finite(as.double(value)) ||
      as.double(value) <= 0
  ) {
    stop(
      sprintf(
        "`%s` must be one finite, strictly positive numeric value.",
        field_name
      ),
      call. = FALSE
    )
  }

  invisible(NULL)
}

.validate_body_mass_parameters <- function(parameters) {
  expected_names <- c(
    "structural_body_mass_kg",
    "reserve_tissue_energy_density_kj_kg"
  )
  if (!.has_exact_named_fields(parameters, expected_names)) {
    stop(
      paste0(
        "`parameters` must be a list record containing only ",
        "`structural_body_mass_kg` and ",
        "`reserve_tissue_energy_density_kj_kg`."
      ),
      call. = FALSE
    )
  }

  .validate_body_mass_positive_scalar(
    parameters$structural_body_mass_kg,
    "parameters$structural_body_mass_kg"
  )
  .validate_body_mass_positive_scalar(
    parameters$reserve_tissue_energy_density_kj_kg,
    "parameters$reserve_tissue_energy_density_kj_kg"
  )

  invisible(NULL)
}

.validate_body_energy_reserve_vector <- function(body_energy_reserve_kj) {
  if (
    !.is_numeric_vector(body_energy_reserve_kj) ||
      length(body_energy_reserve_kj) < 1L ||
      any(!is.finite(as.double(body_energy_reserve_kj))) ||
      any(as.double(body_energy_reserve_kj) < 0)
  ) {
    stop(
      paste0(
        "`body_energy_reserve_kj` must be a non-empty finite, ",
        "non-negative numeric vector."
      ),
      call. = FALSE
    )
  }

  invisible(NULL)
}
