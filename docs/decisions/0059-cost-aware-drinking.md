# Decision 0059: Cost-Aware Drinking

Date: 2026-09-06

Status: comparison accepted; cost-aware candidate retained for diagnosis,
not promoted over reactive drinking

## Question And Scope

Can a cost-aware gate on an optional morning top-up reduce the energetic cost
of hydration while preserving the accepted observed-thirst response?

Barry authorized Goal 059 on 2026-09-06. The starting source is `dcc5d1b`.
The endpoint is an attributable benefit/failure boundary or rejection of one
lean candidate, with bounded sensitivity and independent review. Benefit is
a scientific prediction, not an acceptance test. Package physiology, the
food-choice rule, source availability, actual route expenditure, and the
Goal 058 temperature histories remain fixed in the policy comparison.

The reactive and original anticipatory policies remain separate comparators.
The new rule can decline a premature top-up; it cannot defer an observed-thirst
trip. The threshold remains 26 kg, the reported critical boundary 24 kg, and
the limit one three-hour source trip per day. The existing midnight convention,
late deferral, partial-day retention, and negative-energy stop remain intact.
These constraints do not guarantee identical water minima after paths diverge.

## Frozen Candidate

At 08:00, use current body water `W` and the preceding completed `m` hours:

```text
d = max(0, mean(ordinary loss + extra loss - food water))
v = sum(realized ingested energy) / sum(stationary food opportunities)
```

The default memory window is 24 h. Drinking and overflow do not enter `d`;
travel and source stays do not count as food opportunities. Both estimates
are seeded by actual common preconditioning and subsequently updated from
the candidate's own completed hours. Exact historical physiological fluxes
are the existing synthetic information assumption, not demonstrated perception.

Only consider an optional top-up when the original precautionary projection
`W - 25*d < 26` holds and observed thirst has not already mandated departure.
With positive draw, predict the first threshold crossing after
`q = ceiling((W - 26)/d)` hours. From the current 08:00 decision:

Ratios within floating-point roundoff of a whole hour are snapped to that hour
before taking the ceiling; binary representation must not add an entire hour.

- If `q` is 14, 15, or 16, the predicted crossing is at 22:00, 23:00, or
  midnight; the frozen reactive convention departs next morning, delay 24 h.
- Otherwise departure delay `t = q`, including a first crossing after a
  non-thirsty midnight. This uses the known response convention, not future
  simulated states or the forcing calendar.

Predict refill through the end of the drinking interval (two hours after
departure), with normal stock `N = 28 kg`:

```text
R_now   = min(10, N - W + 2*d)
R_later = min(10, N - W + (t + 2)*d)
K_now   = (C + a*v*F_now) / R_now
K_later = (C + a*v*F_later) / R_later
```

The 10 kg cap is the familiar one-hour drinking capacity. `C = 1800 kJ` is
the familiar round-trip expenditure. `F` counts open feeding
opportunities in the three trip hours under the known repeating feeding
schedule; `F_now = 0` at 08:00. `a = 1` is the default opportunity-value
multiplier. Depart early only if `K_now < K_later`; equality within floating-
point roundoff retains reactive
fallback. Missing experience, no positive draw, or no anticipated threshold
crossing also retains fallback.

The ratios are estimated cost per kilogram of refill, not a full-model
optimum. Constant net draw neglects its within-day pattern and the food-water
lost during travel; the same approximation is used for both predicted refills.
Recent intake values a lost opportunity but cannot predict later compensation,
patch persistence, or the next food-patch move. Neither future temperatures nor
unvisited biomass are inputs. The rule and its sensitivity set will not be
retuned after viewing new trajectories.

## Attribution Before Policy Comparison

First reconstruct the existing Goal 058 common-hour energy differences as
additional intake minus additional water-route expenditure minus additional
food-route expenditure. Report water-trip feeding opportunities separately:
their count alone does not identify realized lost intake.

