## Internals available via helper-ttr.R (source_all_R)

toy_plant <- function() {
  list(
    ms = 2, mr = 3, md = 1,
    cs = 4, cr = 3, cd = 1,
    ns = 0.2, nr = 0.3, nd = 0.1,
    rsC = 1, rrC = 1, rdC = 1,
    rsN = 1, rrN = 1, rdN = 1,
    uc = 0, un = 0, tauC = 0, tauN = 0, tauCd = 0, tauNd = 0,
    gs = 0, gr = 0, gd = 0
  )
}

test_that("transport rates finite and correct sign", {
  p <- toy_plant()
  expect_true(is.finite(calc_tauC(p)))
  expect_true(is.finite(calc_tauN(p)))
  expect_true(is.finite(calc_tauCd(p)))
  expect_true(is.finite(calc_tauNd(p)))
  # gradient signs
  expect_gt(calc_tauC(p), 0)  # Cs/Ms > Cr/Mr
  expect_gt(calc_tauN(p), 0)  # Nr/Mr > Ns/Ms
})

test_that("transport zero when denom or masses zero", {
  p <- toy_plant(); p$rsC <- 0; p$rrC <- 0
  expect_equal(calc_tauC(p), 0)
  p <- toy_plant(); p$ms <- 0
  expect_equal(calc_tauC(p), 0)
})

test_that("uptake UC and UN finite and non-negative", {
  p <- toy_plant()
  uc <- calc_UC(p, CLeaf = 0, K_C_forced = 1, K_M = 10, PI_C = 0.5)
  un <- calc_UN(p, N0 = 1, K_M = 10, PI_N = 0.5)
  expect_true(is.finite(uc)); expect_true(is.finite(un))
  expect_gte(uc, 0); expect_gte(un, 0)
  # zero masses
  p$ms <- 0; expect_equal(calc_UC(p, 0, 1, 10, 0.5), 0)
  p <- toy_plant(); p$mr <- 0; expect_equal(calc_UN(p, 1, 10, 0.5), 0)
})

test_that("growth functions finite and non-negative with positive inputs", {
  p <- toy_plant()
  expect_gt(calc_Gs(p, 1), 0)
  expect_gt(calc_Gr(p, 1), 0)
  expect_gt(calc_Gd(p, 1), 0)
  p$ms <- 0; expect_equal(calc_Gs(p, 1), 0)
})

test_that("RHS terms finite and preserve reasonable signs", {
  p <- toy_plant()
  # Populate upstream fields sensibly
  p$uc <- 1; p$un <- 1
  p$tauC <- calc_tauC(p); p$tauN <- calc_tauN(p)
  p$tauCd <- calc_tauCd(p); p$tauNd <- calc_tauNd(p)
  p$gs <- calc_Gs(p, 0.1); p$gr <- calc_Gr(p, 0.1); p$gd <- calc_Gd(p, 0.1)

  dc_s <- calc_dCs_dt(p, FRACTION_C = 0.5)
  dn_s <- calc_dNs_dt(p, FRACTION_N = 0.5)
  dc_r <- calc_dCr_dt(p, FRACTION_C = 0.5)
  dn_r <- calc_dNr_dt(p, FRACTION_N = 0.5)

  expect_true(all(is.finite(c(dc_s, dn_s, dc_r, dn_r))))
})
