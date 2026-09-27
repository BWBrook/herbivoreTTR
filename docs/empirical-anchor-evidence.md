# Empirical anchor evidence: arid kangaroos, sheep and northern cattle

Assessed 25 September 2026; full-text methods update 26 September and
observation-contract review 27 September 2026.

This is a bounded source assessment, not an empirical fit or a change to the
model contract. The immediate question is whether the nominated studies can
jointly constrain the feeding encounter coefficient `q` (m2 per feeding hour),
the residual density `R` (kg DM/ha), or the animal energy budget for one
coherent extant reference. The relevant observation process is therefore as
important as the reported number: daily paddock depletion, isotope-derived
whole-animal energy expenditure, inferred dry-matter requirement, feeding-time
scan, and GPS movement are different quantities.

## Decision

The red-kangaroo evidence is suitable as a coherent arid-rangeland anchor for
daily intake response, feeding time, diet, whole-animal expenditure, water and
space use. It does not directly estimate area searched per feeding hour. Short
(1985) materially challenges `R = 200 kg DM/ha` as a universal ungrazable
residual: its arid chenopod graze-down trial reports that red kangaroos, Merino
sheep and rabbits could reduce pasture to an ungrazable residual below 20 kg/ha.
That result does not prove `R = 20` for the current model. The full text
distinguishes the fine/sparse ungrazable pasture residue from physically
available but rejected standing material; the fitted intake response uses
combined pasture and shrub biomass. These are not the model's instantaneous
edible stock. It does rule out treating 200 kg DM/ha as an empirical consequence
of this red-kangaroo system.

Munn et al. (2009, 2010 and 2013) provide aligned red-kangaroo and Merino-sheep
evidence at Fowlers Gap. The 2010 enclosure study measured feeding time, diet
and digestibility, but estimated daily intake from field metabolic rate and
assumed diet energy density. The inspected repository-hosted author manuscript
contains erroneous original Table 5 values of `994` and `2,661 g DM/day`, but a
2011 publisher corrigendum replaces them with `518` and `1,572 g DM/day`. The
corrected publisher record, rather than the superseded table, is the relevant
source for any energy-derived intake anchor. The 2013 free-living study measured field
metabolic rate, water turnover and GPS movement, and again inferred dry-matter
requirement rather than observing pasture removal. Field metabolic rate already
includes locomotion and other activity during the isotope interval. It must be
used as a target for total modelled daily expenditure; using it as maintenance
and then adding modelled movement would double count activity.

Munn et al. (2016) is a western grey kangaroo study and cannot be substituted
for red-kangaroo parameters. Ash and McIvor (1998) is the accepted cattle case
for seasonal tall-grass response. It constrains vegetation response to season
and achieved utilization, not kangaroo acquisition or individual cattle
search.

## Source-by-source assessment

### Short (1985): daily small-pen graze-down response

