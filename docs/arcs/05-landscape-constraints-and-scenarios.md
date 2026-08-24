# Arc 05: Landscape Constraints And Scenarios

Status: in progress; one controlled biomass-quality interaction exposes the next behavioral decision gate

## Purpose

Add the ecological constraints needed to ask the motivating Sahul question:
when do repeated habitat conditions cause chronic physiological decline rather
than an acute, recoverable bottleneck? Each constraint enters separately before
combined scenarios are interpreted.

## Starting Boundary

Enter with an explicit, diagnostically stable patch-and-movement model. Keep
the accepted energetic animal, forage conservation, and movement accounting as
anchors. Do not add several stressors in one goal.

## Proposed Progression

1. **Water itinerary:** add a known water source and prescribed daily visit,
   initially as travel time and energy only. Add water balance later as a
   separate physiological decision.
2. **Choice under static heterogeneity:** test how animals select among known
   patches differing in acquisition and quality without depletion.
3. **Patch depletion and renewal:** activate local forage removal and regrowth,
   retaining fixed routes and a simple choice rule.
4. **Richer forage composition:** add one composition axis at a time, with
   protein and water prioritized alongside metabolizable energy; introduce
   physical gut or digestive constraints only when needed to interpret intake.
5. **Weather and thermoregulation:** add thermal and water costs through
   explicit environmental forcing, separately from food limitation.
6. **Landscape heterogeneity:** introduce structured variation in vegetation,
   water distance, patch renewal, and accessibility.
7. **Scenarios:** compare seasonal drought, altered fire or vegetation regimes,
   and other habitat-change hypotheses against the stable reference.
8. **Chronic-state endpoints:** define repeated reserve loss, recovery failure,
   or later viability consequences only after their mechanistic drivers are
   understood.

## Current Progress

Goal 037 implements step 1 as a prescribed out-and-back trip between an
adequate static forage patch and a named non-feeding water source. The same two
one-hour routes are placed either wholly outside or wholly inside feeding
hours. This separates `1,800 kJ` of incremental movement expenditure from zero
versus two hours of feeding opportunity lost. The `900 kJ` per-leg cost is a
ratio-informed synthetic value, not empirical species calibration.

Step 2 is already satisfied at its minimum intended level by the one-choice
static-heterogeneity null accepted in Goal 036. Repeated decisions and richer
information remain deferred.

Goal 038 implements step 3's dynamic resource foundation without yet adding
choice. Every patch receives the same autonomous turnover, and the co-located
representative animal load removes forage only from the occupied opening patch
during stays. Under 30 days in patch A, one closed-hour transfer, and 30 days in
patch B, the released patch renews and the newly occupied patch depletes with
exact patch and animal accounting.

Goal 039 adds one diagnostic perfect-state, perfect-model choice without a new
behavioral API. The oracle compares full stay and move days from one opening
state. It stays under the accepted mild depletion but moves under a severe
stock-limited positive control, whereas the static equal-capacity rule stays in
both. This establishes resource-state decision relevance.

Goal 040 varies only current-patch opening biomass and locates one oracle
transition: move through `497.5 kg DM ha^-1`, stay from
`498.0 kg DM ha^-1`. Movement wins exactly while extra metabolizable intake
exceeds the `900 kJ` route expenditure. This closes the immediate
perfect-information decision-relevance question.

Goal 041 replaces exact forecasting with one opening-state acquisition cue for
the current patch and a prescribed expected destination rate. It differs from
the oracle only from `498.0` through `500.0 kg DM ha^-1`, always by moving too
early because it omits within-day renewal. The largest daily regret is
`549 kJ`. This maps one minimal information limit while leaving endogenous
timing, destination updating, memory, and learning unresolved.

Goal 042 applies the same cue once daily for 120 carried days. The reference
load remains resident and energetically neutral. The accepted pressure load
moves from A to B on day 59 and returns on day 117, only after the occupied
patch reaches the residual. Released A renews to `875.80 kg DM ha^-1` before
the return. All daily actions match their full-model oracles, and the 58-day
separation rules out decision chattering in this fixed comparison. The result
establishes one interpretable repeated null, not a general policy.

