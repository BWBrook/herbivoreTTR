# Rebecca archive: lineage and empirical constraints

Assessment by Astra, 25 September 2026. This records source interpretation and
recommendations, not a new model contract or an accepted calibration. No legacy
model was executed, and no current model equation or parameter was changed.

## Main conclusion

The archive recovers the empirical cases and explains their original purpose.
Bec's manuscript principally asks how herbivores change vegetation, traits,
nutrient cycling and fuels. The current rebuild principally asks when habitat
and forage permit an animal to maintain physiological state. Those questions
can eventually meet, but they require different observations.

The four proposed field studies supply vegetation responses to herbivory. None
directly estimates our effective search area per feeding hour, remembered
returns, body-energy reserve, or chronic physiological decline. Their strongest
immediate use is to identify ecological patterns a coupled model ought to be
able to confront. Fitting the search coefficient to their vegetation endpoints
would mix animal acquisition, abundance and use with plant growth and other
losses.

My recommendation is to retain Ash and McIvor as the first qualitative seasonal
plant-response case, Borer as the strongest supplied numerical dataset once its
treatment mapping is recovered, Waldram as a spatial mechanism challenge, and
Wigley as a later ecosystem-carbon case. Ground acquisition and physiology through a
separate, matched set of measurements before interpreting the synthetic 063
thresholds biologically.

## Sources and provenance

Barry supplied `wsl-laptop:/mnt/c/Temp/large_herbivore_model_MS.zip`. A read-only
transfer to the Mac mini matched the remote SHA-256:

```text
7,630,636 bytes
dff53cfa518b5ecac11a50aba998ec89e63552aa2458a01e8c21d5d6a367eca4
```

The ZIP, its extracted source tree, inventory and derived reading material are
outside the active repository at
`/Users/bwbrook/input/herbivoreTTR-rebecca-2026-09-25/`.
Paths below beginning `Paper/`, `Model code/`, `herbivoreTTR/` or
`potential_validation_datasets/` are relative to the extracted
`large_herbivore_model_MS/` directory. The archive contains 72 entries including
directories: four field-study PDFs, five accompanying Borer CSVs, four manuscript
DOCX files, C++ sources and example output, conversion notes, and the Julia side
experiment. The latter is abandoned, as Barry explicitly clarified on
25 September; it is not a mainline development stage.

The other source is `/Users/bwbrook/git/herbivoreTTR-legacy`, clean at
`e013f1427ae4a9e4a85f9f1f8cd057386335598a`, tagged
`legacy-final-2026-07-16`. Neither source tree was modified. Original summaries
are recorded here; legacy code and manuscript prose were not imported.

## What the lineage establishes

1. **Bec's C++ model and 2023 manuscript.** Barry describes the original C++
   choice as alignment with aDGVM. The supplied C++ README instead describes
   the delivered plant coupling as a modified Thornley transport-resistance
   model used as a vegetation stand-in. These are compatible stages of the
   same history, not evidence that this archive contains an operational aDGVM
   integration. The manuscript describes grazer, browser and mixed-feeder
   types, allometric acquisition and demand, protein/non-protein targets,
   individual plants and plant water. Described capabilities need to be checked
   against code and the author's explicit unfinished-work notes. The supplied
   mainline instantiates one fixed 2,180 kg grazer and 100 grass plants in a
   periodic 100 × 100 m plot, with minute-scale foraging over 12 hours and
   daily plant updates. The manuscript's soil-water buckets, population modes
   and demographic ideas are not all implemented there.
2. **Bec already identified important unfinished science.** Her dated
   `Paper/Notes on model.docx` flags unrealistic initial digestion vectors,
   unimplemented excretion, growth/reproduction/death and population scaling,
   and uncertainty about the modified plant carbon/nitrogen pools and defence
   allocation. Concerns she attributes to Steve Higgins are second-hand notes,
   not an independent failure demonstration or a verdict on the later TTR.PGM
   release. The suggestion to return to aDGVM2 is a proposal.
3. **Conversion material and the abandoned Julia experiment.** These preserve
   attempts to translate, simplify and diagnose the system. Suggestions in
   AI conversations are hypotheses and implementation plans. Their presence,
   and the presence of example output files, do not establish successful
   validation or a trustworthy succession of model versions.
4. **The archived R lineage.** Git records C++ added in `ae67502` and removed
   during the same-day R port in `30c366d` on 16 August 2025. Subsequent work
   expanded the code, scenarios and verification machinery. The late
   observational benchmark explicitly used synthetic `site_alpha` fixtures;
   its error metrics are not field validation. The TTR.PGM adapter explicitly
   returned a non-run status, including when the package was detected.
