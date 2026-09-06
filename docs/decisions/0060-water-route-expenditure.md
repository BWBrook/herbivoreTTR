# Decision 0060: Water-Route Expenditure

Date: 2026-09-06

Status: comparison accepted; access-cost dependence established,
reactive default retained

## Question And Scope

Barry approved this successor to Decision 0059 on 2026-09-06. Does changing
water-access expenditure alter energetic stress and the ranking of the three
existing drinking policies? Vary one energetic-accessibility axis, not literal
distance: both movement legs remain one hour and drinking occupies one hour.
Package physiology, food-route costs, feeding hours, water yields, temperature
histories, and policy forms remain fixed. Reactive drinking remains the default.

Goal 059 is complete but uncommitted on top of `dcc5d1b`; its working source
is preserved before modification under ignored `outputs/goal-060/`. This
tranche authorizes local science and verification, not commit/push or release.

## Frozen Design

Cross isolated and coupled forage systems with four existing histories (no
added heat, midday warmth, evening warmth, and the unannounced phase shift),
five water-route expenditure multipliers (0, 0.5, 1, 1.5, 2), and all three
policies (reactive, original anticipatory, cost-aware): 120 branch runs.
The gradient is 0, 900, 1,800, 2,700, and 3,600 kJ per round trip. Only route
rows connected to the familiar water source change; food routes stay at
900 kJ per leg. The cost-aware controller reads its known out-and-back cost
from those same actual routes. All policies retain their original information
contracts; knowledge of a new route cost is immediate, not learned by trial.

For each system, all branches start from one common 60-day reactive
precondition at the original 900 kJ per water leg. The intervention changes
access cost at branching and holds it for all 126 branch days. Thus the
estimand is response to changed access cost from a common history, not
stationary adaptation to lifelong differences in access. No-added-heat branches
are cost-only controls. Temperature treatment lasts 84 days and is removed for
42 days; access cost is not restored during that temperature recovery period.

Use the primary temperature slope, 24 h memory and unit opportunity valuation
throughout. Retain the 26 kg thirst trigger, reported 24 kg critical boundary,
late and midnight conventions, and at most one three-hour source trip per day.
The zero-expenditure treatment retains source travel time, feeding interruption,
and water dynamics. It is not a no-trip or unconstrained-access control.
No grid refinement, policy retuning, memory search, new loss function, or
variable trip duration follows from the results.

## Outputs And Inference

Report completed hours, exact terminal transition, whether temperature recovery
was reached, full-run water and body-energy minima, trip starts, completed and
pending trips, completed refill size, overlap with feeding hours, intake,
water-route and food-route expenditure, and body and combined gut/body energy.
A negative-energy transition is a model boundary, not a mortality observation.

Compare the three policies at their last common completed hour within each
system/history/cost combination. For cross-cost energy comparisons also use
one fixed common horizon across all 15 runs within each system/history. Report
both horizons explicitly. Do not compare terminal energy stocks from unequal
follow-up or extrapolate stopped trajectories. Record end-treatment and
end-recovery stocks only where those endpoints were actually completed.

Attribute common-horizon combined-energy contrasts exactly to intake minus
water-route expenditure minus food-route expenditure. Realized intake differences
include appetite and forage feedback, not just missed feeding. Charge only
completed movement legs; report pending trips separately. Controls and rankings
are deterministic results on familiar synthetic histories, not empirical
validation or replicated uncertainty estimates. Lower expenditure is predicted to reduce energetic stress, and anticipation
may benefit some costs; neither prediction is a pass criterion. The five-point
grid can bracket completion or ranking transitions, not estimate exact
thresholds by interpolation. Systems and histories are not pooled as replicates.
Branches ending before the phase shift or heat removal cannot inform responses
to those later conditions.

Retain one no-write diagnostic, compact cached summaries and contrasts, and
figures for completed duration, common-horizon policy ranking, and energetic
attribution. The source diagnostic may use three local R workers; these modest
independent hourly branches fit the Mac mini. Generated evidence stays ignored.

## Acceptance And Stop

Before decisive execution, check that only water-route expenditure changes,
known and realized costs agree, zero-cost trips still have two spatial movement rows and take three hours, feeding
is suspended on those trips, unchanged unit-cost decisions reproduce their
predecessor, and altered unseen forcing preserves causal prefixes. Preserve
observed-thirst priority and exact state carry. Independently reconstruct
energy, water, and forage balances for all branches.

Require all 24 unit-cost primary runs and the two preconditions to reproduce
Goal 059 exactly. Share its account and summary helpers rather than sourcing
one diagnostic from another. Parse retained R, run affected checks and package
tests, and check the diff. Independent review must challenge initialization,
comparison horizons, zero-cost interpretation, realized versus known route
costs, and headline rankings. Stop at a defensible cost-dependence result or
clear rejection, after one focused repair pass. Do not add the next mechanism
or run an external release gate without its corresponding authority.

