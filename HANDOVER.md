# Successor Brief: Herbivore TTR

Updated 2026-09-25 after assessment of Rebecca's archive and empirical cases.
The latest model study remains encounter and policy sensitivity (063).
This is a compact entry point, not a new
scientific contract. Check live files and Git state before acting; you do not
need the predecessor's conversation or its full chronological history.

## Start Here

Work directly in `/Users/bwbrook/git/herbivoreTTR`. Programmes 061–063 are
implemented and locally validated. The earlier Goals 059/060 closeout was
committed and pushed as `b2f2c97`. On 25 September Barry authorised committing
and pushing the accumulated work, repairing the inherited two-day recovery
expectation, and using red kangaroos and cattle as complementary empirical
anchors. The authorised 063 diagnostic is closed; its original trajectories
must remain identifiable during that repair. Barry's
recovered archive and four empirical cases have now been assessed; see the
[assessment](docs/rebecca-archive-assessment.md) before proposing another
scientific layer. The bounded recovery repair is now authorised; species
calibration, new plant structure and manuscript publication remain separate
decisions. Fable's review is in correspondence thread 56, messages 540–545;
Astra recorded Barry's authorisation in message 549.

Read in this order, stopping when you have enough context:

1. Current `~/.codex/AGENTS.md` and this repo's `AGENTS.md`.
2. [Model charter](docs/model-charter.md) and the current-model section of
   [README](README.md).
3. The stage-map table in [Roadmap](docs/roadmap.md), then
   [Decision 0063](docs/decisions/0063-encounter-and-policy-sensitivity.md), with
   Decision 0062 for the underlying physical representation.
4. Read the [archive and empirical assessment](docs/rebecca-archive-assessment.md)
   for what the recovered sources can constrain and the proposed next tranche.
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
  absence. Strict expected improvement limits deficit-driven movement; this
  does not validate the remembered estimates. Informed/cyclic rules are controls.
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

A compact synthesis and focused sequencing question were posted to Fable in
correspondence thread 28, message 539 (25 September). No reply was awaited or
assumed. The last strict catch-up returned global retrieval checkpoint 537;
use it with `read_updates` for subsequent catch-up, not as a `mark_read` ID.

## Next Scientific Discussion

The fixed-footprint numerical ambiguity is resolved at the declared scope.
The proposed empirical bridge should recover matched animal intake, edible
sward, feeding-time and physiological evidence for one coherent extant-animal
reference, alongside a bounded Ash-based plant-response comparison. The four
recovered field studies cannot calibrate the encounter coefficient directly.
The present two-day memory can confine feeding to part of a food-rich
landscape, and cannot yet be interpreted
as calibrated behaviour. A mechanistic TTR plant model, more animal physiology
and population demography remain separate decisions. No new implementation or
publication is implied by this recommendation.

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

The governing principle is **rigour at the scientific decision boundary;
proportional engineering everywhere else**. Skills support the requested work;
they do not enlarge its authority or create extra approval gates.

## Evidence And Practical Notes

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