An independent design challenge supported this ratio rule and identified the
overnight convention and discrete-hour decision margins as key risks. Its
retrospective screen used only inherited Goal 058 events, not new candidate
trajectories. The declared opportunity-value sensitivity addresses that risk;
the scenarios are familiar, not held-out evidence.

Then use five isolated one-day prescribed paths from one opening state:
no trip, and 08:00 or 16:00 trips crossed with zero or the actual 1800 kJ
round-trip cost. Zero cost is solely an attribution intervention. All trips
retain their three hours and feeding interruption. This small factorial
distinguishes direct expenditure, feeding displacement, and appetite-mediated
compensation; it does not set parameters for the candidate.

## Decisive Experiment And Sensitivity

Use the same two systems, 60-day reactive preconditioning, and 126-day branch
histories as Goal 058: no extra loss, midday warmth, evening warmth, and an
unannounced midday-to-evening shift after day 42; recovery begins after day 84.
Compare all three policies in both systems: 24 primary branches.

For coupled midday and shifted histories only, retain the following one-factor
sensitivity, reusing identical comparator runs:

- Evaporation slope multipliers 0.5 and 1.5, all three policies: 12 branches.
- Candidate memory windows 12 and 48 h: four branches.
- Candidate opportunity-value multipliers 0.5 and 1.5: four branches.

Total: 44 distinct branch runs plus two common preconditions. These are
prospectively specified new policy trajectories on previously examined
synthetic histories, not held-out environments or empirical validation.

Report policy completion/boundary times and full-run minimum water. For each
three-policy contrast use the last hour all three actually completed for
energy, intake, route costs, feeding opportunities, and refill comparisons.
Report completed refills separately from trips still in progress; charge only
realized movement. Preserve actual valid partial days and identify whether
recovery was reached. Record 08:00 decision margins and rejected top-ups.

## Acceptance And Stop

Require hand-calculable decision probes (including ties and overnight timing),
causal prefix identity under altered unseen forcing, correct observed-thirst
priority, conserved energy/water/forage, common initial states, and exact
preservation of the two existing policies. Independent review must challenge
the cost estimate, information boundary, counterfactual attribution, and
headline interpretation using the actual results and source.

Retain one no-write diagnostic, lean shared behavior, compact tables and
figures under ignored `outputs/goal-059/`, and the accepted conclusion here.
Stop after one focused review/repair pass once benefits and failures are
attributable. Thermal physiology, feeding rescheduling, new sources, lower
thirst thresholds, empirical calibration, mortality, and further policy
search remain outside this tranche.

## Results And Interpretation

The frozen experiment completed all 44 branch runs. No policy parameter was
retuned after observing those trajectories. The cost-aware gate filters most
of the excess primary trip starts produced by the original top-up rule, but
its energetic advantage over reactive drinking is conditional and reverses
within the declared sensitivity set. Reactive drinking remains the default.

### Attribution Controls

The five prescribed isolated days give the following results from one common
opening state. Energy is body plus gut; changes and intake are rounded to kJ.

| Departure | Route cost (kJ) | Trip overlap with feeding (h) | Intake (kJ) | Energy change (kJ) |
| --- | ---: | ---: | ---: | ---: |
| No trip | 0 | 0 | 3,200 | 0 |
| 08:00 | 0 | 0 | 3,200 | 0 |
| 16:00 | 0 | 3 | 2,780 | -420 |
| 08:00 | 1,800 | 0 | 3,600 | -1,400 |
| 16:00 | 1,800 | 3 | 2,850 | -2,150 |

Three foregone opportunities do not imply 600 kJ of realized lost intake.
Appetite partly compensates, and that compensation interacts with expenditure
and trip timing. Thus recent average food return remains a heuristic value,
not an identified marginal cost. It was not adjusted using these controls.

All carried contrasts close the exact whole-animal identity:

