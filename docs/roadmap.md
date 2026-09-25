# Roadmap

## Stage Map

| Stage | Question | Status |
| --- | --- | --- |
| 1. Herbivore core | Can intake, gut delay, expenditure, appetite, and simple forage constraints be understood as one energy system? | Closed |
| 2. Isolated plant-forage | Can a simple forage biomass stock remain stable under growth, loss, and later seasonal forcing without herbivory? | Closed; controlled forcing deferred until required |
| 3. Non-spatial coupling | How do herbivore intake and forage depletion alter one another in a homogeneous system? | Closed |
| 4. Explicit patches and movement | How do location, patch choice, travel time, and travel energy change intake and state? | Closed |
| 5. Landscape constraints and scenarios | How do water, depletion, heterogeneity, climate, and disturbance produce chronic stress? | In progress; return expectation repaired (0064); red-kangaroo/cattle anchors selected, empirical contracts remain open |

The detailed contracts are stored under `docs/arcs/`.

## Completed Herbivore Core

The retained animal system now provides:

1. an hourly body-energy ledger;
2. delayed energy release from one gut stock;
3. dry-matter to metabolizable-energy conversion;
4. periodic reference initialization;
5. maintenance and routine-activity expenditure;
6. a bounded body- and gut-responsive appetite target;
7. an external non-depleting forage-acquisition ceiling;
8. repeated-day state carry-over;
9. derived reserve tissue and total body mass; and
10. diagnostic treatments for feeding duration, implicit patch order,
    movement cost, and food quality.

The diagnostic treatments remain outside the package when they do not yet
justify generalized production state or behavior.

## Isolated Forage Progress

The plant side now has one homogeneous standing-biomass stock in
`kg DM ha^-1`, prescribed hourly growth and background-loss fluxes, and exact
hourly and daily accounting. A linear turnover reference adds constant
production and proportional loss around a positive equilibrium, with an exact
analytic trajectory. A fixed residual threshold then derives non-negative
accessible biomass without changing the plant stock or defining animal intake.

The minimum constant core is ready for coupling. Controlled environmental
forcing is deferred so the stable plant null can anchor the first homogeneous
coupled reference. Herbivory begins in Stage 3; seasonality remains deferred.

## Non-Spatial Coupling Progress

The first homogeneous coupling uses one representative physiology at a fixed
animal density per hectare. Realized per-animal intake scales exact forage
removal, accessible forage supplies a stock ceiling, and accepted turnover
supports a stable period-24 reference. A temporary animal-load pulse then
produces attributable forage depletion, intake limitation, animal-energy loss,
and recovery after release. This closes the homogeneous arc and releases
explicit spatial development.

## Explicit Spatial Progress

The first spatial layer uses named patches, one explicit animal location, and
directed one-hour routes. A prescribed 24-hour closing-patch itinerary now
infers stay versus movement and composes travel with feeding opportunity,
appetite, and energy expenditure. An all-stay day reduces exactly to the
accepted reference; a fixed two-move round trip closes all location, time, and
energy accounts. Static patch acquisition capacity then reproduces the accepted
limited-to-adequate and adequate-to-limited order effects while holding travel
constant. A fixed-demand remaining-bout score then selects sensible stay or
move actions and is checked against both full-model counterfactuals. This closes
the explicit-patch arc without repeated decisions or dynamic resources.

## Landscape Constraints Progress

The first constraint is a mandatory prescribed daily trip from an adequate
forage patch to a named non-feeding water source and back. Matched two-leg trips
outside and inside the feeding window isolate route expenditure from feeding
opportunity lost. The route cost is a ratio-informed synthetic value rather
than species calibration. This historical travel-only null now anchors the
separate body-water layer described below.

The one-choice static-heterogeneity null originally listed in this stage was
already completed at the close of the explicit spatial arc. The first dynamic
resource layer now carries one biomass stock per patch, applies common turnover
everywhere, and removes herbivory only from the occupied patch during stays. A
fixed occupancy-release comparison produces attributable local depletion and
renewal without stock limitation. One perfect-information comparison then
shows that this mild depletion does not justify a costly move, while a severe
stock-limited positive control does. This is a decision-relevance benchmark,
not animal behavior. Varying occupied-patch opening biomass alone locates a
single synthetic switch between `497.5` and `498.0 kg DM ha^-1`: moving is
favored only while added intake energy repays the `900 kJ` route. Information
is then reduced once: an opening-state current-patch cue with a prescribed
destination expectation moves prematurely only from `498.0` through
`500.0 kg DM ha^-1`, with at most `549 kJ` regret because it cannot anticipate
same-day renewal. Applied once daily, that rule produces stable residency at
the reference load. Under pressure, six reciprocal moves occur by day 305 and
their intervals settle at 46 days as destination forage and animal states
approach recurrence. Two one-day-late oracle disagreements cost `101 kJ` in
total and self-correct without chattering. Endogenous timing, memory, learning,
destination updating, patch-specific production, and richer landscape
information remain future layers. Patch-specific metabolizable-energy density
is now transported through the explicit runner: adequate and lower-quality
all-stay patches reduce exactly to their accepted non-spatial physiology.
A matched full-model oracle then varies only current-patch quality against a
fixed adequate destination. It moves through `7,300` and stays from
`7,400 kJ kg DM^-1`; at the accepted `8,000` contrast, the `900 kJ` route is
still too costly by `137 kJ`. This establishes quality-based decision relevance
without yet adding animal foresight. The minimal package helper now scores each
candidate with its own patch energy density. It moves through `6,500` and stays
from `6,600 kJ kg DM^-1`, staying too early only from `6,600` through `7,300`;
maximum realized regret is `168 kJ`, and both rules stay at the accepted
`8,000` contrast. This bounded error is retained as the explicit cost of a
fixed-demand, non-anticipatory operational null.

