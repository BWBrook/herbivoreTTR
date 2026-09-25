# 0062 — Physical feeding support, access controls and recovery

2026-09-08. Accept the physical feeding representation and the completed
counterfactual study at their synthetic scope. The experienced rule remains a
diagnostic; it is not promoted as calibrated herbivore behaviour. The
[specification](../feeding-access-specification.md) preserves the original
53-branch design and the separately declared two-branch follow-up.

## Main finding

A feasible animal trajectory exists under pooled-stock access in every tested
sustained-forcing case, while the physical and other encounter-limited cases
reach the energy-reserve boundary. Total available biomass alone therefore
does not explain these failures. Encounter rate, information, grazing
allocation and travel jointly govern the outcomes. These models do not provide
an additive decomposition of those mechanisms or prove an optimal policy.

Eight physical 100-m² feeding blocks occupy .08 ha in a 100 x 100 m domain.
The same blocks, stations and search footprints persist across numerical
subdivision. A .6-m²/h effective search coefficient reproduces the inherited
acquisition curve throughout the usable appetite range. The three constructed
layouts differ in block placement; they are examples, not replicated estimates
of a general fragmentation effect.

## Original frozen study

Eighteen primary branches cross three layouts, three growth profiles and two
water-access settings under the experienced rule. Twelve sustained-forcing
policy branches, eighteen access controls, four refinements and one boundary
control bring the total to 53. Policies and controls branch from identical
complete day-60 states within each layout/grid/topology. Area and configuration
are present from day 1; their histories are not matched interventions at day 61.

| Model / growth profile | Observed result |
| --- | --- |
| Experienced, unchanged growth, continuous layout | Both water settings complete day 228. |
| Experienced, unchanged growth, clustered/fragmented layouts | Near-water exits on days 197/194; far-water exits on days 172/170. |
| Experienced, 28-day growth pulse | All six branches exit: days 116–118 near water; 103–106 far water. Growth had already returned to baseline on day 89. |
| Experienced, sustained reduction | Exits on days 108–109 near water; 101–102 far water. |
| Informed, sustained reduction | Exits on days 142–144 near water; 133–134 far water. |
| Cyclic, sustained reduction | Exits on days 141–144 near water; 132–135 far water. |
| Zero forage transit, sustained reduction | Exits on days 106–107 near water; 100–101 far water. |
| Pooled search, sustained reduction | Exits on days 145–146 near water; day 134 far water. |
| Pooled stock, sustained reduction | All six branches complete day 228. |

Exit means the first hourly body-energy proposal below zero; that transition
is not committed. It is a model-domain boundary, not a mortality prediction.
Only eight original branches complete: two undisturbed continuous-layout
branches and all six pooled-stock controls. Water remains above 25.87 kg across
the main study, above the declared 24-kg interpretation boundary.

The pooled-stock controls retain plant dynamics, physiological appetite and
water excursions but allow intake from total accessible stock without an
encounter-rate ceiling or forage transit. They finish within 45 kJ of their
own day-60 reserve, with about 19.6–21.5 kg of accessible forage remaining.
Their completed trajectories constructively establish feasibility under this
counterfactual; they do not establish feasibility under physical search.

The analytical accessible-supply bound includes the maximum positive net
plant production above the residual, as well as the physiological intake cap.
It remains positive over the tested horizons and cannot certify insufficiency.
Positive upper bounds are inconclusive. Every observed prefix satisfies the
plant-harvest, intake and combined-energy bounds separately. A no-growth
365-day diagnostic produces a negative bound, checking the impossibility
screen without treating it as another main-study scenario.

## What can and cannot be attributed

Within sustained cases, the experienced animal feeds at four of eight stations
after branching, whereas the informed comparator reaches all eight. The
latter delays the boundary by roughly a month. This identifies a substantial
policy/information contribution under the declared physical rules. It does not
show that current knowledge alone guarantees persistence: the informed rule
also exits and is not an optimum.

Zero transit changes the rule's choices because it knows that movement has
become free. It visits only three stations in the sampled sustained controls
and can exit earlier than the physical experienced rule. Its result is not a
pure subtraction of travel expenditure. Pooled search samples whole-area mean
accessible density, which can be lower than the best local block; it is a
uniform-mixing counterfactual, not an upper envelope on physical access.
Pooled stock changes removal distribution and therefore plant renewal as well
as access. These controls are not nested in a way that supports adding their
effects or assigning a unique percentage to each mechanism.

The two-day last-to-best memory is explicitly optimistic about regeneration;
its reward estimates and deterministic tie handling can keep the animal
revisiting part of the landscape. Requiring an expected improvement prevents
forced moves to an inferior expected destination, but does not make those
expectations accurate. The result argues for empirical scrutiny of encounter
and reward-memory scales, not automatic promotion of a more complex rule.

## Exploratory short-pulse follow-up

After all original runs were complete, a single follow-up was frozen: reduce
growth for seven days in the continuous layout, using both water settings and
the same cached baseline/model. This tests a shorter disturbance against a
physical baseline that completes. It is adaptive exploratory evidence and
must remain labelled separately; no subsequent duration search was performed.

The near-water branch completes day 228 but does not recover condition at that
endpoint: 31,401 kJ, 8,545 kJ below day 60, with a final 28-day trend of
-312 kJ/day. It had returned to about 39,995 kJ by day 75 and remained near the
reference at several intermediate checkpoints. Apparent early recovery thus
preceded later decline. Accessible forage still totals 41.3 kg at day 228.
The far-water branch exits on day 143, hour 18. These are path-dependent
outcomes in a deterministic policy/plant model, not a fitted disturbance
threshold or a general ecological tipping point.

## Representation and verification

The homogeneous 1/2/4-per-axis refinements preserve whole hourly paths,
including stations, departures, travel and domain-exit hour. The largest
4x4-versus-unsplit differences found by independent review are approximately
2.3e-11 kJ in body energy, 2.2e-13 kg DM in landscape forage and 3.1e-17 kg DM
in intake/encounter capacity. The fixed half-block heterogeneous field also
passes the 2/4/8 refinement check. These are equivalent subdivisions of the
same declared mixed feeding supports; they do not validate arbitrary partial
footprints or cell-averaging of unresolved nonlinear heterogeneity.

Conservation residual maxima are 3.8e-13 kg DM, 3.7e-12 kJ and 3.2e-15 kg water.
The abundant stationary animal reduction, fractional feeding, memory contracts,
atomic domain exits and same-state branching pass. Independent review checked
the implemented geometry, controls and summaries. Its two requested repairs
were applied: direct prefix intake-bound assertions and explicit non-nesting
of access controls. No result-changing repair or parameter rescue was needed.

The retained scripts write nothing unless an explicit output path is supplied.
Generated ledgers, summaries and figures are in ignored
`outputs/feeding-access-062/`. The main three-page figure and separate follow-up
figure make the design distinction visible. The full package test suite and
external `R CMD build` / `R CMD check --no-manual` passed on 2026-09-08 with
Status OK and no errors, warnings or notes. Retained R parses and whitespace
checks pass. The scientific source remains uncommitted.

## Stopping point

This programme resolves the numerical support ambiguity and establishes that
encounter and behavioural feedbacks can produce reserve failure despite a
feasible pooled-stock trajectory. It does not settle the biological encounter
coefficient or the animal's knowledge of renewal. The next substantive step
should ground those physical and information scales in an empirical case,
using Barry's recovered examples if available. Additional animal physiology,
TTR plant pools and demographic consequences remain separate decisions.