```text
change in body-plus-gut energy advantage
  = intake difference - water-route cost difference - food-route cost difference
```

Maintenance and prescribed activity are equal at common horizons. This
accounting decomposition identifies realized flux differences, not causal
mediation by particular missed meals: intake also reflects later compensation,
forage depletion, and patch choices.

### Primary Coupled Comparison

The terminal entries below identify the attempted hourly transition rejected
for negative body energy. Valid preceding hours, including partial days, are
retained. Energy advantages use the last hour all three policies completed
within each history, with common initial stocks. Positive values favour the
cost-aware candidate.

| History | Reactive terminal | Original top-up terminal | Cost-aware terminal | Common hours | Cost-aware minus reactive energy (kJ) | Cost-aware minus original top-up energy (kJ) |
| --- | --- | --- | --- | ---: | ---: | ---: |
| No added heat | Completes 126 d | Completes 126 d | Completes 126 d | 3,024 | 0 | +171 |
| Midday warmth | Day 73, 15:00 | Day 61, 18:00 | Day 72, 15:00 | 1,458 | -1,158 | +6,756 |
| Evening warmth | Day 76, 10:00 | Day 79, 14:00 | Day 78, 17:00 | 1,810 | +1,073 | -3,200 |
| Phase shift | Day 70, 18:00 | Day 69, 08:00 | Day 72, 17:00 | 1,640 | +2,166 | +3,706 |

Here energy is body plus gut. The corresponding cost-aware minus reactive
body-reserve contrasts are 0, -1,509, +1,076, and +2,166 kJ. The cost-aware
null trajectory is physically identical to reactive drinking.

In midday warmth, the cost-aware rule restores 85% of the original top-up
rule's 7,914 kJ deficit relative to reactive drinking at 1,458 h. Trip starts
are 21, 25, and 21 for reactive, original top-up, and cost-aware policies;
mean completed refills are 2.310, 1.866, and 2.286 kg. Yet the candidate still
ends 1,158 kJ below reactive and reaches the energy boundary one day earlier.
It is a substantial repair relative to the original candidate, not a midday
improvement over the reactive null.

In the shifted history, trip starts are 23, 26, and 23 and mean completed
refills are 2.283, 1.899, and 2.205 kg. Relative to reactive, the primary
candidate gains 2,166 kJ through increased intake with equal realized movement
cost. Its trips overlap 33 feeding hours versus 45 for reactive. Relative to
the original top-up, it gains 3,706 kJ despite 1,694 kJ less intake because
water-route expenditure is 5,400 kJ lower.

Trip-start counts alone do not determine expenditure at a truncated horizon.
The midday and evening cost-aware minus reactive contrasts each include
900 kJ of additional realized water travel because one policy has a pending
return leg at the common endpoint. Their intake differences are -258 and
+1,973 kJ, respectively; subtracting the 900 kJ gives -1,158 and +1,073 kJ.
All primary coupled food-route cost differences are zero.

The default candidate accepts only one of 24 eligible precautionary decisions
in midday warmth, two of ten in evening warmth, two of 19 in the shifted
history, and none of one under no added heat. These are full-run counts;
rejected events are not proven individually wasteful counterfactuals.

All 12 primary isolated branches complete treatment and recovery. All nine
warm primary coupled branches reach the energy boundary before recovery;
minimum body water remains above 25.6 kg. These outcomes establish neither
mortality nor long-term biological recovery.

### Sensitivity And Decision Boundary

The table gives cost-aware minus reactive body-plus-gut energy in kJ at each
row's common three-policy horizon. Only the named axis changes from the
primary setting. Horizons differ across settings, so the table is not a
fixed-time response surface.

| Setting | Midday warmth | Phase shift |
| --- | ---: | ---: |
| Primary: 24 h memory, unit slope and opportunity value | -1,158 | +2,166 |
| Half evaporation slope | 0 | -4,144 |
| 1.5 times evaporation slope | 0 | 0 |
| 12 h memory | 0 | 0 |
| 48 h memory | -1,009 | -923 |
| Half opportunity value | 0 | 0 |
| 1.5 times opportunity value | -1,158 | +3,766 |