The first controlled biomass-quality interaction holds the accepted pressure
system fixed for 305 days and lowers patch A alone to
`8,000 kJ kg DM^-1`. The first move advances from day 59 to day 40, switching
increases from six to eight events, and minimum body reserve falls from
`38,860` to `36,948 kJ`. The rule incurs seven local daily oracle disagreements
totalling `2,919 kJ`, exposing both late departure from poor forage and early
return to it. The next choice is therefore conceptual, not another automatic
layer. A first minimally realistic candidate remembers only the last realized
energy return in each patch. It leaves lower-quality A on day 41 but never
returns because the stored depleted return cannot reflect unobserved renewal.
The animal reaches the non-negative body-reserve boundary on day 147 while A
has recovered to `960.77 kg DM ha^-1`. Before further composition or forcing,
the next information rule must represent both recovered opportunity and
consequences beyond the current day; neither learning-rate tuning nor local
one-day regret resolves that decision.

The day-101 Goal 049 decomposition then crosses those factors explicitly.
Replacing stale patch-A memory (`119.73 kJ` per feeding-opportunity hour) with
the animal's own previously experienced abundant return (`200 kJ` per feeding-
opportunity hour) does not justify the route over one day: staying remains
better by `295 kJ`. Extending stale information to two days also fails. Only
recovered opportunity plus a two-day horizon favours moving, by `511 kJ` in
both the transparent score and matched full-model policies. This closes the
diagnostic question but leaves the carried recovery-learning mechanism as the
next design decision.

Goal 050 tests that carried design once without tuning. A familiar-territory
memory stores last return, historical best, and days since visit; unvisited
return relaxes toward the best at `0.001 h^-1`, and the animal uses the two-day
score. The rule completes `305` days and revisits both patches seven times, but
minimum body reserve drops to `12,355 kJ`. It disagrees with a local full-model
two-day evaluator on `147` days, always by staying when movement is preferred.
This rejects direct biomass-timescale recovery of experienced return. The next
bounded comparison should distinguish flow-aware recovery hypotheses before
any behavior is promoted or another ecological layer is added.

Goal 051 performs that first bounded comparison without carrying a policy.
Starting either destination at the residual boundary, realized two-day feeding
return recovers over one to two days, while standing biomass continues its
weeks-long approach to equilibrium. Lower-quality A first repays the route at
age 1 day and reaches its return plateau at age 2; higher-quality B repays the
route at age 0 and plateaus at age 1. Accessible forage accumulated during
absence plus continued production is the leading explanation, although their
contributions were not separately manipulated. A learned absence-to-return
relationship is therefore the next candidate; direct biomass-timescale return
relaxation remains rejected.

Goal 052 carries one such candidate without granting biomass knowledge. An
unvisited patch's expected return advances linearly from last experience to
historical best over two absent days. This reduces two-day evaluator
disagreements from `147` to `43`, all remaining errors being false stays, but
induces `83` switches and `74,700 kJ` of travel. Every selected move agrees with
the two-day evaluator while minimum reserve falls to `9,386 kJ`. The result
rejects the clock and exposes the next question: whether a longer consequence
horizon values patch rest, or whether frequent rotation remains favoured by
the current two-patch system.

Goal 053 resolves that question at the first reciprocal checkpoints. Moving
from depleted B into long-rested A strengthens from `511 kJ` over two days to
`10,174 kJ` over fourteen. Returning to B after two days is favourable through
a four-day horizon but reverses to `-2,009 kJ` over seven days and `-7,646 kJ`
over fourteen. The short-horizon failure is therefore an early return to a
high-quality but shallowly recovered patch. The next behavioral information
axis is expected return persistence, not slower recovery or a generic movement
penalty.

Goal 054 closes that information problem without adding a destination-depth
forecast. The animal retains its experience-and-time recovery memory, stays
while the current patch supplies its `200 kJ` per feeding-opportunity-hour
requirement, and accumulates energetic shortfall during inadequate bouts. A
small chronic deficit can therefore repay travel, while adequate current forage
is not abandoned for a briefly attractive destination. The baseline completes
305 days with nine switches no closer than 27 days, a minimum reserve of
`36,221 kJ`, and closed accounts. Seven viable one-factor comparisons remain
stable; an additional low-turnover case identifies an explicit supply boundary.
The synthetic experience-based patch-choice tranche is closed.