Goal 043 changes no mechanism or parameter and extends only the pressure loop
to its sixth move. Moves occur on days 59, 117, 166, 213, 259, and 305; the
intervals contract to 46 days while same-direction destination forage, gut,
and body states converge. Two one-day-late choices incur `101 kJ` total regret
against the full oracle and correct on the following days. This supports an
approach to bounded alternating recurrence without claiming an exact cycle or
a general behavioral policy.

Goal 044 begins the deferred composition component of step 2 with one bounded
food-quality axis. Each explicit patch now carries its own
metabolizable-energy density. With acquisition non-limiting and movement
absent, adequate (`10,000 kJ kg DM^-1`) and lower-quality
(`8,000 kJ kg DM^-1`) all-stay patches reduce exactly to the corresponding
non-spatial physiology. The lower-quality case raises intake but still closes
`412 kJ` below reference. Quality-aware movement and choice remain deliberately
deferred until this environmental property is independently established.

Goal 045 tests that established property against movement without adding
vegetation or behavior. A perfect-model oracle compares matched all-day stay
and hour-0 move counterfactuals while current-patch density varies from `4,000`
to `10,000 kJ kg DM^-1`; the destination stays at `10,000`, acquisition is
equal and non-limiting, and the route costs `900 kJ`. The oracle moves through
`7,300` and stays from `7,400 kJ kg DM^-1`. At the accepted `8,000` contrast,
staying is better by `137 kJ`. This establishes that quality can change a
decision under a sufficiently severe contrast while leaving perception,
anticipation, repeated choice, and quality-aware package behavior unresolved.

Goal 046 resolves the minimum package boundary without adding foresight. The
feeding-bout helper now reads both acquisition capacity and metabolizable-energy
density from each candidate patch. Its fixed-demand score moves through
`6,500` and stays from `6,600 kJ kg DM^-1`, whereas the full-model oracle moves
through `7,300`. The helper therefore stays too early from `6,600` through
`7,300`, with at most `168 kJ` realized regret, but agrees at the accepted
`8,000` contrast. This closes the immediate quality-choice step with a bounded,
inspectable information cost; anticipation and repeated quality-aware choice
remain later decisions.

Goal 047 combines the two established environmental axes without changing a
mechanism. Under matched 305-day pressure runs, lowering patch A alone to
`8,000 kJ kg DM^-1` advances the first switch from day 59 to day 40, increases
switches from six to eight, and lowers the minimum body reserve from `38,860`
to `36,948 kJ`. The lower-quality patch is consumed and depleted faster. Seven
one-day oracle disagreements sum to `2,919 kJ` of local regret: the operational
rule leaves lower-quality forage late and returns to it early. The interaction
is attributable and accounting remains exact, but the information rule is now
an explicit decision gate rather than an accepted realistic behavior.

## Decision Gates

- Which water, composition, and thermal processes are essential for the next
  ecological question rather than merely realistic?
- What information and memory does the animal use when choosing patches?
- Which environmental drivers are prescribed, and which emerge from plant-
  herbivore feedback?
- What duration and endpoint distinguish acute stress from chronic decline?
- When is empirical parameterization strong enough to replace a synthetic
  contrast?

## Exit Criteria

This arc supports scenario science when:

- each added constraint has an isolated reference and attribution test;
- water, food, movement, and thermal costs remain separately inspectable;
- depletion and renewal conserve forage mass;
- choice rules state their information assumptions;
- combined outcomes can be traced to specific mechanisms; and
- chronic decline is defined before testing Pleistocene habitat-change
  scenarios.

## Deliberate Deferrals

Publication framing, species-specific claims, population demography,
reproduction, mortality, and extinction risk remain separate decisions. A
synthetic coupled model may itself be the first scientific product; Diprotodon
or modern macropod parameterization follows only after the machinery is stable
and its sensitivities are understood.
