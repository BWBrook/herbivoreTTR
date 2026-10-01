# Successor Brief: Herbivore TTR

Updated 2026-10-01 after Barry approved the matched-records search and Astra
completed the feasibility assessment and interpretation review of benchmark 065.
This is a compact entry point, not a new
scientific contract. Check live files and Git state before acting; you do not
need the predecessor's conversation or its full chronological history.

## Start Here

Work directly in `/Users/bwbrook/git/herbivoreTTR`. Programmes 061–063 and the
archive assessment are preserved in `d610ae9`; 064 is the completed bounded
recovery repair described below. On 25 September Barry authorised committing
and pushing the accumulated work, repairing the inherited two-day recovery
expectation, and using red kangaroos and cattle as complementary empirical
anchors. The authorised 063 diagnostic is closed; its original trajectories
remain explicit historical controls. Barry's
recovered archive and four empirical cases have now been assessed; see the
[assessment](docs/rebecca-archive-assessment.md) before proposing another
scientific layer. The recovery repair and source assessment are complete.
Barry approved the red-kangaroo accounting/acquisition tranche on 29 September
(message 774); Decision 0065 records its completed result. On 1 October Barry
approved searching for long-term matched kangaroo records (message 801).
The [feasibility assessment](docs/chronic-decline-records-feasibility.md) identifies
Kinchega–Tandou and Fowlers Gap study windows; original animal/pasture data
access remains unresolved. Full dynamic species physiology, new plant structure
and manuscript publication remain separate
decisions. Fable's original review is in correspondence thread 56, messages
540–545; Astra recorded the earlier authorisations in message 549.

Read in this order, stopping when you have enough context:

1. Current `~/.codex/AGENTS.md` and this repo's `AGENTS.md`.
2. [Model charter](docs/model-charter.md) and the current-model section of
   [README](README.md).
3. The [matched-records assessment](docs/chronic-decline-records-feasibility.md),
   [Decision 0065](docs/decisions/0065-red-kangaroo-budget-and-acquisition.md)
   and its [specification](docs/red-kangaroo-benchmark-specification.md), then
   the stage-map table in [Roadmap](docs/roadmap.md) and
   [Decision 0064](docs/decisions/0064-plant-matched-return-expectation.md), with
   Decision 0062 for physical representation and 0063 for the frozen old rule.
4. Read the [anchor evidence](docs/empirical-anchor-evidence.md) and
   [observation contracts](docs/empirical-anchor-contracts.md), then the
   [archive assessment](docs/rebecca-archive-assessment.md) when history matters.
5. Consult [Model specification](docs/model-specification.md) by topic and
   [Experiments](experiments/README.md) when planning the next implementation.
   Do not load every historical decision or rerun experiments just to orient.

## What We Are Building

Barry Brook wants a mechanistically understandable model of how habitat and
forage conditions affect herbivore physiological state. The motivating context
is extinct Sahul megafauna, including Diprotodon, but the present model is a
deliberately synthetic, loosely kangaroo-like reference, not a fitted species.
Longer-term chronic reserve decline and recovery matter more than isolated
seasonal deficits. Empirical parameterization and publication framing come
later; the immediate task is understanding mechanisms and their interactions.

The old C/C++-derived implementation was replaced by a clean R rebuild.
Ecological logic and explicit assumptions outrank historical behavior. Do not
recreate legacy architecture, compatibility machinery, or particle-level gut
tracking. Historical code is evidence to consult for a specific question only.

The current representation has fixed physical feeding blocks, station centres,
area-based encounter/search rates and metric travel. Numerical vegetation cells
can subdivide the same feeding support without changing biology. See the
[feeding-access specification](docs/feeding-access-specification.md). Earlier
linear-turnover, density-scaled and one-hour-route systems remain scientific
references. The animal physiology is unchanged.

The current spatial experiment composes:

- Hourly gut release, appetite feedback and body-energy accounting. Food energy
  is already metabolizable; do not add another digestibility deduction.
- Exact biomass-dependent production/senescence, residual protection and focal
  intake removed conservatively from intersecting physical feeding areas.
- Daily food-departure decisions with last/best experienced returns and elapsed
  absence. The current forecast propagates a return-equivalent proxy under
  known baseline plant dynamics, capped by historical best. It receives no
  actual unvisited biomass or forcing. Strict expected improvement limits
  deficit-driven movement; the prior remains synthetic. Informed/cyclic rules
  are controls, and the frozen 062/063 runners explicitly use the old clock.
