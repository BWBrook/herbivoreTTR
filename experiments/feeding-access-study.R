# Frozen 062 main design. Run directly for compact printed results; no writes.
source("experiments/feeding-access-validation.R")

feeding_access_supply_bound <- function(system,initial_state,growth_multiplier) {
  stopifnot(is.numeric(growth_multiplier),length(growth_multiplier)>0,
    all(is.finite(growth_multiplier)),all(growth_multiplier>=0 & growth_multiplier<=1))
  gamma_mass_h <- vapply(growth_multiplier,function(f) {
    a <- system$growth_rate_h*f-system$senescence_rate_h
    b <- system$growth_rate_h*f/system$K
    vertex <- if (f==0) rep(200,length(b)) else pmin(system$K,pmax(200,a/(2*b)))
    sum(pmax(a*vertex-b*vertex^2,0)*system$cell_area_ha)
  },numeric(1))
  initial_accessible <- sum(pmax(initial_state$biomass_kg_dm_ha-200,0)*system$cell_area_ha)
  supply <- initial_accessible+cumsum(gamma_mass_h)
  feeding <- rep(system$fixture$feeding_open,length.out=length(growth_multiplier))
  physiological_max <- cumsum(.025*feeding)
  expenditure <- cumsum(100+50*feeding)
  initial_energy <- initial_state$body$body_energy_reserve_kj+
    initial_state$gut$gut_available_energy_kj
  data.frame(hour=seq_along(growth_multiplier),harvest_upper_kg_dm=supply,
    intake_upper_kg_dm=pmin(supply,physiological_max),
    combined_energy_upper_kj=initial_energy+10000*pmin(supply,physiological_max)-expenditure)
}

feeding_access_summary <- function(run,system,profile) {
  d <- run$daily[run$daily$complete_day,,drop=FALSE]
  at <- function(day,variable) {
    z <- d[d$day==day,variable]
    if (length(z)) z else NA_real_
  }
  final <- d[d$day>200,,drop=FALSE]
  slope <- if (nrow(final)==28) unname(coef(lm(body_energy_kj~day,final))[2]) else NA_real_
  f <- rep(1,168*24)
  if (profile=="short_pulse") f[seq_len(7*24)] <- .6
  if (profile=="pulse") f[seq_len(28*24)] <- .6
  if (profile=="sustained") f[seq_len(84*24)] <- .6
  bound <- feeding_access_supply_bound(system,run$initial_branch_state,f)
  observed <- run$hourly[run$hourly$day>=61,,drop=FALSE]
  assert_that(all(observed$body_energy_kj+observed$gut_energy_kj <=
    bound$combined_energy_upper_kj[seq_len(nrow(observed))]+1e-7),
    "observed combined energy respects analytic upper bound")
  cumulative_intake <- cumsum(observed$intake_kg_dm)
  assert_that(all(cumulative_intake <= bound$harvest_upper_kg_dm[seq_len(nrow(observed))]+1e-9) &&
    all(cumulative_intake <= bound$intake_upper_kg_dm[seq_len(nrow(observed))]+1e-9),
    "observed cumulative intake respects plant and physiological bounds")
  screen <- which(bound$combined_energy_upper_kj<0)
  data.frame(completed=is.na(run$stop_day),stop_day=run$stop_day,stop_hour=run$stop_hour,
    energy_day60_kj=at(60,"body_energy_kj"),energy_day88_kj=at(88,"body_energy_kj"),
    energy_day144_kj=at(144,"body_energy_kj"),energy_day228_kj=at(228,"body_energy_kj"),
    recovery_energy_difference_kj=at(228,"body_energy_kj")-at(60,"body_energy_kj"),
    final_slope_kj_day=slope,
    accessible_day60_kg_dm=at(60,"accessible_mass_kg_dm"),
    accessible_day144_kg_dm=at(144,"accessible_mass_kg_dm"),
    accessible_day228_kg_dm=at(228,"accessible_mass_kg_dm"),
    min_water_kg=min(run$hourly$body_water_kg),
    forage_travel_to88_h=sum(d$forage_travel_h[d$day>=61 & d$day<=88]),
    forage_travel_to144_h=if (144 %in% d$day) sum(d$forage_travel_h[d$day>=61 & d$day<=144]) else NA_real_,
    min_supply_energy_upper_kj=min(bound$combined_energy_upper_kj),
    first_certified_impossible_day=if(length(screen)) 60+(screen[1]-1)%/%24+1 else NA_integer_,
    max_plant_balance_kg_dm=max(abs(run$hourly$plant_balance_kg_dm)),
    max_energy_balance_kj=max(abs(run$hourly$energy_balance_kj)),
    max_water_balance_kg=max(abs(run$hourly$water_balance_kg)))
}