5. **The July 2026 diagnosis and rebuild.** Legacy Goals 002/003 found persistent
   energy deficit in one semi-synthetic 50 kg animal, even with daily-restored,
   non-binding food. The Goal 004 record reports that adding twelve digestion
   ticks changed the isolated daily closure from deficit to surplus. It did
   not establish a stable alternative trajectory or uniquely identify the
   biological cause: a 12-hour feeding loop and daily physiological accounting
   were entangled. Its raw bundles were deliberately excluded from the archive.
   This supports the clean rebuild's explicit 24-hour clock, carried stocks,
   units and isolated controls; it is not evidence to restore the old queues.

Useful legacy evidence pointers are `ARCHIVED.md`,
`docs/contracts/observational_data_contract_v1.md` (synthetic examples),
`R/ttr_pgm_benchmark.R` (non-running adapter), the dated July logs under
`docs/log/`, and `docs/goals/rebuild-001-legacy-freeze-clean-repository-foundation/`.
The legacy `docs/reference/c++_model_logic.md` conflicts with later checked R
behaviour on clock length, gut initialization and unwired outputs. Treat it as
a question index, not a specification. This does not imply that the present
rebuild retains those defects.

The supplied C++ snapshot is also unsuitable as a numerical reference. Static
inspection found uninitialized transport-flux members used in reached plant
derivatives, integer division in an intended fractional constant, and a
temperature cycle using the product-inhibition constant in place of pi
(`Model code/src/daily_per_plant.cpp`, lines 59–68, 453, 504;
`Model code/inc/constants.hpp`, lines 72–74;
`Model code/src/init_aDGVM.cpp`, lines 213–226).
Separately, `Model code/data/output/plants.txt` has negative substrate values
on day 0 and its first non-finite record on day 361, plant 57, before the
configured five-year herbivory onset. No revision, seed or build record binds
those outputs to the source, so this is not a causal reconstruction of the
failure. There is no scientific reason to demand trajectory parity with it.

## What each empirical case can constrain

| Study | Supplied observations and experimental support | Useful model question | Main limit for the current animal model |
| --- | --- | --- | --- |
| Ash & McIvor (1998), Scott Creek, northern Australia | Seasonal grazing, pasture biomass, species composition, defoliation-derived selectivity, subsequent plant response; paper tables and figures | Does the timing and intensity of grazing leave persistent effects on forage production and composition? | Consumption is estimated partly from animal size/growth; no individual intake–search or reserve series |
| Borer et al. (2020), Nutrient Network | Factorial fertilization × fencing, annual peak live biomass across sites; three data CSVs plus metadata and coordinates | How do nutrient supply and herbivore access change standing biomass, and how variable are those contrasts? | Open plots are visited by herbivore communities; their abundance, visits and intake are not measured at our scale |
| Waldram et al. (2008), Hluhluwe–iMfolozi | Rhino removals, sward height/biomass, short-grass extent, other grazers' dung and burn patterns; paper only | Can grazing maintain accessible short swards and change other herbivores' patch use? | Nonrandom removals, mobile animals and community effects; no individual condition or acquisition histories |
| Wigley et al. (2020), Mpala, Kenya | Long-term paired exclosures, grass/woody cover, woody carbon and soil carbon/isotopes; paper only | How do prolonged herbivore exclusions alter vegetation and ecosystem carbon? | Carbon pools, woody competition and community effects lie outside the present model |

### Ash and McIvor: the most focused plant-response case

The experiment used two replicate blocks, each divided among three grazing
seasons and three utilization treatments. Three steers, initially averaging
135 kg, grazed each 2–8 ha treatment plot for eight weeks. The many quadrats
are subsamples; they do not replace the two experimental blocks. Target
utilization was 15/30/45%, but achieved estimates were 13/22/42% in the early
wet, 10/20/38% in the late wet and 22/42/61% in the dry season (Table 1,
p. 127). A reconstruction must use achieved exposure and uncertainty.

The informative contrast is not simply less standing biomass under grazing.
After early-wet medium/high use, the following season's estimated production
was 82%/61% of the low-use treatment, whereas dry-season grazing showed no
corresponding reduction (Table 4, p. 129). The following year was dry; the
second-year follow-up sampled only the early-wet treatments, after a burn.
Neither follow-up is a clean, continuously observed relaxation curve.

The initial use should be an ordinal seasonal-response check, not a fitted
continuous dose-response curve. Two blocks and consumption estimated partly
from the animal response cannot support the latter without further evidence.

Utilization and the compensation calculation use estimated consumption,
derived partly from animal size and growth, plus residual biomass. Thus these
are not independent observations of animal acquisition. Standing material also
includes senescent carry-over; the authors corrected next-season production
using estimated carry-over fractions (pp. 125–126). A single edible-stock
model cannot simply equate that measurement with its state. Species-selective
loss and persistent growth effects are credible challenges to our simple
plant representation; they do not yet select a particular replacement.
The authors also caution that apparent dry-season utilization can include
detachment of senescent material rather than additional animal offtake.