With half evaporation slope, all shifted runs complete 126 d. Its sign reversal
also holds when restricted to the primary 1,640 h horizon (-616 kJ), so it
cannot be explained solely by longer follow-up. At 1.5 times slope, all three
policies share the same physical path and fail on day 27 at 21:00, before the
histories diverge. That zero contrast is shared failure, not successful coping.

Both 12 h memory and half opportunity value reproduce the reactive physical
and action trajectories in the two tested histories. With 48 h memory, the
shifted candidate loses 923 kJ and reaches the boundary one hour earlier than
reactive. At 1.5 times opportunity value it gains 3,766 kJ and postpones that
boundary by 182 h. Discrete crossing times and sparse optional decisions make
these differences path dependent. There is no supported universal ranking or
validated optimal memory length.

Accept this as a bounded benefit/failure comparison. Retain all three policies
for diagnosis, stop candidate tuning, and do not promote cost-aware drinking
as the new baseline. The evidence is deterministic and synthetic on familiar
histories; the forecast's constant draw and average opportunity value remain
structural approximations.

## Verification And Retained Evidence

Hand-calculable ratio, tie, insufficient-history, and overnight-clock probes
pass, including integer crossings protected from floating-point ceiling error.
The altered-future forcing probe preserves the completed prefix and 08:00
choice; an observed-thirst probe preserves reactive priority. Independent
stock/flux reconstruction closes energy, water, and coupled forage accounts,
with exact state carry and at most one trip per day across all 44 runs.
All 24 matching old comparator run objects and both preconditions are exactly
identical to the Goal 058 cache. Package physiology and public API are unchanged.

The decisive execution produced harmless summary-binding row-name warnings.
A reporting-only correction explicitly replicates the design row before
binding three policy summaries. Rebuilding the summaries from cached runs
reproduces all 60 rows exactly; contrasts are unchanged. The original executed
source digest is preserved in the cache alongside the reporting amendment and
current digest. No physical trajectory was rerun or relabelled as rerun.

The focused closeout parsed all 78 retained R files, passed all 332 package
test expectations with no failures, warnings, or skips, and passed the diff
whitespace checks. Independent methodological review accepted closure and
rejected candidate promotion after inspecting the actual rule, information
boundary, controls, cached trajectories, sensitivity, and figure values. The
accepted interpretation incorporates its qualifications about average versus
marginal opportunity cost, pending trips, and unequal sensitivity horizons.
External package build/check is reserved for the explicit publication gate.

The retained no-write client is `experiments/cost-aware-drinking.R`, with shared
behavior in `experiments/temperature-hydration-fixtures.R`. Ignored evidence is
under `outputs/goal-059/`: cached runs, compact summaries and contrasts,
decisions, control results, frozen design, and three figures
(`energy-trajectories.png`, `hydration-mechanisms.png`, and
`policy-sensitivity.png`). Generated evidence is not part of Git.

## Next Proposed Tranche

Test one energetic-accessibility gradient: water-route expenditure multipliers
0, 0.5, 1, 1.5, and 2 with the existing one-hour legs, one-hour source stay,
three policy forms, and environmental histories. Change the actual water-route
cost and the candidate's known cost together. Keep food-route costs fixed.
The zero-cost control retains the time and feeding interruption of source
access. This distinguishes expenditure-mediated stress from temporal access
costs and tests whether policy ordering depends on the fixed 1,800 kJ route.

Call this energetic accessibility, not literal water distance: travel duration
is held constant. Freeze a compact design and stopping point upon approval;
do not add variable trip durations, forage moisture, physiology, or another
policy search simultaneously. This proposal is not implemented or authorized
by Goal 059's closeout.
