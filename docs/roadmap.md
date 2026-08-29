# Roadmap

## Stage Map

| Stage | Question | Status |
| --- | --- | --- |
| 1. Herbivore core | Can intake, gut delay, expenditure, appetite, and simple forage constraints be understood as one energy system? | Closed |
| 2. Isolated plant-forage | Can a simple forage biomass stock remain stable under growth, loss, and later seasonal forcing without herbivory? | Closed; controlled forcing deferred until required |
| 3. Non-spatial coupling | How do herbivore intake and forage depletion alter one another in a homogeneous system? | Closed |
| 4. Explicit patches and movement | How do location, patch choice, travel time, and travel energy change intake and state? | Closed |
| 5. Landscape constraints and scenarios | How do water, depletion, heterogeneity, climate, and disturbance produce chronic stress? | In progress; one deterministic repeated depletion-renewal choice loop established |

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
than species calibration. Water balance and drinking benefits remain absent.

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

## Deferred Animal Layers

Protein, water balance and drinking physiology, thermoregulation, explicit
mass feedback, gut composition, reproductive allocation, and survival
thresholds remain scientifically important. They should be added one at a time
after the forage and basic coupling stages reveal which physiological detail
can change a decision.