Goal 055 adds one physical body-water stock without changing the accepted food-
patch rule. Effective forage water and stationary drinking add water; fixed
ordinary loss removes it; a daily-opening thirst trigger sends the animal to
one familiar source. Isolated deficit, neutral, and surplus cases close exactly,
and disabling water reproduces the Goal 054 trajectory. Wetter forage lowers
visit frequency and protects energy reserve. Under drier forage or greater
ordinary loss, repeated water trips make energy limiting before the declared
critical-water boundary is crossed. The result is an attributable synthetic
stress boundary, not species calibration. Thermal forcing, dynamic plant
moisture, and multiple water sources remain later decisions.

Goal 056 adds the smallest temporal forcing boundary: one prescribed
incremental evaporative-loss flux, independently conserved and exactly zero in
the Goal 055 reduction. Isolated and coupled systems branch after 60 common
days into clustered, repeated, diffuse dose-matched, sustained, and control
schedules. Equal cumulative loss produces unequal visits and recovery debt;
repeated events recover better than the clustered pulse, contrary to the
prespecified prediction. Sustained forcing drives coupled energy close to its
non-negative boundary before critical dehydration. Temperature response,
heat balance, thermoregulatory behavior, plant moisture, and species
calibration remain deliberately unimplemented.

Goal 057 replaces delayed daily observation with one causal hourly drinking
null. A visit never begins before the `26 kg` threshold is observed, at most one
complete known-source trip occurs per day, and late detections are deferred.
Across the Goal 056 regimes, faster response consistently protects minimum
water. In the coupled system it also displaces feeding opportunity: the
sustained branch reaches the non-negative energy boundary after 76 treatment
days while remaining above critical water. One integration repair prevents
water excursions from being misremembered as poor food-patch return. The rule
is accepted as an operational null, not optimized or calibrated behavior.

Goal 058 compares reactive drinking with one recent-experience anticipatory
top-up under synthetic temperature cycles, equal-dose phase shifts, and bounded
sensitivity. The candidate helps some conditions but worsens others because
smaller refills can require more costly trips; it is not promoted as a default.
This closes the environmental-forcing/first-anticipation comparison without
rescue tuning.

Goal 059 gates optional top-ups by estimated energetic cost per kilogram of
refill. It restores most of the original midday penalty and benefits the
primary shifted case, but the advantage over reactive drinking reverses under
longer memory or weaker evaporation. The comparison is accepted and both
anticipatory policies remain diagnostic comparators; reactive drinking stays
the default; see Decision 0059.

Goal 060 establishes energetic-accessibility dependence by varying source-route
expenditure alone. All heated coupled branches complete at half the inherited
cost but stop before heat removal at unit cost or above; doubled cost also
ends the no-added-heat coupled branches around day 85. Isolated forage tolerates
more expenditure, and policy ranking remains conditional. The five-point grid
brackets sampled completion transitions without estimating exact thresholds.
A complementary trip-duration comparison at fixed round-trip expenditure is
proposed next, pending approval of its timing contract; see Decision 0060.

## Deferred Animal Layers

Protein, mechanistic thermoregulation, state-dependent water loss,
dynamic plant moisture, explicit mass feedback, gut composition, reproductive
allocation, and survival thresholds remain scientifically important. They
should be added one at a time when a new ecological question can distinguish
their contribution.

## Area-Supported Spatial Programme (061)

The approved broader programme supersedes the narrow duration-only proposal
above. It adds one focal animal, explicit area/XY geometry, travel time in
physical units, responsive edible biomass, and a 16-branch chronic-condition
factorial plus five structural controls. Habitat and plant forcing drive
energy-domain exits while water remains above its interpretation boundary.
Policy and feeding support affect exit timing; this is a synthetic conditional
result, not species viability. See [Decision 0061](decisions/0061-area-supported-spatial-grazing.md).

## Physical Feeding Support and Access (062)

Fixed footprints now preserve biological search support under numerical
subdivision. The main 53-branch matrix and two adaptive follow-up branches
distinguish pooled-stock feasibility from encounter/behavioural limits, with
explicitly non-nested access controls. Short-term reserve recovery can precede
later decline. The representation is accepted at its synthetic scope; reward
memory and encounter scales need empirical grounding before further enrichment.
See [Decision 0062](decisions/0062-physical-feeding-support-and-access.md).

## Encounter and Policy Sensitivity (063)

The four missing undisturbed informed/cyclic controls complete near baseline
reserve. Across the five sampled encounter rates, sustained informed branches
complete from 1.5 m²/h upward while experienced branches exit throughout.
More search is not monotonically beneficial under the experienced rule.
The 90-branch comparison, dimensionless diagnostics and stationary analytical
benchmark are closed at their synthetic scope; see
[Decision 0063](decisions/0063-encounter-and-policy-sensitivity.md).
The [recovered empirical-case assessment](rebecca-archive-assessment.md) is
complete. The four studies chiefly constrain vegetation responses to herbivory;
none directly calibrates search or memory. A matched animal reference and an
Ash-based qualitative plant-response comparison are the proposed next tranche,
before adding another behavioural or physiological layer. Borer treatment
mapping and a conflicting livestock flag require resolution before its supplied
data can support factorial comparisons.