## Results

All 120 frozen branches completed execution. The 24 unit-cost primary run
objects and both common preconditions exactly reproduce Goal 059. No policy,
parameter, history, or sampled cost was retuned. Water-route expenditure has a
large effect on encountering the energy boundary, while policy ranking remains
conditional on temperature timing, cost, and comparison horizon.

### Completion And Energy Boundaries

The coupled system gives the following terminal days, in the order
**reactive / original anticipatory / cost-aware**. “Complete” means all three
policies finish 126 branch days. Terminal day is the day containing the first
rejected negative-energy transition; exact hours remain in the summaries.

| Water cost multiplier | No added heat | Midday warmth | Evening warmth | Shifted history |
| ---: | --- | --- | --- | --- |
| 0 | Complete | Complete | Complete | Complete |
| 0.5 | Complete | Complete | Complete | Complete |
| 1 | Complete | 73 / 61 / 72 | 76 / 79 / 78 | 70 / 69 / 72 |
| 1.5 | Complete | 35 / 29 / 31 | 35 / 56 / 46 | 35 / 29 / 31 |
| 2 | 85 / 85 / 85 | 26 / 22 / 26 | 26 / 28 / 28 | 26 / 22 / 26 |

At half the inherited cost, every coupled branch completes treatment and the
42 days after heat removal. At the inherited cost or above, every heated
coupled branch stops before heat removal. Doubling expenditure makes even the
cost-only, no-added-heat branches fail on day 85 (16:00 for original anticipation,
18:00 for the other two). This identifies a strong dependence on the inherited
route expenditure, which cannot be treated as an innocuous background constant.

The five-point grid brackets the sampled heated-coupled completion transition
between multipliers 0.5 and 1, and the no-added-heat transition between 1.5 and
2. It does not identify an exact critical expenditure or guarantee monotonicity
between sampled points. At costs 1.5 and 2, shifted coupled histories stop
before day 43; their identity with midday results supplies no evidence about
response to the later phase shift.

All isolated runs complete through cost 1.5. At cost 2, eight of nine heated
isolated runs stop: reactive and cost-aware on day 69 in midday warmth and day
66 in the shifted history; original anticipation stops on days 50 and 55.
In evening warmth, reactive and cost-aware stop on day 78 at 16:00, while
original anticipation completes 126 days. Thus original anticipation retains
one distinct benefit that the cost-aware heuristic misses. All isolated
no-added-heat runs complete at every sampled cost.

Across both systems, every termination is a rejected negative-body-energy
transition. Minimum water across the whole grid is 25.646 kg, above the 24 kg
reported critical boundary. Completion here is an observed finite model
horizon, not stationary balance or biological recovery.

### Why Cost Matters, And Why Energy Is Not Universally Monotone

For coupled reactive drinking, the common across-cost horizons are 2,032 h
without added heat, 514 h for midday and shifted histories, and 615 h for
evening warmth. The latter two heated horizons precede the phase shift. At
these early heated horizons, changing route cost leaves cumulative intake and
food-route expenditure identical across costs: all combined-energy differences
are exactly the changed water-route expenditure.

Relative to unit cost, half cost gains 6,300 kJ by 514 h in the midday/shifted
histories and 7,200 kJ by 615 h in evening warmth. Zero cost gains 12,600 and
14,400 kJ; double cost loses those same amounts. This is a direct expenditure
contrast over that common early window, not a claim that later food or water
trajectories remain identical. The shifted panel at 514 h cannot inform the
unannounced change on day 43.

Over longer periods, expenditure also changes appetite and forage history.
At the no-added-heat common horizon, removing coupled reactive water-route
cost saves 21,600 kJ of water movement and 900 kJ of food movement, but intake
falls by 10,195 kJ; combined energy therefore rises by 12,305 kJ. The realized
intake term includes compensation and coupled feedback, not simply missed meals.

Even lower cost need not raise combined energy at every finite checkpoint.
In isolated no-added-heat reactive runs at 126 d, half cost yields 558 kJ less
combined energy than unit cost: intake is 21,258 kJ lower while water-route
expenditure is 20,700 kJ lower. Both complete the horizon. The supported broad
pattern is avoidance or delay of energy-boundary encounters at lower sampled
costs, with potentially nonmonotone stock responses under appetite feedback.

Zero cost still entails 987 completed trips across its 24 branches, each with
two moves and three hours unavailable for feeding, zero water-route energy
expenditure, and zero intake during the trip. Its favourable completion result
does not demonstrate that the temporal or hydration costs of access vanish.

### Policy Ranking

For the coupled system, cost-aware minus reactive combined-energy differences
(kJ) at each cost's
common three-policy horizon are:

