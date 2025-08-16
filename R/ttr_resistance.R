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
  TR_C <- pmax(TR_C, 0)
  Q_SCP <- pmax(Q_SCP, 0)
  Ms_safe <- ifelse(Ms <= 0 | !is.finite(Ms), NA_real_, Ms)
  val <- TR_C / (Ms_safe ^ Q_SCP)
  # Large cap to avoid Inf/NaN while preserving limiting behavior
  LARGE <- 1e12
  val[!is.finite(val)] <- LARGE
  val <- pmax(val, 0)
  pmin(val, LARGE)
}

#' Root C resistance (skeleton)
#'
#' @inheritParams calc_RsC
#' @param Mr Numeric: root biomass mass [kg].
#' @note Write-target: plant$rrC
calc_RrC <- function(TR_C, Mr, Q_SCP) {
  TR_C <- pmax(TR_C, 0)
  Q_SCP <- pmax(Q_SCP, 0)
  Mr_safe <- ifelse(Mr <= 0 | !is.finite(Mr), NA_real_, Mr)
  val <- TR_C / (Mr_safe ^ Q_SCP)
  LARGE <- 1e12
  val[!is.finite(val)] <- LARGE
  val <- pmax(val, 0)
  pmin(val, LARGE)
}

#' Defence C resistance (skeleton)
#'
#' @inheritParams calc_RsC
#' @param Md Numeric: defence biomass mass [kg].
#' @note Write-target: plant$rdC
calc_RdC <- function(TR_C, Md, Q_SCP) {
  TR_C <- pmax(TR_C, 0)
  Q_SCP <- pmax(Q_SCP, 0)
  Md_safe <- ifelse(Md <= 0 | !is.finite(Md), NA_real_, Md)
  val <- TR_C / (Md_safe ^ Q_SCP)
  LARGE <- 1e12
  val[!is.finite(val)] <- LARGE
  val <- pmax(val, 0)
  pmin(val, LARGE)
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
  TR_N <- pmax(TR_N, 0)
  Q_SNP <- pmax(Q_SNP, 0)
  Ms_safe <- ifelse(Ms <= 0 | !is.finite(Ms), NA_real_, Ms)
  val <- TR_N / (Ms_safe ^ Q_SNP)
  LARGE <- 1e12
  val[!is.finite(val)] <- LARGE
  val <- pmax(val, 0)
  pmin(val, LARGE)
}

#' Root N resistance (skeleton)
#'
#' @inheritParams calc_RsN
#' @param Mr Numeric: root biomass mass [kg].
#' @note Write-target: plant$rrN
calc_RrN <- function(TR_N, Mr, Q_SNP) {
  TR_N <- pmax(TR_N, 0)
  Q_SNP <- pmax(Q_SNP, 0)
  Mr_safe <- ifelse(Mr <= 0 | !is.finite(Mr), NA_real_, Mr)
  val <- TR_N / (Mr_safe ^ Q_SNP)
  LARGE <- 1e12
  val[!is.finite(val)] <- LARGE
  val <- pmax(val, 0)
  pmin(val, LARGE)
}

#' Defence N resistance (skeleton)
#'
#' @inheritParams calc_RsN
#' @param Md Numeric: defence biomass mass [kg].
#' @note Write-target: plant$rdN
calc_RdN <- function(TR_N, Md, Q_SNP) {
  TR_N <- pmax(TR_N, 0)
  Q_SNP <- pmax(Q_SNP, 0)
  Md_safe <- ifelse(Md <= 0 | !is.finite(Md), NA_real_, Md)
  val <- TR_N / (Md_safe ^ Q_SNP)
  LARGE <- 1e12
  val[!is.finite(val)] <- LARGE
  val <- pmax(val, 0)
  pmin(val, LARGE)
}
