# Feeding support and access specification (062)

Approved by Barry Brook on 2026-09-08: implement physical feeding support,
attribution controls, and a habitat-configuration/recovery study as one
programme, including independent review. This document freezes the main design
before execution. The prior 061 source and accepted results are preserved.
No commit, push, species calibration or new physiology is included.

## Physical support and numerical representation

The rectangular domain is 100 x 100 m. Eight fixed, nonoverlapping 10 x 10 m
vegetated blocks provide .08 ha total vegetation. Each block has a fixed
feeding station at its centre and a 10 x 10 m feeding/search footprint. The
matrix is traversable but has no forage. Configurations have identical block
areas, plant parameters and food composition:

- continuous: centres x=35,45,55,65 and y=45,55 (one contiguous rectangle);
- clustered: centres x=15,25,75,85 and y=45,55 (two separated groups);
- fragmented: centres x=10,35,65,90 and y=15,85 (eight separated blocks).

Station order is increasing y, then x. The focal animal starts at station 1.
The primary boundary is bounded Euclidean geometry; a periodic diagnostic
checks the fragmented severe/far case. There are no barriers or pathfinding.
Forage transit is 40 m/h and adds 1 kJ/m. Within-footprint search is represented
by an effective area of .6 m² per feeding hour; its energetic cost remains in
the existing routine feeding expenditure, with no additional debit.

For accessible density max(B-200,0), footprint-accessible mass is the integral
over the footprint. The encounter ceiling equals that mass times
min(search_area_rate * feeding_time / footprint_area, 1). Realized intake is
bounded by this ceiling and the unchanged appetite target. Removal is shared
among overlapping cells in proportion to their accessible mass. This assumes
mixing within a feeding footprint; repeated hourly search need not cover virgin
ground. It does not resolve bite paths, sensory detection or within-block
travel. It replaces unsupported access to an entire named patch with an
explicit area-based encounter constraint.

Each fixed block is numerically subdivided 1, 2 or 4 times per axis. Station
centres, footprint geometry, paths, total habitat and search rate do not change.
The primary field is homogeneous within blocks (K=2000 kg DM/ha), so equivalent
subdivisions should agree to floating-point precision. An additional heterogeneous
control resolves fixed left/right half-block K=1600/2400 at 2,4,8 subdivisions;
this tests refinement of the same nonlinear physical field, not replacing a
mixed field by its average. Initial B=K/2; r=.002/h and s=.001/h are unchanged.
Exact autonomous plant growth precedes conservative grazing each hour.

## Information and decisions

New forage departures are considered at day opening; existing journeys finish
first. Water takes priority, and journeys can cross hours/days. All candidate
policies use this same decision clock, a two-day (32 feeding-hour) comparison
horizon, known station geometry, and the same physical transitions. This is
not an exact replay of 061's hourly cyclic policy.

The primary experienced rule carries last and best realized feeding return per
station, last observation time, and accumulated shortfall during its current
residence. All stations are declared familiar initially, with synthetic prior
last/best returns of 200/250 kJ per feeding hour. Expected unvisited return
rises linearly from last to best over two absent days, following Decision 0054.
Current return >=200 kJ/h is adequate and triggers staying. Otherwise, a move
requires strictly higher expected destination return AND positive two-day net
advantage after known travel time/cost and accumulated local shortfall. Shortfall
can accelerate a promising move, but cannot make an inferior expected destination
acceptable. Ties retain the current station. Realized food intake divided by
actual feeding opportunity updates observations, excluding water and transit.
No simulator biomass, plant forcing or future state enters this memory policy.

The cyclic diagnostic leaves inadequate current forage for the next station.
The informed diagnostic uses current footprint encounter capacity in place of
remembered return, with the same adequacy and comparison structure. Neither is
an optimal strategy. Initial common baseline is always the experienced rule;
policies branch only after day 60, carrying the exact same complete state within
each map. After branching the assigned policy persists through recovery.

Animal gut/body energy and water remain hourly and unchanged. Effective food
water is 3.28 kg/kg DM, ordinary loss 1.56 kg/day, normal water 28 kg, reactive
threshold 26 kg, critical interpretation boundary 24 kg. At most one water
excursion begins per day. The source is encountered halfway through a prescribed
round trip, which returns to its departure station. The existing hourly drinking
account convention is retained.

## Frozen comparisons

Every run comprises 60 baseline days and 168 subsequent days, to day 228.
Growth profiles: none (f=1 throughout); pulse (f=.6 on days61-88); sustained
(f=.6 on days61-144). Water during days61-144 is near (.5 h,0 kJ per round trip)
or far (3 h,900 kJ); baseline and days145-228 use near water. Geometry is an
enduring factor from day1. Growth and water branches share complete baseline
state within map; geometry contrasts include their different baseline histories.