### Borer: strongest supplied data, different inferential scale

This is a factorial manipulation of nutrients and vertebrate access in
5 × 5 m plots, usually with three blocks per site. Biomass is annual peak-season
live aboveground dry mass, sampled from two 0.1 m² strips, not continuous
production or an intake flux. The supplied duration cohorts are:

| Filename suffix | Rows × columns | Sites | Actual `year_trt` range |
| --- | ---: | ---: | ---: |
| `years-2-4.csv` | 2,729 × 14 | 58 | 1–4 |
| `years-5-7.csv` | 3,339 × 14 | 42 | 1–7 |
| `years-8-10.csv` | 2,971 × 14 | 24 | 1–10 |

These are overlapping duration cohorts, not disjoint windows. The 9,039-row
stack has 4,720 distinct site–block–plot–calendar-year keys. No duplicate key
occurs within an individual file. Forty-eight shared `ping.au` keys differ in
`dom.graze` between the first two files (FALSE versus TRUE); their other fields,
including biomass, agree. No pretreatment rows are supplied, despite a baseline
year having been measured in the experiment.

Most consequentially, **the supplied data and metadata have no fence/nutrient
treatment assignments**. Plot identifiers are not a documented treatment key.
The factorial contrast cannot yet be reconstructed from this package. The
three data tables and metadata are byte-identical to the publisher's source
ZIP downloaded on 25 September 2026, so this omission and the livestock-flag
discrepancy are not peculiar to Bec's copy. Recovery of a treatment key and
clarification of `ping.au` are prerequisites for that analysis, not grounds
for guessing from plot numbers or biomass.

The outcome `lm.lg` is log10(g dry matter/m²). Its conversion to kg DM/ha is
`10 * 10^lm.lg`; negative log values are not negative biomass. Outcome and key
fields are complete, with no non-missing non-finite numeric values. Missingness
affects domestic grazing, the square-root herbivore index and soil nitrogen.
The coordinate-only file exactly matches the 58 unique coordinate pairs in
the data, but drops site names; it is a derived convenience file.

The herbivore index is an expert assessment of species' impact and frequency,
summed across taxa; the other herbivore covariate is modeled biomass. Neither
is a measured treatment-level grazing rate (Methods, p. 6). Exclosure–open
differences combine removal with changes in production, senescence, competition
and plant composition. They cannot be assigned wholesale to consumption.

The study therefore offers potential vegetation contrasts and environmental
contexts, conditional on an explicit observation model and exposure assumptions.
It does not turn the current focal animal into a representative natural
community or identify its search efficiency. Negative or weak fencing effects
must remain possible observations rather than be discarded to enforce a
preferred grazing mechanism.

### Waldram: an important challenge to biomass-only reward

The study identified 52 wallows, 23 in rhino-removal areas and 29 in controls,
within 1 km² landscape cells. Eight 60 m radial transects around each wallow
sampled vegetation and other grazers' dung. Rhino removals were a management
intervention, not randomized allocation; remaining rhinos could enter the
areas. The dung measure cannot estimate rhino use because rhinos use middens.

Sward and grazer contrasts were stronger in the mesic than semiarid area.
However, the park × removal interaction for short-grass proportion was
non-significant and removed from the final regression (pp. 106–107). Do not
promote differing within-park significance into a demonstrated interaction.
The 2001/2002 burn analysis and June 2004 wallow survey also belong to distinct
evidence streams, not one animal trajectory.

This is a useful ecological warning for our model: more standing biomass can
coincide with reduced use by short-grass specialists. Height, structure and
quality can change feeding value. Our current homogeneous edible stock cannot
represent the full facilitation mechanism. The study supplies a future spatial
pattern to explain, not a measured memory or search parameter.

### Wigley: retain for a later ecosystem question

Three sites each held an approximately 0.5 ha exclosure–control pair, with
measurements in the inner 50 × 50 m. Exclosures excluded herbivores above 2 kg.
The three pairs, not the many soil samples or vegetation points, provide the
treatment replication. Cover was observed in 1999/2002/2016; woody censuses
also included 2009. Soil sampling in 2016 and a further 2019 sampling have
different designs (Methods, pp. 2–4).

Herbaceous cover was 71.9% in exclusions versus 50.2% in controls in 2016;
woody cover also increased (Fig. 1). The herbaceous difference is about
22 percentage points, not a measured 22% increase in edible biomass. Soil
carbon stocks and isotope source attribution integrate processes absent from
our current plant/animal system. This is valuable evidence about long-term
herbivore effects, but a poor next calibration target for the present model.
The authors explicitly state that grass biomass was not measured directly
in this study (Discussion, pp. 7–8).

## The additional animal-process source