- Fractional and multihour travel, reactive off-domain water excursions, food
  water, ordinary water loss and separate movement expenditure. The 062 study
  adds no thermal physiology and uses fixed food moisture/energy.

Arcs 01-04 (herbivore core, isolated forage, non-spatial coupling, and initial
explicit patches) are closed at their stated scope. We are in
[Arc 05](docs/arcs/05-landscape-constraints-and-scenarios.md): resource
constraints and behavior before richer ecological scenarios. Protein, dynamic
plant moisture, mechanistic thermoregulation, demographics,
and calibrated viability claims remain deferred, not abandoned.

## Latest Scientific Decision

The red-kangaroo benchmark (065) is complete. Munn's corrected energy-derived
intake is reproduced at 518 g DM/day under the printed DE conversion, or
576 g/day with assumed ME:DE=0.9. At the central values, synthetic food-water
yield 3.28 exceeds total measured water turnover before drinking or metabolic
water. The declared SE corners qualify this result; they are not confidence
intervals. Energy closure is an accounting check of a derived intake.

Short's 12 reconstructed Fig. 4 points retain yard identity and dependence.
The primary shared-yard midpoint comparison gives descriptive RMSE 224.5
g DM/animal/day, versus 197.9 for the published in-sample curve. The opening
and closing biomass alternatives give 188.9 and 239.4; none is selected by fit.
No primary prediction overlaps the digitization-only rectangles, but these
exclude larger unquantified observation errors; Short's fitted curve overlaps
only one. The 18 no-growth, J=0 cases span RMSE 188–242. This does not establish
model failure or statistical equivalence. The 1 October addendum rejects an
empirically estimated error floor and a confidence interpretation of the
tested 42–170-m2/day search range. Matched R/J offsets are structurally aliased;
their numerical agreement checks the implementation. R=200 gives midpoint
RMSE 466.2 and is not an empirical anchor.

Study-specific records and experiment clients are retained alongside the
unchanged synthetic reference. No full animal fixture, new plant process,
memory change or chronic-decline simulation was added.

The approved records search found quarterly Kinchega–Tandou pasture/count
overlap during 1980–84, condition/recruitment sampling during 1982–84, and
complementary Fowlers Gap condition/pasture/rain records from 1988–92 and
demographic records from 1994–97. A downstream copy of 41 paired Kinchega
count occasions was downloaded and its R schema checked; full primary-source
verification is pending. No original individual condition or site-level
pasture payload was obtained. Published reconstruction and targeted records
inquiries are concrete next routes; no external inquiry has been sent.

## Recovery Repair (064)

All five predeclared repaired trajectories complete day 228, removing the four
selected historical failures: undisturbed clustered/fragmented at q=.6 and
continuous near-water sustained disturbance at q=3/5. The original continuous
undisturbed control still completes. Reference clustered/fragmented feeding
expands from four stations to eight, with median complete absence rising from
3 days to about 20 and improved first-day returns. This supports Fable's
diagnosis in these cases, not every failure in the old 90-case grid.

Repaired day-228 reserves are 39,853/39,914 kJ in those undisturbed layouts and
39,525/39,727 kJ in the high-search disturbed cases. The last case still has a
negative final 28-day trend (−47.23 kJ/day). Completion and a near-baseline
endpoint are not stable recovery or empirical validation. All five old-rule
replays are bit-identical; the 14 reported paths pass accounts and bounds.
No clock tuning or further trajectory search followed the results.

A universal fixed replacement clock was rejected: exact baseline recovery
from 200 to 250 kJ/h takes 14.246 days at q=.6, while 250 is unreachable at
q=.3. The current prior respects that baseline geometry, but may remain wrong
during unobserved drought. The 26 September review also finds post-forcing
opening overprediction: agreement of the median forecast and median opening
potential at the appetite cap does not mean each forecast is exact. Of 19
inadequate post-forcing revisits, 17 have opening overprediction; 14 start
adequate and lose capacity during feeding, with overlap between these causes.
The daily-mean return proxy exceeds true departure-day closing stock even for
the tested absences wholly after forcing. See Decision 0064's dated addendum;
the frozen [064 contract](docs/feeding-access-recovery-specification.md) is unchanged.

The 27 September cached diagnostic supports testing a last-hour observation:
across 44 post-forcing-origin revisits, median biomass-proxy excess falls
from 11.34 to 1.51 kg/ha at q=3 and from 8.54 to 1.07 at q=5. It remains
an opening-hour observation, and it does not reveal drought. Replacing the
existing scalar would also change daily adequacy and accumulated deficit;
no new policy trajectories were run. Any prospective observation comparison
must separate endpoint memory from daily energy adequacy and fix its clock.

