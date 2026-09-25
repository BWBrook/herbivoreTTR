# 0063 — Encounter rate and policy jointly determine the observed exits

2026-09-18. Close the diagnostic programme authorised by Barry following
Fable's external review. The [frozen specification](../feeding-access-sensitivity-specification.md)
defines the 90 branches and stopping point. No animal, plant or policy equation
was changed. The results remain synthetic and conditional on the tested grid.

## Main conclusion

The undisturbed clustered and fragmented layouts support completing trajectories
under the existing informed and cyclic rules. At the inherited encounter rate,
their experienced-rule exits are therefore not evidence that those layouts
cannot support the animal. The contrast establishes dependence on policy under
the given geometry and prior history; it does not identify an additive
fragmentation or information effect.

The sustained-forcing outcomes also depend jointly on encounter rate and policy.
Every informed branch completes at each sampled rate from 1.5 through 5 m²/h;
every experienced branch exits at every sampled rate. The original .6 result
does not generalise to all physical-access trajectories. These are deterministic
conditional contrasts, not a population-level statistical interaction or a
calibrated behavioural threshold.

## Four missing undisturbed controls

All branches below use near water and .6 m²/h, with policies changed at day 61
from the same complete state within each layout. Station counts include only
stations with positive intake after day 60. Energy is rounded to integer kJ.

| Layout | Policy | Outcome | End reserve (kJ) | Feeding stations | Final 28-day reserve slope (kJ/day) |
| --- | --- | --- | ---: | ---: | ---: |
| Clustered | Experienced | Exit day 197 | 10 | 4 | Not applicable |
| Clustered | Informed | Completes day 228 | 39,989 | 8 | -0.69 |
| Clustered | Cyclic | Completes day 228 | 39,990 | 8 | -0.66 |
| Fragmented | Experienced | Exit day 194 | 69 | 4 | Not applicable |
| Fragmented | Informed | Completes day 228 | 39,975 | 8 | -1.74 |
| Fragmented | Cyclic | Completes day 228 | 39,933 | 8 | 4.16 |

The matched day-60 reserves are 39,946 and 39,919 kJ respectively. Completing
branches finish within 14–56 kJ above their own day-60 reserves. Three retain
slightly negative final slopes; these results establish finite completion and
near-reference condition, not equilibrium or indefinite persistence. For exits,
the recorded reserve is the last accepted state before the rejected hourly
transition, not a common day-228 endpoint.

## Coefficient sensitivity

The coefficient applies throughout life, including each 60-day experienced
baseline. Subsequent policies share that baseline. All 15 baselines complete;
all 90 planned branches are evaluable, with 34 completing day 228. Baseline
condition differs across coefficients: at .3 m²/h, day-60 reserves range from
18,583 to 28,381 kJ. Across-coefficient effects include these altered histories.

| Search coefficient (m²/h) | Sustained experienced: complete / 6 | Sustained informed: complete / 6 | Undisturbed experienced: complete / 2 | Undisturbed informed and cyclic: complete / 4 |
| ---: | ---: | ---: | ---: | ---: |
| 0.3 | 0 | 0 | 0 | 0 |
| 0.6 | 0 | 0 | 0 | 4 |
| 1.5 | 0 | 6 | 0 | 4 |
| 3.0 | 0 | 6 | 0 | 4 |
| 5.0 | 0 | 6 | 0 | 4 |

Informed sustained trajectories finish at 39,003–40,000 kJ, from 963 kJ below
to 302 kJ above their own day-60 reserve. Ten of 18 finish above that baseline;
12 have positive final 28-day slopes. Completion, endpoint recovery and the
direction of recent change are distinct observations. This five-point grid
neither locates a precise transition nor proves monotonicity between points.

Fable's revised prediction of sampled experienced failure versus informed
completion at high search is supported. Its four-block explanation applies to
the clustered and fragmented experienced branches, but not all continuous
branches: higher-rate continuous animals feed at six or seven stations.
More search is not uniformly beneficial. The continuous near-water experienced
animal exits on day 205 at 3 m²/h but day 150 at 5 m²/h. The coefficient changes
depletion, baseline history and decisions; it is not an isolated increase in
intake holding the rest of the trajectory fixed. No further grid points or
policy repairs were added to obtain a preferred result.

## Ratios and analytical limits

The [ratio and one-block note](../feeding-access-ratios.md) makes the synthetic
scales explicit. At the baseline production optimum, encounter/reference-intake
ratios are .45, .90, 2.25, 4.50 and 7.50 across the five coefficients. Landscape
reference demand divided by maximum positive accessible renewal is .667 at
baseline and 10.417 during forcing. The latter does not prove finite-horizon
failure: standing forage, gut/body energy, forcing duration and later renewal
also matter.

A permanently occupied 100-m² block renews at most .06 kg DM/day at baseline,
against .32 kg DM/day reference demand. Its inevitable long-run deficit is
already explained by limited support area and must not be presented as proof
of a feedback trap. The stationary analytical map assumes adequate free water
and has explicit encounter-cap and residual-domain limits. A reserve-buffer to
plant-relaxation ratio remains descriptive; no universal chronic-decline gate
has been established.

## Evidence and verification

- Source: `experiments/feeding-access-sensitivity.R` and its explicit figure
  helper. Sourcing writes nothing; generated RDS, tables, logs and three-page
  PDF remain ignored under `outputs/feeding-access-063/`.
- All matched policy branches carry identical complete day-60 states and
  prefixes. Independent review found all 14 overlapping .6 trajectories have
  bit-identical complete hourly ledgers to 062, including exit timing.
- Every branch and baseline satisfies the applicable harvest/intake and
  combined-energy bounds. Maximum ledger residuals are 3.23e-14 kg DM,
  3.75e-12 kJ and 3.11e-15 kg water. Minimum water is 25.864 kg, above the
  24-kg interpretation boundary.
- Targeted area, plant and footprint tests and existing integration checks
  pass. Ninety direct stationary hourly checks of the analytical equations
  agree with the implementation to 1.14e-13 in the recorded numerical units.
  Retained R parses and whitespace checks pass. The 062 package release gate
  was not repeated because no package boundary changed.
- Independent scientific review accepted the design, arithmetic, cached
  evidence and bounded interpretation. Its figure-label corrections distinguish
  exit from completion and reserve endpoints at different times. The final
  three PDF pages were visually checked. Baseline-exit handling was not reached
  by this grid; no scientific claim depends on that unused branch.

Only reporting metadata, analytic reporting columns and figure labels were
refined after the run; trajectories and the frozen grid were unchanged.

## Stopping point

The key synthetic uncertainty is now demonstrated, rather than only inferred:
the tested landscape outcomes depend strongly on the chosen policy and
encounter coefficient. Preserve the existing equations until the empirical
cases can constrain feeding access, knowledge of renewal and coherent animal
scales. Assess those cases as incomplete pattern-oriented templates, separating
reported facts, estimates and unknowns. No further sweep, new memory rule,
body-size axis, plant coupling or paper format is chosen here. At this original
closeout the source was uncommitted; no commit, push or publication was performed.
The source was preserved in `d610ae9` on 25 September. Decision 0064 records the
subsequently authorised recovery repair and commit/push, with the original
trajectories retained as historical controls.
