#' herbivoreTTR: Transparent functional herbivore energetics
#'
#' The package provides a small functional model that converts prescribed
#' dry-matter ingestion through one fixed dry-matter-basis metabolizable-energy
#' density into an existing one-pool gut-energy buffer. The converted energy is
#' an accounting equivalent, not an explicit digestion calculation. A fixed
#' fraction of opening gut energy is released each hour into a body-energy
#' ledger with fixed maintenance and explicit prescribed routine-activity
#' expenditure. A reference-cycle runner can advance only the gut under repeated
#' identical daily forcing until a numerical period-24 cycle is reached, reset
#' body energy once, and record two carried measurement days. The model separates
#' validated dynamic state, fixed parameters, prescribed inputs, pure conversions
#' and transitions, and recorded history. A separate homogeneous forage stock
#' has an isolated turnover reference and a minimum density-scaled non-spatial
#' coupling to realized animal intake.
#'
#' @keywords internal
"_PACKAGE"