Red kangaroos and cattle are the agreed complementary empirical systems.
Munn's 2011 corrigendum replaces the original 994 g/day kangaroo intake with
518 ± 39 g/day; this is energy-derived, not directly observed intake. Field
metabolic rate already includes movement. Short's reported residual below
20 kg/ha challenges an empirical interpretation of R=200. No source directly
identifies this model's instantaneous q or memory. Ash's prediction is recorded
on paper; no seasonal comparison or new plant compartment was implemented.

## Frozen Encounter and Policy Study (063)

The frozen 063 study tests five encounter coefficients (.3, .6, 1.5, 3 and
5 m²/h) from day 1, with shared experienced day-60 baselines followed by
policy interventions. All 15 baselines and 90 planned comparisons are evaluable;
34 branches complete day 228. At .6, all four missing undisturbed informed/cyclic
controls complete near their baseline reserve, while experienced animals exit
on days 194/197. In sustained scenarios, informed animals complete all six
cases at each of 1.5/3/5, whereas experienced animals exit throughout the grid.
The latter are not always confined to four stations, and increasing search
can bring failure forward through changed decisions and depletion history.

The results support conditional coefficient-by-policy effects, not a general
fragmentation law or a calibrated threshold. Completion does not imply lasting
recovery: only 10 of 18 completing sustained runs finish above their own
day-60 reserve, and 12 have positive final 28-day trends.

The [ratio note](docs/feeding-access-ratios.md) supplies explicit dimensionless
diagnostics and a bounded stationary one-block map. A single 100-m² block's
renewal ceiling is already insufficient for reference demand; that alone is
not evidence for a grazing trap or an exact finite-horizon failure prediction.
Independent review verified all 14 overlaps with 062 as identical full hourly
ledgers, matched initial states, conservation and supply bounds. See Decision
0063 for the evidence and frozen-design limits.

## Physical Representation Foundation (062)

The frozen 53-branch study holds total habitat/plant parameters fixed across
three constructed layouts and compares growth disturbances, water access,
policies, and access counterfactuals. Only eight main branches complete day228:
two undisturbed continuous-layout branches and all six pooled-stock controls.
Physical sustained cases exit despite substantial accessible biomass; informed
access delays the boundary by about a month. Pooled-stock success establishes
feasibility under that contract, not under physical search. Zero transit changes
choices and can worsen outcomes; pooled search sees mean density rather than
the best block. These are not additive or monotone mechanism decompositions.

The original 28-day pulse failed to recover under the experienced rule. A
separately declared two-branch seven-day follow-up retained all model parameters.
Near water reaches day228 but finishes 8,545 kJ below day60 and is declining;
far water exits on day143. Early near-reference condition at day75 was not
lasting recovery. No further duration or parameter search was performed.

The physical representation passes equivalent-grid checks, including all
hourly station/departure identities. Maximum body-energy discrepancy across
homogeneous refinement is about 2.3e-11 kJ. Fixed heterogeneous-field refinement
also passes. All 55 trajectories satisfy conservation and both cumulative
intake upper bounds; the analytical impossibility screen is inconclusive for
these scenarios. Water remains above the critical interpretation boundary.
These are synthetic model-domain exits, not death, optimality or viability
claims. Decision0062 gives the detailed limits and independent audit.

Run `Rscript experiments/feeding-access-study.R` after installing the package
from the project root. It prints results and writes nothing. For optional
parallel execution, source the script and call `run_feeding_access_study(cores=3)`.
The adaptive follow-up is a separate function taking the main result. Generated
review material is in ignored `outputs/feeding-access-062/`; the main and
follow-up PDFs are separate. The older 061 study remains reproducible.

TTR.PGM was assessed from its primary paper and release source. Direct coupling
would require persistent six-state restart, grazing fluxes, area scaling and
time-step work. [The assessment](docs/plant-model-assessment.md) recommends the
current one-stock model for this synthetic question and a later TTR comparison
if empirical cases justify it. Barry supplied the DGVM/Thornley project history;
it is recorded with attribution in the spatial specification. Rebecca's
recovered package contains four proposed field studies; their assessment is
summarized below. Publication structure remains undecided.

## Recovered Empirical Evidence

The 25 September read-only assessment separates Bec's C++ prototype, conversion
plans, the archived R lineage, and the current rebuild. Barry identifies Julia
as an abandoned side experiment. The archive has genuine field-study material,
but the legacy R observational benchmark was explicitly synthetic. Archived
C++ output contains non-finite plant values before the configured herbivory
onset; no source/build/seed record binds those outputs to the supplied code.
They are not a parity target for the rebuild.

