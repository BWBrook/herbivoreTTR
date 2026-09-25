# Plant-matched return expectation (064)

Frozen 25 September 2026 before repair trajectories. Barry authorised fixing
the inherited two-day recovery assumption, selecting red kangaroos and cattle
as empirical anchors, and committing/pushing the accumulated work. Fable's
review is correspondence thread 56, messages 540–545; Astra recorded the
authorisation in message 549. The original 061–063 implementation is preserved
in commit `d610ae9`. This is a synthetic expectation repair, not calibration.

## Question and repair

Does correcting the recovery expectation remove the experienced-rule exits
in the reference undisturbed cases and the two high-search examples identified
by Fable? The intervention starts on day 61 from each original complete state,
including memory, vegetation, gut, body water, reserve and journeys. The
day-60 state is a transient, not an asserted grazed equilibrium.

At fixed search coefficient q (m² per feeding hour), the instantaneous
uncapped return is q(B-R) kJ per feeding hour, because the food energy density
and m²/ha conversion both equal 10,000. Define a **return-equivalent density
proxy**, not an estimate of actual biomass:

```text
a = max(0, day - 1 - last_observed_day) complete absent days
Z0 = R + last_return / q
Za = Phi_baseline(24 a, Z0)
expected_return = min(best_return, q max(Za - R, 0))
```

Phi is the exact ungrazed plant solution, using familiar baseline belief
r=.002/h, s=.001/h, nominal K=2000 kg DM/ha and R=200 kg DM/ha. In the
heterogeneous numerical control, nominal K is the area-weighted mean of its
fixed within-block values; this remains a homogeneous belief, not a claim of
exact heterogeneous regrowth. The controller knows fixed q and baseline plant
parameters, but receives no actual unvisited biomass, prescribed/current
growth multiplier, future state or cached outcome. These parameters are
synthetic prior knowledge, not a learned or empirically validated animal skill.

Historical best is an upper cap, not a target guaranteed in finite time.
At q=.3 and last return 200, the baseline expectation approaches 240, never
250. At q=.6 the exact ungrazed passage from 200 to 250 is 14.246 days;
it is longer from a lower starting return. During reduced growth the baseline
belief can still overpredict recovery: eliminating that uncertainty would
require a separately justified observable seasonal cue or learning model.

Daily realized return is appetite-censored and averaged over depletion, so Z
must not be interpreted as measured standing biomass. Priors outside the
declared plant domain are rejected rather than silently clamped. All other
priors, memory updates, adequacy, score horizon, accumulated shortfall, travel,
physiology, plant equations and forcing retain 063. The two-day rule remains
an explicit historical experimental comparator, not the default forecast.

## Fixed comparisons and predictions

Five deterministic scenarios, each with old and repaired experienced rules:

| q (m²/h) | Layout | Growth | Water |
| ---: | --- | --- | --- |
| .6 | continuous | unchanged | near |
| .6 | clustered | unchanged | near |
| .6 | fragmented | unchanged | near |
| 3 | continuous | reduced on days 61–144 | near |
| 5 | continuous | reduced on days 61–144 | near |

All end on day 228 or a reported model-domain exit. Old branches are replayed
against their original full hourly ledgers; repaired branches use the same
cached day-60 state. Existing informed branches supply context where available;
no new informed run is required for undisturbed continuous terrain. No clock
sweep, new q, forcing dose, physiology or reserve-rescue tuning is permitted.

Fable predicts that the clock explains the failures. Astra predicts less
optimistic return expectations in the reference cases, but does not require
completion or improvement: selected paths, travel and depletion can change
non-monotonically. High-q drought cases specifically test remaining optimism
when baseline plant knowledge is wrong. Acceptance is correct implementation
and interpretable results, not agreement with either prediction.

## Evidence and stopping point

Keep a no-write runner and targeted validation. Record matched complete states
and prefixes; full-ledger historical replays; energy, forage and water balances;
the existing cumulative intake/energy bounds; exit/completion, reserve change,
final 28-day slope only for complete runs, station count, travel and intake.
For revisits, report complete absent days between the last feeding day in the
previous residence and the first feeding day in the next, and the first-day
realized return. Revisit statistics are conditional on policy-selected visits,
not estimates of an unbiased recovery curve. A day with positive feeding
opportunity and zero realized intake remains an observed visit; omitting it
would hide depleted arrivals. Compare total intake/cost at a
common observed horizon when a pair has different exit times.

Test zero-age identity, day-opening indexing, exact propagation, impossible
baseline targets, above-equilibrium decline, historical cap, input validation,
unchanged observation/choice rules and purity. Independently audit the repair
and results. Generated evidence stays in ignored `outputs/recovery-clock-064/`;
accepted conclusions go in Decision 0064 and current model documentation.
Record the two empirical anchors and a conditional Ash prediction, without
adding plant pools or running an Ash comparison. Commit and push after checks;
reply to Fable and stop at that review boundary.