run_feeding_access_study <- function(cores=1L,progress=interactive()) {
  validate_feeding_access()
  bound_system <- new_feeding_access_system()
  bound_state <- new_feeding_access_state(bound_system)
  healthy_bound <- feeding_access_supply_bound(bound_system,bound_state,rep(1,24))
  reduced_bound <- feeding_access_supply_bound(bound_system,bound_state,rep(.6,24))
  zero_bound <- feeding_access_supply_bound(bound_system,bound_state,rep(0,365*24))
  assert_that(near(tail(healthy_bound$harvest_upper_kg_dm,1),64+.48) &&
    near(tail(reduced_bound$harvest_upper_kg_dm,1),64+.03072) &&
    tail(zero_bound$combined_energy_upper_kj,1)<0,
    "analytical supply coefficients and negative impossibility control")
  configurations <- c("continuous","clustered","fragmented")
  primary <- expand.grid(configuration=configurations,profile=c("none","pulse","sustained"),
    water=c("near","far"),stringsAsFactors=FALSE)
  primary$policy <- "experienced"
  primary$access <- "physical"
  primary$subdivisions <- 1L
  primary$boundary <- "bounded"
  primary$role <- "primary"
  diagnostics <- expand.grid(configuration=configurations,profile="sustained",
    water=c("near","far"),policy=c("informed","cyclic"),stringsAsFactors=FALSE)
  diagnostics$access <- "physical"
  diagnostics$subdivisions <- 1L
  diagnostics$boundary <- "bounded"
  diagnostics$role <- "policy"
  controls <- expand.grid(configuration=configurations,profile="sustained",water=c("near","far"),
    access=c("zero_transit","pooled_search","pooled_stock"),stringsAsFactors=FALSE)
  controls$policy <- "experienced"
  controls$subdivisions <- 1L
  controls$boundary <- "bounded"
  controls$role <- "access"
  refinement <- expand.grid(configuration=c("continuous","fragmented"),profile="sustained",
    water="far",subdivisions=c(2L,4L),stringsAsFactors=FALSE)
  refinement$policy <- "experienced"
  refinement$access <- "physical"
  refinement$boundary <- "bounded"
  refinement$role <- "resolution"
  periodic <- primary[primary$configuration=="fragmented" & primary$profile=="sustained" &
    primary$water=="far",]
  periodic$boundary <- "periodic"
  periodic$role <- "boundary"
  design <- rbind(primary,diagnostics[,names(primary)],controls[,names(primary)],
    refinement[,names(primary)],periodic)
  design$id <- sprintf("access_%02d",seq_len(nrow(design)))
  keys <- paste(design$configuration,design$subdivisions,design$boundary,sep="_")
  systems <- baselines <- setNames(vector("list",length(unique(keys))),unique(keys))
  for (key in names(systems)) {
    i <- match(key,keys)
    systems[[key]] <- new_feeding_access_system(design$configuration[i],design$subdivisions[i],
      design$boundary[i])
    baselines[[key]] <- run_feeding_access(systems[[key]],final_day=60)
    stopifnot(is.na(baselines[[key]]$stop_day))
  }
  run_one <- function(i) {
    d <- design[i,]
    if (progress) message("Running ",d$id," ",d$configuration," ",d$profile," ",d$water," ",d$policy," ",d$access)
    system <- systems[[keys[i]]]
    baseline <- baselines[[keys[i]]]
    r <- run_feeding_access(system,d$profile,d$water,d$policy,d$access,baseline=baseline)
    stopifnot(identical(r$initial_branch_state,baseline$final_state),
      identical(r$hourly[r$hourly$day<=60,],baseline$hourly))
    list(run=r,summary=feeding_access_summary(r,system,d$profile))
  }
  results <- parallel::mclapply(seq_len(nrow(design)),run_one,mc.cores=cores,mc.preschedule=FALSE)
  if (any(vapply(results,inherits,logical(1),"try-error"))) stop("A study worker failed.")
  runs <- setNames(lapply(results,`[[`,"run"),design$id)
  summary <- cbind(design,do.call(rbind,lapply(results,`[[`,"summary")))
  assert_that(all(summary$max_plant_balance_kg_dm<1e-9),"study plant closure")
  assert_that(all(summary$max_energy_balance_kj<1e-8),"study energy closure")
  assert_that(all(summary$max_water_balance_kg<1e-10),"study water closure")
  for (i in which(design$role=="resolution")) {
    j <- which(design$role=="primary" & design$configuration==design$configuration[i] &
      design$profile=="sustained" & design$water=="far")
    a <- runs[[i]]; b <- runs[[j]]
    assert_that(identical(a$stop_day,b$stop_day) && identical(a$stop_hour,b$stop_hour),
      "equivalent-grid domain exit")
    for(v in c("body_energy_kj","forage_mass_kg_dm","intake_kg_dm","forage_travel_h","water_travel_h"))
      assert_that(near(a$daily[[v]],b$daily[[v]],1e-8),paste("equivalent-grid",v))
  }
  list(design=design,systems=systems,baselines=baselines,runs=runs,summary=summary)
}

if(sys.nframe()==0L) {
  result <- run_feeding_access_study(cores=1L,progress=TRUE)
  print(result$summary,row.names=FALSE,digits=5)
}
