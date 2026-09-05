# Successor Brief: Herbivore TTR

Prepared 2026-09-05 after Goal 058. This is a compact entry point, not a new
scientific contract. Check live files and Git state before acting; you do not
need the predecessor's conversation or its full chronological history.

## Start Here

Work directly in `/Users/bwbrook/git/herbivoreTTR`. The scientific baseline is
published commit `b93278d`; this handover is recorded in a subsequent
documentation commit. Redundant linked worktrees and merged branches were
removed, leaving the canonical checkout and `main` as the only local and remote
branch. Preserve any subsequent changes. Goal 058 is closed; Goal 059 is
proposed, not approved.

Read in this order, stopping when you have enough context:

1. Current `~/.codex/AGENTS.md` and this repo's `AGENTS.md`.
2. [Model charter](docs/model-charter.md) and the current-model section of
   [README](README.md).
3. The stage-map table in [Roadmap](docs/roadmap.md), then
   [Decision 0058](docs/decisions/0058-temperature-anticipatory-drinking.md).
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

Goal 058 tested reactive drinking against an additional 08:00 anticipatory
top-up. Anticipation uses current water plus the previous 24 completed hours'
physiological net water draw, excluding drinking and overflow. It projects
25 hours to next morning's source arrival, with no future forcing knowledge.
The familiar reactive fallback and one three-hour trip per day remain shared.

After common preconditioning, 28 isolated/coupled branches tested midday,
evening, shifted and zero-extra-loss histories plus bounded slope/memory
sensitivity. In the primary coupled comparison, anticipation reached the
energy boundary earlier under midday warmth (day 61 versus 73), later under
evening warmth (79 versus 76), and did not improve the shifted case. All
primary water minima exceeded 25.6 kg; these were energy limits, not mortality.

The explanation is conditional: early top-ups can buy smaller refills at the
same fixed travel cost and alter later reactive trips and feeding opportunities.
Accept the experiment, not a claim that anticipation always helps. Keep the
reactive null and the fallible candidate; do not tune failures away.

For this layer, start with `experiments/temperature-anticipatory-drinking.R`,
`temperature-hydration-fixtures.R`, and `hydration-hourly-transition.R` (all
under `experiments/`). The last composes existing public hourly transitions;
it avoids the older planner's full hypothetical no-trip day, whose later
invalidity could prevent an earlier feasible intervention. Package physiology
was unchanged. Compare terminal runs over common completed hours, keep valid
partial days, and distinguish completed refills from trips still in progress.

## Next Proposal: Goal 059

**Cost-aware drinking decisions**, not yet authorized. First distinguish trip
frequency costs from feeding displacement, then evaluate one lean rule that
considers refill size and feeding opportunity using current state and past
experience only. Retain both existing comparators and hold physiology and
environmental contrasts fixed. Freeze the information and safety boundaries
before generating decisive results. The completed tranche should deliver the
comparison, bounded sensitivity, interpretable figures, and independent review.
A defensible benefit/failure boundary or clear rejection is the endpoint;
guaranteed energetic rescue is not. No Goal 059 packet or implementation exists.

Recover this proposal with Barry rather than restarting a long parameter-by-
parameter approval conversation. Do not assume Goal 058's publication authority
automatically authorizes new science or publication in Goal 059.

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

Goal 058 passed all 27 retained diagnostics, full tests, independent review, and
external package build/check with no errors, warnings or notes. This is a
dated verification, not a reason to rerun the whole suite during bootstrap.
Use targeted checks for changes and the repo's explicit release gate when due.
Use `Rscript --vanilla` with the intended installed package/library; repository
startup previously hid a temporary test installation. Follow current runtime
instructions rather than depending on old `/tmp` paths.

Generated evidence is ignored, not committed. Retained figures and results from
the retired worktrees were consolidated into this checkout's `outputs/`, with
file contents verified unchanged. The Goal 058 result cache, figures, rendering
script and validation logs are now at:

`/Users/bwbrook/git/herbivoreTTR/outputs/goal-058/`

Useful figures are `energy-trajectories.png` and `hydration-mechanisms.png`.
Do not delete retained evidence as part of orientation. The old worktree paths
no longer exist, and disposable Goal 058 build/library directories were removed.
Scientific decisions belong in `docs/decisions/`; current contracts belong in
model docs. Use proportionate planning, not a mandatory four-file goal template
or the retired management workflow. Git preserves development history; this
note is your short route back to the live scientific question.