Primary: 3 configurations x 3 growth profiles x 2 water settings under the
experienced rule (18 branches). Diagnostics: informed and cyclic policies in
all six sustained cases (12). In those same six cases, three access controls
branch from the common baseline (18):

- zero forage transit: experienced decisions know zero forage time and cost;
  footprints and encounter limits remain;
- pooled search: no forage transit or station choice; search samples the whole
  vegetated area at the same .6 m²/h effective rate, preserving the density-based
  encounter limit;
- pooled stock: no forage transit or encounter-rate ceiling; intake is limited
  by appetite and total accessible mass, removing proportionately from accessible
  biomass. Plant dynamics and water journeys still operate.

These counterfactual access models are not optimal-policy proofs. Pooled search
samples mean density and can offer less food than the best local block. Zero
transit changes choices as well as realized costs, so it is not a pure travel
component subtraction. Pooled stock also changes grazing distribution and
subsequent renewal.
Their relaxations persist after day60. Water constraints remain identical.
A separate analytical upper bound on accessible supply will distinguish any
certified insufficiency from failure of a particular control or policy.

Resolution: repeat continuous and fragmented experienced sustained/far cases
with 2 and4 subdivisions (four branches). Also run the fragmented sustained/far
periodic diagnostic. Primary total: 53 branches. The heterogeneous refinement
control is a separate short diagnostic, not additional main-study evidence.

## Endpoints, review and stop

Primary endpoints are energy and water on shared elapsed horizons, first
infeasible reserve transition, total intake, plant production/senescence,
accessible biomass, and separately accumulated search opportunity, forage
travel, water travel and expenditure. Day88 is the common early checkpoint;
day144 is the scheduled end of sustained forcing; day228 is final recovery.
A missing endpoint remains missing when the run exits beforehand. No averaging
across unequal observed horizons is treated as a matched effect.

Recovery is final reserve relative to the same branch's day60 state; also
report the last28-day reserve trend for complete runs. Report plant recovery
separately from animal recovery. No physiological death/viability claim is made.
The hypothesis is that configuration/access matters most near declining
encounter returns; outcomes need not have that direction to pass validation.

Acceptance: independent mass/energy/water closure, reduction to the stationary
animal reference with abundant encounters, no forced inferior move, exact
same-state branching, and equivalent-grid stock/intake/travel/condition agreement
(relative tolerance1e-8, allowing absolute1e-7 kJ for energy). Plot the physical
maps and condition/forage/travel contrasts. Review the analytical supply bound
and interpretation independently; correct material defects and stop. Parameters
will not be retuned to obtain recovery or a preferred policy ranking. Record
any necessary pre-main-run pilot amendment explicitly.

## Pre-execution methodological refinement

Before any main run, independent review changed the provisional effective
search coefficient from .5 to .6 m²/h. This preserves 061's low-density
acquisition slope (.00006 kg DM/h per kg DM/ha of accessible density). Above
.025 kg DM/h the animal's appetite cap binds, so the missing old .030 ceiling
does not change realized acquisition under the accepted physiology. This is
a continuity constraint, not fitting to new outcomes.

The three layouts are specific deterministic examples. With whole-block mixed
footprints they chiefly change inter-station travel distances/order; no general
fragmentation law, configuration-class average, or within-block edge effect
will be claimed. Fixed left/right heterogeneous fields are resolved on all
2/4/8 meshes; a homogeneous coarse average is not used as their reference.

For accessible biomass X=A max(B-R,0), cumulative harvest is bounded above by
X(0)+A integral gamma(f)dt, where gamma(f)=max over B in [R,K] of
max(rfB(1-B/K)-sB,0). For these parameters gamma(1)=.25 and gamma(.6)=.016
kg DM/ha/h. Summing these bounds and also imposing the physiological maximum
intake gives an optimistic combined gut/body energy bound after maintenance
and routine expenditure, with all travel relaxed. A negative bound at any
prefix certifies inability to reach it without a domain exit. A nonnegative
bound is inconclusive; it does not prove feasibility. Pooled-control success
can separately demonstrate a feasible trajectory under that relaxation.

## Bounded follow-up after the frozen main study

The completed main study found that the proposed 28-day pulse did not recover
under the experienced policy in any layout. The undisturbed continuous-layout
branches completed; clustered/fragmented undisturbed branches did not. Preserve
all 53 main outcomes and their status as the original design.

To test a shorter disturbance against a completing physical baseline, add ONLY
a seven-day f=.6 pulse (days61-67) in the continuous layout with near/far water,
using the same cached day60 state, parameters, policy and final day228. These
two runs are a post-main, prospectively fixed follow-up; they are not part of
the original frozen matrix. The duration is an experimental contrast, not a
change to plant, encounter or behaviour parameters. No further duration search
will follow if these cases also fail. Report their status separately and avoid
using them as independent confirmation of a fitted response.