Ash and McIvor (1998) is the recommended first qualitative seasonal plant-response
case, with only two blocks and indirectly estimated consumption. Borer (2020)
provides overlapping plot-year biomass cohorts, not independent time windows;
the supplied files lack treatment assignments and disagree on 48 shared
`ping.au` livestock flags. All four source CSVs match the publisher's ZIP byte
for byte. Waldram (2008) is a spatial/structure challenge with nonrandom rhino
removals; Wigley (2020) concerns slower vegetation and carbon outcomes. None
directly estimates search efficiency, memory or individual physiological decline.

The original ZIP and extracted sources are outside this repo at
`/Users/bwbrook/input/herbivoreTTR-rebecca-2026-09-25/`; the assessment records its
verified checksum, primary references, inspection limits and reproducible R
data inventory. No legacy model was executed and no model code or parameter
was changed during this assessment.

The archive synthesis is correspondence thread 28, message 539. The 064 result
is in thread 56, Astra message 554; Fable's review is 556–558 and his supplied-PDF
note is 563. Barry's three authorisations are recorded in message 549. The
phase/full-text response is Astra 569; Fable's contract critique is 571–573.
Fable's subsequent agreements and Ash specification are messages 644–645;
his proposed 20–100-kg/ha bound on the edible residual was withdrawn. Barry's
red-kangaroo approval is Astra message 774. Fable's 065 critique and records
proposal are 798–799; Barry's search approval is recorded in Astra 801. The
thread has been read contiguously through 801 and acknowledged through 799.
Do not treat reviewer agreement as model validation or a broader implementation
mandate. The last strict catch-up checkpoint was 801; pass it as `after` to
`read_updates`, not as a `mark_read` message ID.

## Next Scientific Discussion

Fable's next review should assess the matched-records access routes and the
qualified Short interpretation. Munn's budget and Short's acquisition
comparisons are
closed at the declared scope; do not expand the grid or tune parameters to
repair the observed discrepancies. The source-derived records do not supply
unmeasured reserve, gut, feedback or dehydration parameters for a full
dynamic species fixture.

The search has answered the feasibility question positively for published
aggregate observations, conditionally for original records. Prioritise the
Kinchega 1980–84 overlap and Fowlers 1988–92 condition series when defining a
bounded recovery tranche. The latter's detailed methods were read through a
transcription; recover the publisher PDF before numerical extraction. The
1994–97 Fowlers articles explicitly offer summaries on request. Do not infer
that institutional custodians retain every original sheet, or that the
downstream count copy has been completely checked. See the assessment for
specific sources, access states and the acquired file hash.

Short does not establish a 20–100-kg/ha bound on model R. Its stock-loss
estimator omits an explicit growth correction and has unresolved density
pairing. Its cited 47% low-pasture statistic excludes shrubs and is a personal
communication summary, not a retrieved series or a direct zero-food fraction.

For Ash, Fable's revised message 645 specifies fixed capacity and two dynamic
capacity variants, stock-bounded removal, achieved-utilisation matching and
a proposed discrimination check. It has been received, not yet accepted or
implemented. Review common forcing, the consequences of model-specific
exposure calibration, the claimed low-green-stock limit and what two blocks
can discriminate before presenting the separate concrete plant proposal.

Full dynamic species parameterization, the plant extension and a multi-season
kangaroo comparison remain separate scientific choices. No anchor validates chronic
decline; matched studies have been located, but a validated dataset and an
observation contract remain to be assembled. The current day-60 transient
remains frozen for causal attribution;
future disturbance studies need a grazed-reference or periodicity check where
such a reference exists. No fitted dynamic model or publication follows
automatically from the completed accounting/acquisition benchmark.

## How To Collaborate

You are Barry's persistent scientific collaborator and orchestrator, not a
passive dispatcher. The former action agent `grazer` is retired. Use native
bounded subagents when they add independent evidence or useful parallel work;
follow current global model/effort policy, not historical profile routing.
Chief of Staff and Goal Composer are not required reading for this project.

- Use [Twilight Laboratory](/Users/bwbrook/.codex/skills/twilight-laboratory/SKILL.md)
  for substantive tranches: agree on the scientific endpoint, authority and
  stop conditions, then execute routine stages and repairs autonomously.
- Use [Kill Your Darlings](/Users/bwbrook/.codex/skills/kill-your-darlings/SKILL.md)
  for periodic lean reviews, particularly at arc boundaries. An audit is not
  permission to refactor or delete. Avoid backward-compatibility scaffolds,
  ceremonial ledgers, redundant tests and repeated successful validation.