| Cost multiplier | Midday warmth | Evening warmth | Shifted history |
| ---: | ---: | ---: | ---: |
| 0 | 0 | +2 | 0 |
| 0.5 | -6,166 | +4,804 | +2,740 |
| 1 | -1,158 | +1,073 | +2,166 |
| 1.5 | -2,937 | +3,444 | -2,937 |
| 2 | 0 | -800 | 0 |

These rows have unequal follow-up, explicitly retained in `summaries.csv` and
`contrasts.csv`. The across-cost figures additionally use a fixed horizon
within each system/history. No sign in this table establishes a universal
policy ordering. At half cost, all runs finish 126 d, yet the cost-aware midday
candidate still loses 6,166 kJ relative to reactive. In evening warmth it gains
4,804 kJ, and in the shifted case 2,740 kJ. Its improvement over the original
candidate is also not uniform: in half-cost midday warmth it ends 514 kJ below
the original top-up rule.

At 1.5 cost under evening warmth, original anticipation lasts 1,320 h,
cost-aware 1,097 h, and reactive 831 h. Their common-hour energy advantages
relative to reactive are 4,944 and 3,444 kJ. At double cost, both anticipatory
policies last 648 h versus reactive's 615 h, despite being 800 kJ below reactive
in combined energy at that common hour. Combined stock and the time of a
body-reserve boundary are distinct outcomes because gut release, subsequent
intake, and trip timing matter. Retain both rather than forcing one score to
stand for the other.

Accept the energetic-accessibility comparison and retain all three policies
for diagnosis. Reactive drinking remains the default. The cost-aware rule is
neither an optimizer nor a consistently better substitute for the original
anticipatory rule. No further policy tuning is justified by this grid alone.

## Verification And Evidence

The source changes only source-connected route expenditure, passes known
round-trip cost from the same route records to the candidate, and preserves
food-route expenditure and all trip durations. It uses stored trip origin when
an 08:00 diagnostic occurs during a prior reactive trip. All 120 initial
physical states match their common precondition, all completed trips retain
two moves and three unavailable hours, and realized cost agrees with the
assigned multiplier. Altered-future prefix and observed-thirst priority probes
pass at the declared cost extremes.

Independent reconstruction closes energy, water, and forage accounts and
checks state carry. Shared account and summary helper bodies are unchanged
from Goal 059; moving them to the fixture avoids sourcing a diagnostic from
another diagnostic. Exact equality of all 24 unit-cost run objects includes
hourly actions, decision tables, daily summaries, terminal records, and carried
contexts. Both common preconditions are exactly unchanged.

The closeout parsed 79 retained R files, passed all 332 package-test expectations
without failures, warnings, or skips, and checked whitespace. Independent
methodological review reconstructed the cached summaries, horizons, balances,
and contrasts and challenged the initialization, zero-cost meaning, ranking,
and interpretation. A post-execution removal of one blank EOF line changed no
R expression; the cache preserves executed-source digests and records the
whitespace amendment. No scientific rerun or grid extension followed the results. Review accepted
closure with no blocking scientific defect and retained the reactive default.
Figure review corrected an inapplicable heat guide on energy axes and made
policy-ranking scales common within each system before final inspection.

The retained no-write client is `experiments/water-route-expenditure.R`.
Ignored `outputs/goal-060/` contains the frozen design, predecessor source,
120 cached runs, compact summaries and contrasts, verification logs, and
three figures: `completed-duration.png`, `policy-ranking.png`, and
`energy-attribution.png`. The 120 branches ran with three local R workers in
about 168 seconds. Package physiology and public API are unchanged. No external
release gate, commit, or push was performed under this scientific authorization.

## Next Proposed Tranche

Vary water-trip duration while holding total round-trip expenditure fixed.
This is the complementary temporal-access question: how much energetic stress
comes from time unavailable for feeding and delayed drinking, once the direct
expenditure effect is controlled? Retain the reactive and two anticipatory
comparators, explicit hourly timing, and conserved ledgers. Their forecasts
must use the actual declared travel and drinking durations without tuning the
policy score from new outcomes.

Unlike this cost-only intervention, longer travel changes feasibility of a
within-day excursion and the precautionary horizon. Freeze those information,
late-departure, and day-boundary conventions before running decisive trajectories.
This requires a separately approved contract; no variable-duration behavior,
new source, feeding rescheduling, or physiology is implemented in Goal 060.

## Publication Closeout

On 2026-09-06 Barry authorized committing and pushing the accepted Goals 059
and 060, followed by a pause for broader scientific reflection. The publication
gate passed full package tests and external `R CMD build` and
`R CMD check --no-manual` with Status OK and no errors, warnings, or notes.
Generated evidence remains ignored. The duration experiment above remains a
candidate direction; no further scientific implementation is authorized.
