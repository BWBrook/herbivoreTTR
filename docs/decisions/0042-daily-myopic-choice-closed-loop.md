# Decision 0042: Daily Myopic Choice Closed Loop

Date: 2026-08-16

Status: accepted

## Question

When the accepted myopic resource-choice null is applied once per day to
carried animal and forage states, does it produce stable residency under the
reference load and interpretable patch switching under established forage
pressure, without pathological day-to-day oscillation?

## Design

Two identical patches start at the `1,000 kg DM ha^-1` forage equilibrium. The
animal starts in patch A on its accepted gut-body reference trajectory. For
120 days, location, both forage stocks, gut energy, and body reserve carry
exactly from each selected day into the next.

At every day boundary, the Goal 041 myopic rule compares the opening-state
one-hour acquisition cue in the occupied patch with a prescribed
`0.025 kg DM h^-1` expectation for the other patch. It chooses either a full
stay day or a one-hour, `900 kJ` move at hour 0 followed by residence in the
destination. Both full dynamic counterfactuals are run from the same opening
state; the better is retained only as the daily perfect-model oracle benchmark.

The only treatment difference is representative animal density:

- reference: `10 animals ha^-1`;
- pressure: `50 animals ha^-1`, previously established in Goal 032.

This is a deterministic diagnostic. Density is aggregate removal pressure,
not an explicit population or empirical abundance estimate.

## Evidence

| Treatment | Density | Switches | Switch days | Stock-limited hours | Movement expenditure | Cumulative regret | Minimum body reserve | Closing body reserve | Closing patch A | Closing patch B |
| --- | ---: | ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Reference | 10 animals ha^-1 | 0 | None | 0 | 0 kJ | 0 kJ | 40,000 kJ | 40,000 kJ | 874.14 kg DM ha^-1 | 1,000.00 kg DM ha^-1 |
| Pressure | 50 animals ha^-1 | 2 | 59, 117 | 12 | 1,800 kJ | 0 kJ | 38,949 kJ | 39,868 kJ | 819.99 kg DM ha^-1 | 545.79 kg DM ha^-1 |

The reference animal remains in patch A. Intake never becomes stock-limited,
body reserve remains exactly neutral, occupied patch A declines monotonically
toward its accepted load-dependent equilibrium, and unoccupied patch B remains
exactly at forage equilibrium.

The pressure animal moves from A to B on day 59 and returns on day 117, so the
moves are separated by 58 days. Both occur when the occupied patch opens at the
`500 kg DM ha^-1` residual threshold. The first destination is at equilibrium;
by the return, released patch A has renewed to `875.80 kg DM ha^-1`.

Stock limitation occurs for four hours on day 58 and eight hours on day 116,
immediately before the respective moves. Movement days are not stock-limited.
Body reserve reaches its minimum after the second route expenditure, then
recovers by `919 kJ` over the final three adequate-forage days. The first and
second move-day intakes are `0.364` and `0.372 kg DM`, respectively, reflecting
the carried appetite-energy state.

Every myopic action agrees with its matched daily oracle, giving zero realized
and cumulative regret. All 480 stay and move counterfactuals close patch,
coupling, gut, body, and combined-energy accounts.

## Interpretation

The closed loop behaves coherently. Low pressure supports persistent residence.
High pressure produces local depletion, a move to adequate forage, renewal of
the released patch, and a later reciprocal move. There is no consecutive-day
switching or cue-driven chattering.

This is the first emergent-looking spatial pattern in the rebuild, but its
mechanism remains fully attributable. The once-daily rule, hard residual,
common turnover, fixed destination expectation, and synthetic density largely
determine its timing. The result does not establish optimal foraging, realistic
movement frequency, carrying capacity, chronic stress, or viability.

Memory, learning, destination updating, uncertainty, endogenous within-day
choice, patch-specific turnover, richer forage composition, water physiology,
weather, population feedback, and health consequences remain separate
questions.
