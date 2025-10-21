test_that("transport calculations remain within baseline performance", {
  skip_if_not(Sys.getenv("RUN_PERF_TESTS") == "1", message = "Set RUN_PERF_TESTS=1 to run performance checks.")
  plant <- list(
    ms = 2, mr = 3, md = 1,
    cs = 4, cr = 3, cd = 1,
    ns = 0.2, nr = 0.3, nd = 0.1,
    rsC = 1, rrC = 1, rdC = 1,
    rsN = 1, rrN = 1, rdN = 1,
    uc = 0, un = 0, tauC = 0, tauN = 0, tauCd = 0, tauNd = 0
  )
  runtime <- system.time(replicate(1000, {
    calc_tauC(plant)
    calc_tauN(plant)
    calc_tauCd(plant)
    calc_tauNd(plant)
  }))["elapsed"]
  expect_lt(runtime, 0.5)
})