The archive also includes Jeschke and Tollrian (2005), *Predicting Herbivore
Feeding Times*, under the abandoned Julia folder. Its placement does not
reduce its value as a primary scientific source. It separates searching from
feeding and proposes a satiation-based feeding-time fraction `b g / t_g`,
equivalently `b / c`, where `b` is handling time per food mass and `c` is
retention time divided by gut capacity. The latter is not gut retention time
itself (pp. 188–190).

The mammal handling relation in Fig. 4 (p. 196) is
`b = 1.65 m^-0.766`, in minutes per gram dry matter, with numerical body mass
`m` in kilograms. It is an interspecific relationship, not a species-specific
calibration. The authors require comparable diet and physiological conditions
and explicitly warn against circular validation. These are useful source and
unit checks for any later animal parameterization. They do not estimate square
metres searched per hour or a memory-recovery timescale.
The C++ `eat()` routine does take the reciprocal of this handling relation and
convert g/min to kg/min before its defence adjustment (lines 1164–1168).
That narrow conversion is consistent with the primary paper; the historic
model's inadequacy should not be used to presume every inherited equation wrong.

## Consequences for our next scientific decision

For a homogeneous footprint below its area cap, the current encounter ceiling
is `q (B - R) / 10000` kg DM per feeding hour, where positive accessible density
`B - R` is in kg DM/ha. Estimating `q` from intake therefore requires concurrent
edible density, a defensible residual, feeding opportunity and evidence that
appetite/handling/gut limits did not bind. When another ceiling binds, observed
intake provides at most a conditional lower bound on `q`. Walking speed alone
does not provide an area rate without feeding width, interception efficiency,
revisitation and activity assumptions. None of the four field papers supplies
that complete observation set.

The next useful tranche is an empirical bridge, with two explicit targets:

1. Select one coherent extant-animal reference and recover matched evidence
   for intake versus edible sward conditions, feeding time, passage, energetic
   demand and water. Trace taxon, body size, diet, physiological state and units.
   Determine what can bound acquisition and what remains unidentifiable;
   do not combine unrelated allometries into a nominal species.
2. Specify an Ash-based plant-response comparison using documented seasonal
   exposure and an observation model for standing live/dead material. Before
   implementation, decide whether the accepted one-stock model can address
   the selected contrast, and which missing processes are indispensable.

Borer can subsequently test the generality of vegetation contrasts without
claiming independent animal calibration. Waldram motivates structure-dependent
feeding value; Wigley motivates later ecosystem pools. These are recommendations
for discussion. This assessment does not approve extra physiology, a TTR.PGM
coupling, new simulations, a fitted body-size axis or a paper format.

## Primary references and access limits

- Ash, A. J. & McIvor, J. G. (1998). *Journal of Vegetation Science* 9,
  123–132. [Paper](https://doi.org/10.2307/3237230).
- Borer, E. T. et al. (2020). *Nature Communications* 11, 6036.
  [Paper](https://doi.org/10.1038/s41467-020-19870-y);
  [published data identifier](https://doi.org/10.6073/pasta/a318fe0fb11eb43c1a2c8233b2e3494f);
  [publisher source ZIP](https://media.springernature.com/original/springer-static/esm/art%3A10.1038%2Fs41467-020-19870-y/MediaObjects/41467_2020_19870_MOESM4_ESM.zip).
  DataCite resolves the DOI to EDI package `edi.625.1`; EDI content retrieval
  returned HTTP 403 here, so no claim of comparison with that repository copy
  is made. The publisher comparison is independently recorded.
  The [2021 correction](https://www.nature.com/articles/s41467-021-20985-z)
  corrects an affiliation, not the data or scientific results.
- Waldram, M. S., Bond, W. J. & Stock, W. D. (2008). *Ecosystems* 11,
  101–112. [Paper](https://doi.org/10.1007/s10021-007-9109-9).
- Wigley, B. J. et al. (2020). *Ecology* 101, e03008.
  [Paper](https://doi.org/10.1002/ecy.3008).
- Jeschke, J. M. & Tollrian, R. (2005). *Ethology* 111, 187–206.
  [Paper](https://doi.org/10.1111/j.1439-0310.2004.01052.x).

The scientific reading used the supplied PDFs, including visual inspection of
decisive equations, figures and tables. DOCX text and comments were inspected
separately from rendered manuscript pages. The manuscript's author comments
are ordinary bracketed text, not Word comment objects with resolution metadata.
The R inventory and publisher comparison are retained under
`borer-data-analysis/` alongside the archive. Independent specialist readings
checked the historical distinctions and empirical eligibility; these are
critical checks, not independent empirical validation. Raw field data for Ash, Waldram and
Wigley were not supplied; this is not a claim that no such data exist elsewhere.
All recommendations remain distinct from the accepted synthetic model findings
in [Decision 0063](decisions/0063-encounter-and-policy-sensitivity.md).
