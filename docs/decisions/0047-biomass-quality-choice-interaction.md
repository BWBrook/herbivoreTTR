# Decision 0047: Biomass-Quality Choice Interaction

Date: 2026-08-24

Status: accepted

## Question

Does one established food-quality contrast alter residence and switching when
combined with dynamic forage biomass under the existing once-daily myopic
choice rule?

## Design

Two pressure treatments run for the same `305` days from identical animal,
gut, forage, and location states at `50 animals ha^-1`. Both patches open at
`1,000 kg DM ha^-1`, share the accepted turnover and `0.025 kg DM h^-1`
acquisition capacity, and are connected by the same one-hour, `900 kJ` routes.
The animal starts in patch A.

The equal-quality control keeps both patches at `10,000 kJ kg DM^-1`. The
quality treatment changes patch A alone to `8,000 kJ kg DM^-1`; patch B remains
at `10,000`. This contrast does not justify movement from an otherwise adequate
static patch in the Goal 045 oracle, so any changed trajectory is an interaction
with dynamic forage and carried physiological state rather than an imposed
day-one preference.

At each day boundary, the existing operational rule uses current accessible
biomass as a one-hour acquisition cue, a prescribed adequate destination cue,
and each patch's declared energy density. Matched full-day stay and move
counterfactuals define a local perfect-model oracle. The myopic action alone is
carried. No anticipation, learning, endogenous timing, new depletion process,
or new physiology is added.

## Evidence

| Outcome over 305 days | Equal quality | Lower-quality patch A |
| --- | ---: | ---: |
| Switches | 6 | 8 |
| First switch | day 59 | day 40 |
| Switch days | 59, 117, 166, 213, 259, 305 | 40, 97, 129, 168, 195, 231, 258, 293 |
| Shortest switch interval | 46 days | 27 days |
| Dry-matter intake, days 1-39 | 12.480 kg DM | 15.406 kg DM |
| Patch A biomass after day 39 | 594.67 kg DM ha^-1 | 500.00 kg DM ha^-1 |
| Stock-limited hours | 41 | 38 |
| Movement expenditure | 5,400 kJ | 7,200 kJ |
| Daily oracle disagreements | 2 | 7 |
| Summed local daily regret | 101 kJ | 2,919 kJ |
| Minimum body reserve | 38,860 kJ | 36,948 kJ |
| Closing body reserve | 38,872 kJ | 38,900 kJ |
| Closing patch A biomass | 819.79 kg DM ha^-1 | 619.56 kg DM ha^-1 |
| Closing patch B biomass | 511.86 kg DM ha^-1 | 634.29 kg DM ha^-1 |

All switches still occur at or within `0.6 kg DM ha^-1` of the declared
`500 kg DM ha^-1` residual threshold, and consecutive switches remain at least
27 days apart. Every daily stay and move counterfactual closes its forage,
coupling, and energy accounts.

The quality treatment creates two directional error types. On days 39, 128,
and 257, the helper stays one day too long in lower-quality patch A while the
oracle moves to adequate patch B. On days 97, 168, 231, and 293, it moves from
adequate patch B back to lower-quality patch A while the oracle stays. The
reported `2,919 kJ` is the sum of these seven one-day opportunity costs along
the carried myopic trajectory. It is not regret against a separately carried
multi-day oracle policy.

## Interpretation

The mechanistic interaction is expected and informative. Lower energy density
elicits more dry-matter intake, depletes patch A faster, advances the first
departure by 19 days, and produces shorter lower-quality residence bouts. The
quality treatment therefore changes forage, movement, and body-energy
trajectories even though quality alone did not repay travel from the adequate
opening state. The nearly equal closing body reserves are phase-dependent
endpoints after different final switch dates; they do not erase the lower
minimum reserve or establish equal chronic viability.

The behavioral result is amber rather than green. The operational rule combines
the known Goal 046 tendency to leave a poor patch late with the known myopic
tendency to move from a depleted current patch before crediting same-day
renewal. Under asymmetric quality, those errors act in opposite travel
directions and are no longer negligible. This does not demonstrate a model bug
or justify silently adding foresight. It establishes the next decision: retain
the rule as an explicitly fallible operational null, or separately define a
minimally realistic information rule before adding further ecological layers.
