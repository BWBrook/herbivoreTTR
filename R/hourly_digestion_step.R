#' Advance digestion by one hour
#'
#' Shifts gut content through hourly compartments, accumulates digestible
#' carbohydrate and protein energy, and accounts for metabolic water
#' production.
#'
#' @param herbivore Herbivore state list containing `MRT` and `digestion`
#'   vectors (`bleaf`, `bstem`, `bdef`, `dc_leaf`, `dc_stem`, `dp_leaf`,
#'   `dp_stem`, `dp_def`).
#' @return Updated `herbivore` list with intake and water fields increased.
#' @examples
#' # herbivore <- hourly_digestion_step(herbivore)
#' @export
hourly_digestion_step <- function(herbivore) {
  MRT <- herbivore$MRT
  
  # Incorporate digested nutrients from the final hour
  digested_carbs <- herbivore$digestion$dc_leaf[MRT] + herbivore$digestion$dc_stem[MRT]
  digested_proteins <- herbivore$digestion$dp_leaf[MRT] + 
                       herbivore$digestion$dp_stem[MRT] + 
                       herbivore$digestion$dp_def[MRT]

  herbivore$intake_digest_carbs_day <- herbivore$intake_digest_carbs_day + digested_carbs
  herbivore$intake_digest_protein_day <- herbivore$intake_digest_protein_day + digested_proteins

  herbivore$intake_NPE_day <- herbivore$intake_NPE_day + digested_carbs * CONSTANTS$CARB_TO_ENERGY * 1000
  herbivore$intake_PE_day  <- herbivore$intake_PE_day + digested_proteins * CONSTANTS$PROTEIN_TO_ENERGY * 1000
  
  # Calculate metabolic water
  herbivore$metabolic_water_day <- herbivore$metabolic_water_day +
    CONSTANTS$CARB_TO_MW * digested_carbs +
    CONSTANTS$PROTEIN_TO_MW * digested_proteins
  
  # Shift digestion vectors forward by one hour
  shift_digestion_vector <- function(vec) {
    c(0, vec[-MRT])
  }
  
  herbivore$digestion$bleaf   <- shift_digestion_vector(herbivore$digestion$bleaf)
  herbivore$digestion$bstem   <- shift_digestion_vector(herbivore$digestion$bstem)
  herbivore$digestion$bdef    <- shift_digestion_vector(herbivore$digestion$bdef)
  herbivore$digestion$dc_leaf <- shift_digestion_vector(herbivore$digestion$dc_leaf)
  herbivore$digestion$dc_stem <- shift_digestion_vector(herbivore$digestion$dc_stem)
  herbivore$digestion$dp_leaf <- shift_digestion_vector(herbivore$digestion$dp_leaf)
  herbivore$digestion$dp_stem <- shift_digestion_vector(herbivore$digestion$dp_stem)
  herbivore$digestion$dp_def  <- shift_digestion_vector(herbivore$digestion$dp_def)
  
  return(herbivore)
}
