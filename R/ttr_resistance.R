#' Shoot C resistance (skeleton)
#'
#' Resistance to carbon transport in shoot compartment.
#'
#' @param TR_C Numeric: temperature-related factor for C transport (unitless scalar).
#' @param Ms Numeric: shoot biomass mass [kg].
#' @param Q_SCP Numeric: phenomenological parameter (unitless or 1/[kg]) for C pathway.
#' @return numeric scalar (stub returns NA_real_).
#' @note Write-target: plant$rsC
calc_RsC <- function(TR_C, Ms, Q_SCP) {
  NA_real_
}

#' Root C resistance (skeleton)
#'
#' @inheritParams calc_RsC
#' @param Mr Numeric: root biomass mass [kg].
#' @note Write-target: plant$rrC
calc_RrC <- function(TR_C, Mr, Q_SCP) {
  NA_real_
}

#' Defence C resistance (skeleton)
#'
#' @inheritParams calc_RsC
#' @param Md Numeric: defence biomass mass [kg].
#' @note Write-target: plant$rdC
calc_RdC <- function(TR_C, Md, Q_SCP) {
  NA_real_
}

#' Shoot N resistance (skeleton)
#'
#' Resistance to nitrogen transport in shoot compartment.
#'
#' @param TR_N Numeric: temperature-related factor for N transport (unitless scalar).
#' @param Ms Numeric: shoot biomass mass [kg].
#' @param Q_SNP Numeric: phenomenological parameter (unitless or 1/[kg]) for N pathway.
#' @return numeric scalar (stub returns NA_real_).
#' @note Write-target: plant$rsN
calc_RsN <- function(TR_N, Ms, Q_SNP) {
  NA_real_
}

#' Root N resistance (skeleton)
#'
#' @inheritParams calc_RsN
#' @param Mr Numeric: root biomass mass [kg].
#' @note Write-target: plant$rrN
calc_RrN <- function(TR_N, Mr, Q_SNP) {
  NA_real_
}

#' Defence N resistance (skeleton)
#'
#' @inheritParams calc_RsN
#' @param Md Numeric: defence biomass mass [kg].
#' @note Write-target: plant$rdN
calc_RdN <- function(TR_N, Md, Q_SNP) {
  NA_real_
}