- Be assertive about evidence and recommendations. Escalate material science,
  strategy, resources or authority, not reversible implementation details.
  One focused review/repair pass is normally enough; do not chase perfection.
- Lead closeouts with the ecological result and a few discussion sentences.
  Propose the next coherent tranche inline. Display energy quantities as
  integer kJ, except when precision is warranted for a specified rate.
- End closing messages to Barry with the date and time in Australia/Hobart;
  he uses this to track whose turn it is in the Fable/Astra exchange.

The governing principle is **rigour at the scientific decision boundary;
proportional engineering everywhere else**. Skills support the requested work;
they do not enlarge its authority or create extra approval gates.

## Evidence And Practical Notes

Current 065 evidence is in ignored `outputs/red-kangaroo-065/`: `benchmark.rds`,
budget/response/prediction/RMSE/check tables and the two-page
`red-kangaroo-benchmark.pdf`. Source `experiments/red-kangaroo-benchmark.R`
and call `run_red_kangaroo_benchmark()`; optional output is explicit. The
runner requires only the installed project package and committed numerical
source inputs, not historical caches or PDFs. The PDF and numerical checks
were reviewed independently; targeted package tests, R parsing and whitespace
checks passed. A package release gate was unnecessary because package source
and API did not change. Frozen 064 source/input hashes still match.

The 064 evidence is in ignored `outputs/recovery-clock-064/`: `repair.rds`,
summary, revisit and common-horizon CSVs, source/input checksums, audit notes
and `recovery-expectation.pdf`. The no-write runner is
`run_feeding_access_recovery_repair(cores=3)` after sourcing its matching
experiment file; it reads the original 062/063 caches. A separate plotting
function writes only to an explicit path. The 25 September release gate passed
441 package tests and external build/check with Status OK; 064 affects only
experimental composition and docs, with targeted policy/integration/refinement
and analytical checks. The installed exported function definitions match source.

The 26 September audit reads the existing cache only; its R calculation and
tables are in `outputs/recovery-clock-064/phase-review-20260926/`. The three
supplied published PDFs are local in ignored `references/papers/`, with
filenames/checksums in `references/README.md`; extracts and key-page renders
are in `outputs/recovery-clock-064/fulltext-review-20260926/`. Access is resolved,
but observation-model and evidence gaps remain. No new trajectories or package
changes were made, and no release gate was repeated for these documentation updates.

The 27 September read-only calculations are in ignored
`outputs/anchor-review-20260927/`: `check-anchor-arithmetic.R` and
`departure-review/audit-departure-rate.R`, with compact tables and input hashes.
The latter uses prior-day final hour-23 biomass as its endpoint and separates
baseline day 60 from forcing days 61–144. The frozen 064 source/input hashes
still match. Retained R parses and the documentation diff passes whitespace
checks; a package release gate is unnecessary for this review.

The 063 numerical evidence is in `outputs/feeding-access-063/`: `sensitivity.rds`,
summary and baseline CSVs, `analytic.csv`, execution/provenance logs and the
three-page `encounter-policy-sensitivity.pdf`. Source
`experiments/feeding-access-sensitivity.R` and call
`run_feeding_access_sensitivity(cores=3)` to reproduce; the default replay
check needs the retained 062 cache. To reproduce without that cache, explicitly
set `check_reference=FALSE`; this omits only historical trajectory comparison.
The 063 targeted tests, integration checks, analytical arithmetic, R parsing
and independent audit pass. No package equations changed and no release gate
was repeated. All generated evidence remains ignored.

The 062 integration controls, fixed-field/grid checks and independent scientific
review are complete. Full package tests and external R CMD build/check passed
on 2026-09-08 with Status OK and no errors, warnings or notes. Do not repeat
tests or build merely to orient.

Current evidence is in `outputs/feeding-access-062/`: main `study.rds` (about
12 MB), `summary.csv`, `run.log`, `bound-review.log`, and the three-page
`feeding-support-and-recovery.pdf`; the separate `recovery-followup.rds`, CSV,
log and PDF contain the two exploratory runs. All generated evidence is ignored.
The 061 cache and earlier `outputs/goal-*` caches remain in place.

Use project-root Rscript so renv selects the installed project library.
`Rscript --vanilla` bypasses that activation and needs an explicit library path;
do not silently substitute a global package. External R CMD check installs its
own built source. Current contracts belong in model docs and accepted reasoning
in `docs/decisions/`; there is no active goal-file machinery to resume.