**Source.** J. Short, *The functional response of kangaroos, sheep and rabbits
in an arid grazing system*, Journal of Applied Ecology 22:435-447,
[JSTOR](https://www.jstor.org/stable/2403176).

- Full text: Barry's supplied JSTOR PDF, checked by title, journal pages and
  checksum in [`references/README.md`](../references/README.md). Equations,
  design and residual definitions were checked on rendered pages 437, 440 and
  442. The earlier abstract-only access limitation is closed.
- Setting and design (pp. 436–438, 444): Kinchega National Park, western NSW,
  in *Maireana pyramidata* shrubland with annual forbs and grasses. The trial
  occurred in spring; a calendar year is not specified in the inspected
  description. Adult female red kangaroos averaged 25.6 kg after six months'
  holding/acclimation. Each of two replicate 20 × 20 m yards held two
  kangaroos, with shade, unrestricted water and a separate 5 × 20 m holding
  yard used during vegetation assessment. Merino wethers averaged 57.5 kg
  fleece-free, with the same two-per-yard design; rabbits averaged 1.25 kg,
  with eight per 10 × 10 m yard. Animal observations within a yard are not
  independent replicates of depletion.
- Observation process (pp. 436–437): starting vegetation was about 500–700
  kg DM/ha and was grazed down over roughly 10–12 days. Pasture biomass was
  estimated from 60 random 0.25-m2 quadrats per yard/occasion, with a correction
  for 20% visual underestimation. Shrub biomass was assessed separately with
  harvested reference shrubs. Kangaroo yards were assessed every two days,
  whereas sheep/rabbit yards were assessed daily. Intake is the loss of
  **combined pasture and shrub biomass** between observations, adjusted for
  trampling, divided by animals and elapsed time, and smoothed by running
  two-point averages. The trampling correction came from muzzled sheep and
  assumed equal effects for kangaroos; the paper calls it crude. Intake and
  biomass therefore share measurement error, and adjacent smoothed points
  are dependent. Intake was not measured directly on individuals. The methods
  describe no correction for plant growth during the spring trial. Positive
  production makes stock-loss intake underestimate ingestion, while other
  uncorrected stock losses can act oppositely. Its relative importance along
  the response curve depends on growth and measurement error; spring alone
  does not establish that the largest relative bias is at low density.
- Fitted response (Fig. 4, p. 440): `c(V) = 709 * (1 - exp(-V/84))` in
  g DM/animal/day, with `V` the combined vegetation density in kg DM/ha.
  Fig. 5 gives `62.3 * (1 - exp(-V/84))` in g DM/kg^0.75/day. The analogous
  sheep/rabbit asymptotes are 1,275/80 g/day and density scales 111/138 kg/ha.
  The text rounds kangaroo intake to 710 g/day. These are descriptive
  least-squares fits to the yard series, not independent individual feeding
  curves or a measured hourly encounter law. Short explicitly could not
  distinguish ramp, inverted-exponential, Michaelis–Menten and sigmoidal
  forms (p. 444); the evidence supports saturation without selecting its
  mechanism. The interspecific efficiency differences were not statistically
  testable (p. 441).
- Residual definition (p. 442): physically present but rejected material
  included green/flowering plants and unpalatable dead tussocks/stalks.
  Separately, normally eaten species left a fine/sparse residue below
  20 kg/ha. The latter is **not all remaining aboveground biomass**, a measured
  root/crown reserve, or a fitted offset in Fig. 4 (whose curve has no positive
  intercept threshold). It challenges 200 as a universal grazing residual
  but does not directly set the current model's `R`. In particular, `<20`
  is not a lower bound, and low terminal combined biomass does not identify
  a hard zero-intake threshold. A proposed `20–100 kg/ha` range for model `R`
  is a reviewer hypothesis, not a measured interval.
- Diet and recovery (pp. 440–444): bluebush use rose as pasture declined;
  its chemistry and palatability also varied seasonally. Rabbit-defoliated
  bluebush recovered within eight months, an observation about shrubs, not
  an annual-pasture recovery curve. Thus this experiment neither estimates a
  fixed plant relaxation rate nor identifies a universal regeneration pool.
- Longer-term context (p. 444): Short cites G. Robertson's personal
  communication for 3.5 years with pasture biomass 9–1,090 kg/ha, below
  180 kg/ha for 47% of the time, and annual rain at 112%, 90% and 50% of the
  average. This is a reported summary, not a retrieved time series. It concerns
  pasture, whereas Short's intake curve includes bluebush. Equating the
  statistic directly with time below the model's edible-stock threshold would
  discard that distinction and does not establish time without food.
- Interpretation for `q`: the response includes searching, harvesting, diet
  switching, satiation and unmeasured feeding duration in shared yards.
  `1/84` has units ha/kg DM, not m2/hour. Even a low-density slope conversion
  requires a matched edible-biomass definition and feeding duration, as well
  as allowance for depletion during the observation interval. Munn's 10.4-h
  value is from a different study and must not silently supply that missing
  denominator. The curve's zero-density slope converts to `q * hours =
  84.4 m2/day` only if biomass definitions match, no positive threshold
  intervenes and encounters bind without interval distortion. This is a
  conditional algebraic conversion, not an empirical estimate or bound on q.

### Munn et al. (2009): enclosed field metabolic rate and water turnover

**Source.** A. J. Munn et al., *Field metabolic rate and water turnover of red
kangaroos and sheep in an arid rangeland: an empirically derived
dry-sheep-equivalent for kangaroos*, Australian Journal of Zoology 57:23-28,
[DOI](https://doi.org/10.1071/ZO08063).

- Full text: the supplied CSIRO published PDF was checked against its methods
  and rendered Tables 1–2 (pp. 24–25). The earlier access limitation is closed.
- Setting (p. 24): mature, non-pregnant, non-lactating female red kangaroos
  and Merino sheep shared a 16-ha chenopod enclosure at Fowlers Gap, NSW,
  with shade and an unrestricted shared trough. The enclosure had been
  ungrazed for more than five years before acclimation. The trial ran
  2–10 April 2007 in mild autumn (mean daily temperature 21.7 C), after
  roughly three weeks' acclimation. Clipped standing biomass at the start
  of the metabolic trial was `44 +/- 8 g DM/m2`, based on 60 random 0.25-m2
  quadrats. It is not evidence of a long-established grazed equilibrium.
- Counts: this paper reports six kangaroos and five sheep in Methods and
  Tables 1–2. The concurrent 2010 paper reports seven introduced per species
  but six/five in its intake table. The reason for that discrepancy or any
  exclusions is not given. Keep analysis sample size distinct from a complete
  co-consumer census; do not assign total grazing pressure from `n = 6/5`
  without resolving or representing that uncertainty. There is only one
  enclosure, despite repeated animal-level measurements.
- Measurements (pp. 24–25): doubly labelled water, with about eight hours'
  equilibration and 6–8 days of free ranging between blood samples. A fixed
  `21.7 kJ/L CO2` converts carbon-dioxide production to FMR; no measured
  respiratory quotient is reported. Sheep values include methane corrections;
  kangaroo methane was assumed negligible. FMR averages were
  `4,872 +/- 364 kJ/day` for kangaroos and `16,664 +/- 1,314` for sheep.
  Mean initial/final masses were `23.6 +/- 0.8 kg` and `50.2 +/- 2.2 kg`
  (sheep fleece-free). Water turnover was `1.5 +/- 0.1 L/day` versus
  `11.5 +/- 0.8`; total body water was `66.7 +/- 0.5%` versus `66.2 +/- 2.1%`.
  At the kangaroo mean mass the reported fraction corresponds to about
  15.7 kg of body water, far below the synthetic 28-kg pool. Turnover is a
  whole-animal water flux, not a separately measured ordinary-loss component.
- Basal reference (Table 1): red-kangaroo BMR is predicted as
  `2,141 +/- 52 kJ/day`, using `200 * mass_kg^0.75`. It is not a field
  maintenance measurement. The 2016 paper instead prints a red-kangaroo
  relation `230 * mass_kg^0.72`; do not silently interchange those
  normalizations. FMR minus the 2009 mean BMR is 2,731 kJ/day, an unresolved
  nonbasal budget, not a measurement of locomotion alone.
- Intake status: the paper treats FMR as an index of food requirement. It did
  not measure daily dry-matter removal directly. The 2010 companion converts
  FMR to intake using measured apparent digestibility and assumed gross energy
  content. The original calculation was subsequently corrected by the 2011
  publisher corrigendum detailed below.
- Energy-scale interpretation: roughly 12–14 kg is an illustrative equivalent
  under the paper's body-mass scaling and this study's FMR:BMR, not a measured
  mass or a coherent calibration of the synthetic animal. Similarity between
  1.56 kg/day model ordinary loss and 1.5 L/day measured turnover cannot repair
  the mismatched water pool or identify all water inputs/losses.

### Munn et al. (2010): feeding biology in the 16-ha enclosure

**Source.** A. J. Munn, T. J. Dawson and S. R. McLeod, *Feeding biology of two
functionally different foregut-fermenting mammals, the marsupial red kangaroo
and the ruminant sheep: how physiological ecology can inform land management*,
Journal of Zoology 282:226-237,
[DOI](https://doi.org/10.1111/j.1469-7998.2010.00740.x). Numerical intake
interpretation also uses the publisher's 2011
[corrigendum](https://doi.org/10.1111/j.1469-7998.2011.00799.x).

- Version provenance: the locally inspected 38-page PDF is a University of
  Wollongong Research Online repository copy with a cover sheet followed by a
  line-numbered author-manuscript layout and tables at the end. It is not the
  publisher-formatted version-of-record PDF. Wiley's version-of-record landing
  page explicitly links the 2011 corrigendum; the version-of-record PDF itself
  was not inspected in this assessment.
- Setting and animals: Fowlers Gap (`31°05'S, 141°43'E`), 2-10 April 2007,
  mild autumn after 49.2 mm rain in the preceding six months. Seven mature,
  non-reproductive females of each species shared the 16-ha enclosure after
  two to three weeks' acclimation. The table analysis retained six kangaroos
  and five sheep for intake. Mean analysed masses were `23.6 +/- 0.8 kg` and
  `50.2 +/- 2.2 kg` (sheep fleece-free).
- Forage context: clipped standing biomass was `44 +/- 8 g DM/m2`, equivalent
  to about 440 kg DM/ha. The methods also report `44 +/- 30 g DM/m2` from the
  cover-height calculation. Visual inspection of author-manuscript Table 1
  rules out a text-extraction or shifted-column artefact: the row explicitly
  labelled `Biomass (g m^-2)` gives 15.4, 161.7, 33.3, 6.7 and 1.8 for the five detected
  plant groups, summing to `218.9 g DM/m2`; the next row gives their percentages
  as 7.0, 73.9, 15.2, 3.1 and 0.8, summing to 100%. Table 1 also reports 80.1%
  bare ground. Multiplying the plant-category sum by the vegetated fraction
  gives `218.9 * (1 - 0.801) = 43.6 g DM/m2`, essentially the two methods-text
  totals. This strongly suggests that the category biomasses are conditional on
  vegetated ground while 44 g/m2 is averaged across the whole enclosure. That
  is an inference: the table labels all values `g m^-2` and does not state the
  spatial support. The calibration limitation is therefore ambiguous support,
  not a demonstrated fivefold error. A biomass denominator must specify whether
  it is per vegetated square metre or per total enclosure square metre.
  Most grass was dry. Diets were selective and differed: kangaroo forestomachs
  contained about 64% round-leafed chenopods and 15% each grass and flat
  chenopods, whereas sheep had about 45% each flat- and round-leafed chenopods
  and 2% grass.
- Whole-enclosure depletion scale: at the reported 440-kg/ha mean stock,
  eight days of inferred intake by seven sheep at 1.572 kg/day and seven
  kangaroos at 0.518–0.576 kg/day represents about 1.66–1.71% of total
  standing DM. The kangaroo range spans the corrected published conversion
  and the separately assumed 0.9 ME:DE conversion below. This supports a
  simple nonlimiting-food budget benchmark, without modelling individual
  competitors. It is not the fraction removed from the selectively eaten
  stock and does not verify spatial food availability.
- Measurements: three complete 24-h behavioural observation days with scan
  sampling; vegetation cover, height and clipped biomass; forestomach diet;
  faecal-marker apparent DM digestibility; blood and urine chemistry. Both
  species spent `10.4 h/day` in food harvesting, defined to include searching,
  moving, cropping and chewing. The behavioural definitions explicitly include
  fast walking between food patches; water-directed travel is classified
  separately. A model must not subtract food-directed travel a second time
  when using the observed harvesting total. Apparent DM digestibility was
  `52.1 +/- 3.9%` for kangaroos and `59.1 +/- 2.4%` for sheep.
- Intake status: daily intake was inferred, not weighed or recovered from
  pasture depletion. In the inspected author manuscript, the original conversion
  is internally inconsistent.
  The methods assume `18 kJ/g DM` gross energy and equate energy digestibility
  with the measured DM digestibility, yielding stated digestible-energy
  densities of 9.4 and 10.6 kJ per gram of ingested DM. Dividing FMR by those
  densities gives `4,872 / 9.4 = 518` and `16,664 / 10.6 = 1,572 g DM/day`.
  Those are already the gross amounts of ingested diet required under the
  stated energy-density calculation. The inspected author-manuscript Table 5
  instead labels them
  `Digestible DM`, then divides them again by 0.521 and 0.591 to report
  `994 +/- 60` and `2,661 +/- 210 g DM/day` as gross intake. Equivalently,
  `4,872 / (18 * 0.521) = 520 g/day`; reaching 994 applies the 0.521 coefficient
  a second time. The sheep arithmetic behaves identically. The publisher's 2011
  corrigendum explicitly states that the original Table 5 gross-DMI values were
  incorrect and replaces them with `518 +/- 39` and `1,572 +/- 124 g DM/day`;
  it also replaces standard-animal values with 541 and 1,447 g/day and revises
  the intake-based kangaroo dry-sheep-equivalent from 0.42 to 0.37. Thus the
  arithmetic audit diagnoses the superseded author-manuscript table and agrees
  with the formal correction. The corrected values remain estimates conditional
  on FMR, 18 kJ/g gross energy, and equivalence of energy and DM digestibility;
  they are not measured intake or newly measured 'corrected intake'.
- `q` implication: even here, the denominator needed by the current encounter
  equation is not observed. Total standing biomass is not edible biomass, the
  animals selected plant groups strongly, and no hourly acquisition or swept
  area was measured. Combining the values produces only an assumption-dependent
  `q-R` curve, not separate estimates of `q` and `R`.

### Munn et al. (2013): free-living energy, water and space use

**Source.** A. J. Munn et al., *Energy, water and space use by free-living red
kangaroos Macropus rufus and domestic sheep Ovis aries in an Australian
rangeland*, Journal of Comparative Physiology B 183:843-858,
[DOI](https://doi.org/10.1007/s00360-013-0741-8).

- Setting and animals: Fowlers Gap in mild austral autumn, late February to
  early March 2008. Six wild mature, non-pregnant, non-lactating female red
  kangaroos (`26.7 +/- 1.7 kg` initial) and six South Australian-strain Merino
  sheep (`52.7 +/- 1.6 kg` initial) were measured in their free-living/home
  paddock context.
- Measurements and units: doubly labelled water FMR (`kJ/day`), total body
  water and water turnover (`L/day`, and allometrically scaled
  `mL kg^-0.8 day^-1`), forestomach/faecal-marker diet digestibility, diet
  composition, urine chemistry, and 10-min GPS positions. GPS provided
  relative travel distance and multi-method utilization areas, not area
  searched for food.
- Results relevant here: measured FMR was `4,788 +/- 421 kJ/day` for kangaroos
  and `16,922 +/- 1,390 kJ/day` for sheep. Estimated gross DM requirement was
  `557 +/- 55` versus `1,763 +/- 145 g/day`; those values were calculated from
  FMR and estimated diet energy, not observed intake. Mean GPS-derived daily
  travel was `3,646 +/- 301 m/day` versus `7,913 +/- 313 m/day`. Standardised
  25-kg kangaroo versus 45-kg sheep DM requirement was estimated as 546 versus
  1,574 g/day.
- Diet and condition: kangaroos ingested more grass and fewer flat-leafed
  chenopods than sheep; apparent DM digestibility was `51.6 +/- 1.8%` versus
  `58.1 +/- 1.3%`.
- Energy accounting: FMR is measured carbon-dioxide production over days of
  normal activity. It therefore includes the energy consequences of movement,
  feeding, thermoregulation and other activity during the interval. GPS distance
  can explain variation in FMR, but it is not an extra expenditure to add to
  the same measured FMR.
- `q` implication: distance travelled and utilization area do not supply a
  feeding-strip width, interception efficiency, revisit fraction or feeding-only
  path. They cannot be converted to m2 searched per feeding hour without new
  assumptions.

### Munn et al. (2016): western grey kangaroo, not red kangaroo

**Source.** A. J. Munn et al., *Field metabolic rate, movement distance, and
grazing pressures by western grey kangaroos (Macropus fuliginosus melanops) and
Merino sheep (Ovis aries) in semi-arid Australia*, Mammalian Biology 81:423-430,
[DOI](https://doi.org/10.1016/j.mambio.2016.04.001).

- Full text: Barry supplied the Elsevier published PDF. Methods, equations,
  Tables 1–3 and Fig. 1 were inspected (pp. 424–428), closing the access gap.
  This is the actual 2016 paper, not the different 2014 water-use paper
  previously exposed under its title on ResearchGate.
- Setting (p. 424): **western grey**, not red, kangaroos and Merino sheep in
  one shared 16-ha Fowlers Gap enclosure in February–March 2009, late summer.
  It had `33 +/- 13 g DM/m2` standing biomass and a shared unrestricted
  trough. Mean temperature was 28.2 C. Long-term annual rain is reported,
  but antecedent/trial rain does not supply an observable regrowth cue series.
  Eleven mature dry female western greys were captured; FMR was reported for
  seven (`25.2 +/- 1.3 kg`) and seven maiden Merino ewes (`55.2 +/- 1.5 kg`,
  fleece-free). The capture-to-analysis exclusions are not explained here.
- Energy (pp. 425–428): DLW integrates over multiple days. Sheep FMR was not adjusted
  for methane in this paper, unlike the 2009 calculation. All seven kangaroos
  averaged `8,599 +/- 1,301 kJ/day`, versus `22,799 +/- 2,471` for sheep.
  The abstract's `6,245 +/- 544` is a **selected subset of four** kangaroos
  whose FMR:BMR was at most three (Table 3). Western-grey BMR was unavailable,
  so that ratio used a red-kangaroo BMR relationship. The selected mean is not
  an unqualified species average.
- Intake and energy definitions (p. 425): marker-based apparent DM
  digestibility and assumed gross energy of 18 kJ/g give DE densities of
  `11.1 +/- 0.4` and `12.5 +/- 0.3 kJ/g DM`. The authors then assume a further
  **10% loss** for urine/methane, using ME densities of 10.0 and 11.2 kJ/g DM.
  These losses were not measured on these animals. DMI is FMR divided by that
  assumed ME, hence is not independent of FMR. This supplies a published
  conversion assumption, not a measured red-kangaroo ME:DE factor or evidence
  for a 10–20% range. Applying a 0.9 ratio to the 2010 red-kangaroo 9.4-kJ/g
  DE value would give 8.46-kJ/g ME and about 576 g/day, **a new conditional
  calculation**, not a further correction to the published 518-g/day result.
- Movement (pp. 425–428): GPS collars on six kangaroos/five sheep sampled at
  10-min intervals; distances are relative and omit between-fix paths.
  Mean daily distances were `2,410 +/- 373` and `4,291 +/- 44 m/day`.
  The FMR-distance comparison used five of each; the kangaroo association
  was one-tailed Spearman `r_s = .83, P = .03`. Fence-walking was observed
  without assigning it to individuals. Thus travel was associated with high
  FMR, not experimentally isolated as its cause. The printed sheep coefficient
  `r_s = -1.05` in Fig. 1 is impossible and must not be reused numerically.
- Applicability: retain the full-sample and selected-subset distinction and
  use this as a cross-species comparator. It cannot supply red-kangaroo
  parameters, a feeding-only search distance or independent intake validation.

### Ash and McIvor (1998): northern tall-grass cattle response

**Source.** A. J. Ash and J. G. McIvor, *How season of grazing and herbivore
selectivity influence monsoon tall-grass communities of northern Australia*,
Journal of Vegetation Science 9:123-132,
[DOI](https://doi.org/10.2307/3237230). The full supplied PDF was read from the
recovered Rebecca archive.

- Question and experimental unit: at Scott Creek Station, Northern Territory,
  two replicate blocks were split among early-wet, late-wet and dry-season
  grazing areas, then low, medium and high utilization plots. The plot/season
  treatment is the experimental unit; the 50-80 quadrats within a plot are
  subsamples. Two blocks sharply limit treatment-level replication.
- Animals and exposure: three weaner Brahman or Brahman-Shorthorn steers,
  initially averaging 135 kg, grazed each 2-8 ha plot for eight weeks. Sex is
  male by the term steer. The nominal 15/30/45% treatments achieved
  13/22/42% in early wet, 10/20/38% in late wet and 22/42/61% in dry season.
- Observation process: utilization was estimated as consumption divided by
  consumption plus residual standing biomass. Consumption itself was inferred
  from animal size and growth rate; standing biomass and composition came from
  BOTANAL quadrats, clipping calibration and exclosures. Dry-season apparent
  utilization may include detachment of senescent material.
- Plant response: early-wet medium/high use reduced next-season production to
  about 82/61% of low-use plots; late-wet high use to about 68%; dry-season use
  showed no comparable reduction. The follow-up is not a continuously observed
  recovery curve and the next year was dry.
- Applicability: this supports a qualitative seasonal plant-response test with
  observed treatment exposure and standing-material observation error. It does
  not measure individual intake, feeding time, search area, body reserve or
  physiological decline, and it cannot constrain kangaroo `q` or `R`.

## What is jointly constrained

1. **A daily red-kangaroo acquisition response exists and is saturating.**
   Short links interval-derived intake to declining combined vegetation
   biomass and reports a low fine/sparse pasture residue. It constrains
   saturation and daily scale conditional on its shared pens, diet and spring
   trial; it does not distinguish competing saturating equations.
2. **Matched feeding time and energetic demand are available for one coherent
   red-kangaroo context.** Munn (2009/2010) supplies about 10.4 feeding hours,
   whole-animal FMR and diet digestibility for mature dry females in the same
   enclosure. The 2011 corrigendum supplies the corrected gross-DM requirement,
   which remains an assumption-derived energy requirement rather than observed
   intake. Munn (2013) supplies a free-living replication of FMR plus movement
   and space use in a different mild-autumn year.
3. **`q` and `R` remain confounded.** At constant homogeneous density, a daily
   observation constrains only `q * feeding_hours * (B - R) / 10000`, and only
   when encounter is binding. In a depleting block this expression must be
   integrated along changing density and competing intake limits. None of
   these studies observes all four terms as edible forage,
   feeding-only area swept, realized intake and binding status. The studies can
   define plausible consistency checks or bounds after an explicit observation
   model, but they do not identify a unique `q`.
4. **`R = 200 kg DM/ha` is not supported as the red-kangaroo residual.** It is
   inconsistent with Short's reported `<20 kg/ha` ungrazable residual for that
   small-pen chenopod trial. A value near 200 could still represent a different
   construct, such as non-edible standing material or a conservative access
   threshold, but that interpretation needs independent evidence and should not
   be attributed to Short.
5. **Daily energy targets must close once.** FMR should be compared with total
   modelled expenditure over the day. Basal/maintenance, movement,
   thermoregulation, feeding and production costs may be decomposed inside the
   model, but their sum must be compared with FMR; FMR must not be entered as
   the baseline component and then augmented with those costs.
6. **The cattle case constrains a different process.** Ash and McIvor identify
   season- and utilization-dependent vegetation legacy effects in northern
   tall grass. It is useful beside the animal anchor, not part of a pooled
   animal calibration.

## Remaining evidence gap

The three requested full texts are now available and their methods have been
read. Remaining gaps are observational, not PDF access: edible versus total
vegetation, the time assigned to Short's density/intake pairs, within-interval
plant changes and trampling uncertainty, feeding-only effort, shared consumers,
and rain-conditioned growth. The 2010 Table 1 spatial-support ambiguity and
the 2009/2010 consumer-count discrepancy must be resolved or represented in
any depletion/acquisition calibration. They do not prevent a first daily
energy/water accounting benchmark with prescribed nonlimiting food. The
synthetic moisture yield also requires revision in any species fixture:
at the inferred intake it supplies more food water than the mean measured
turnover; the conditional balance is set out in the observation contract.
The superseded original Table 5 intake values must
be excluded in favour of the 2011 corrigendum; a DE-to-ME adjustment remains
a separate assumption. No source reviewed here measures the model's memory
or recovery clock. The multi-season pasture summary is a lead for a later
data-feasibility assessment; matched rain, forage and animal-condition records
have not been obtained. The [draft observation contracts](empirical-anchor-contracts.md)
specify these boundaries before any fit or new plant/consumer mechanism.
