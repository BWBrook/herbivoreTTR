# Successor Brief: Herbivore TTR

Prepared 2026-09-06 after Goal 060. This is a compact entry point, not a new
scientific contract. Check live files and Git state before acting; you do not
need the predecessor's conversation or its full chronological history.

## Start Here

Work directly in `/Users/bwbrook/git/herbivoreTTR`. Goals 059 and 060 are
accepted on top of cleanup commit `dcc5d1b`. Barry authorized committing and
pushing their source and conclusions on 2026-09-06. Check live Git state and
preserve subsequent changes. Further implementation is paused for a broader
scientific discussion; the duration experiment below is an option, not an
approved next tranche.

Read in this order, stopping when you have enough context:

1. Current `~/.codex/AGENTS.md` and this repo's `AGENTS.md`.
2. [Model charter](docs/model-charter.md) and the current-model section of
   [README](README.md).
3. The stage-map table in [Roadmap](docs/roadmap.md), then
   [Decision 0060](docs/decisions/0060-water-route-expenditure.md).
4. Consult [Model specification](docs/model-specification.md) by topic and
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

The current model has:

- A 24-hour clock with hourly pure transitions, plain state lists, and data-frame
  histories. Dry-matter intake supplies already-metabolizable energy to one
  gut stock; release uses opening gut energy, not the current mouthful.
- Physical body-energy reserve, maintenance, routine activity and incremental
  movement costs, with bounded body/gut appetite feedback. Body mass is a
  downstream interpretation, not feedback into physiology. Do not silently
  add another digestibility or thermic-effect deduction to metabolizable energy.
- A synthetic forage stock with constant production, proportional background
  loss, an unavailable residual, and density-scaled local herbivory. This is
  a diagnostic renewal model, not mechanistic plant physiology.
- Explicit named patches, hourly routes, different food quality, and an
  experience-based food-patch rule. The animal remembers returns rather than
  seeing unvisited biomass or simulator forecasts. Decision 0054 records why
  adequate current forage and accumulated shortfall matter.
- Separate body-water accounting, food water, a familiar drinking source, and
  incremental temperature-driven evaporation. Water travel suspends feeding
  and costs 900 kJ per leg. The present thermal forcing has no action-dependent
  loss, body temperature, or heat balance.

Arcs 01-04 (herbivore core, isolated forage, non-spatial coupling, and initial
explicit patches) are closed at their stated scope. We are in
[Arc 05](docs/arcs/05-landscape-constraints-and-scenarios.md): resource
constraints and behavior before richer ecological scenarios. Protein, dynamic
plant moisture, mechanistic thermoregulation, richer landscapes, demographics,
and calibrated viability claims remain deferred, not abandoned.

## Latest Scientific Decision

Goal 060 crossed five water-route expenditure multipliers (0, 0.5, 1, 1.5, 2)
with isolated/coupled forage, four existing temperature histories, and the
reactive, original anticipatory, and cost-aware policies: 120 runs. All branches
share 60 days of reactive history at 900 kJ per water leg. Cost changes at
branching and persists through 84 treatment days and 42 days after heat removal.
Thus this is changed energetic accessibility, not lifetime habitat adaptation
or literal distance. Every trip still requires two one-hour legs and a drinking
hour. The candidate knows the cost of the actual routes; food routes stay fixed.

Every heated coupled run completes at zero or half cost, but stops before heat
removal at unit cost or above. Doubled cost also stops the no-added-heat coupled
runs around day 85. Isolated forage tolerates greater expenditure: all runs
complete through 1.5 cost, with eight heated failures at double cost. Original
anticipation alone completes the isolated evening case at double cost, where
reactive and cost-aware drinking stop on day 78. Neither candidate dominates.
Reactive remains the default; stop policy tuning.

Lower cost prevents or delays energy boundaries across this sampled grid, but
need not raise combined energy at every checkpoint because intake responds.
All water minima exceed 25.6 kg. Completion is a finite model horizon, not
biological recovery or viability. High-cost coupled shifted runs stop before
the phase shift and cannot inform its consequences.

For this layer, start with `experiments/water-route-expenditure.R` and
`temperature-hydration-fixtures.R`. The shared fixture now contains the account
and summary helpers previously local to Goal 059; their bodies are unchanged.
The hourly transition and package physiology are unchanged. Per-cost contrasts
use three-policy common hours; across-cost contrasts use one common 15-run
horizon per system/history. Coupled shifted across-cost energy ends at 514 h,
before the shift. Keep valid partial days and charge only realized movement;
endpoint stocks are missing for runs that did not reach that endpoint.

## Candidate Next Question: Trip Duration

**Water-trip duration at fixed total route expenditure**, not yet authorized.
This would isolate time unavailable for feeding and delayed drinking from the
direct expenditure effect established in Goal 060. Retain the three policy
forms and explicit ledgers. Forecasts must use actual durations; freeze late-
departure, precautionary-horizon, and day-boundary conventions before decisive
runs because longer trips change within-day feasibility. Do not add new
sources, feeding rescheduling, physiology, or another policy search at once.

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

Goal 060 completed 120 branches with three local R workers in about 168 seconds.
All 24 unit-cost primary run objects and both preconditions exactly reproduce
Goal 059. Independent review rebuilt balances, summaries, and comparison
horizons. Every complete zero-cost trip still has two moves and three unavailable
hours. All 332 package-test expectations pass, 79 retained R files parse, and
whitespace checks pass. A blank EOF line was removed after execution without
changing any expression; original digests and the amendment remain in the cache.

The publication gate for Goals 059–060 passed on 2026-09-06: full package
tests and external `R CMD build` / `R CMD check --no-manual`, with Status OK
and no errors, warnings, or notes. These goals change experiments and
documentation, not `R/` or the public API. Do not rerun the whole suite merely
to orient. Use `Rscript --vanilla` with the intended installed
package/library, and verify live runtime state instead of relying on old `/tmp`
paths. Generated evidence is ignored, not committed.

Current cache, compact tables, frozen design, renderer, and figures are at:

`/Users/bwbrook/git/herbivoreTTR/outputs/goal-060/`

Useful figures are `completed-duration.png`, `policy-ranking.png`, and
`energy-attribution.png`. Goals 058 and 059 remain in their corresponding
`outputs/goal-*` directories. Do not delete retained evidence during orientation.
Scientific decisions belong in `docs/decisions/`; current contracts belong in
model docs. Use proportionate planning, not a mandatory four-file goal template
or retired management workflow.
