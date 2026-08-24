# Decision 0043: Repeated Choice Recurrence

Date: 2026-08-16

Status: accepted

## Question

If the accepted pressure-only daily myopic choice loop is continued without
changing any mechanism or parameter, do repeated switches approach a stable,
interpretable alternation, drift secularly, or accelerate into chattering?

## Design

The Goal 042 pressure treatment starts from the same two patches at the
`1,000 kg DM ha^-1` forage equilibrium, the same reference animal state, and
the same `50 animals ha^-1` aggregate removal pressure. The once-daily cue,
fixed destination expectation, `900 kJ` one-hour route, common forage turnover,
residual threshold, appetite-energy system, and full stay-move oracle are
unchanged.

The run stops immediately after its sixth move, with day 360 as a hard cap.
This event-based stop gives three moves in each direction while avoiding an
arbitrary long run. Every selected day carries location, both forage stocks,
gut energy, and body reserve. Both full daily counterfactuals are still run
from the same opening state before only the myopic action is carried.

## Evidence

The sixth move occurs on day 305, before the hard cap. The switch sequence is:

| Move | Day | Interval | Route | Destination forage | Gut opening / closing | Body reserve opening / closing |
| ---: | ---: | ---: | --- | ---: | ---: | ---: |
| 1 | 59 | - | A to B | 1,000.00 kg DM ha^-1 | 680 / 850 kJ | 39,831 / 39,200 kJ |
| 2 | 117 | 58 days | B to A | 875.80 kg DM ha^-1 | 637 / 885 kJ | 39,579 / 38,949 kJ |
| 3 | 166 | 49 days | A to B | 845.84 kg DM ha^-1 | 656 / 865 kJ | 39,728 / 39,099 kJ |
| 4 | 213 | 47 days | B to A | 838.25 kg DM ha^-1 | 626 / 896 kJ | 39,496 / 38,860 kJ |
| 5 | 259 | 46 days | A to B | 834.32 kg DM ha^-1 | 650 / 872 kJ | 39,677 / 39,049 kJ |
| 6 | 305 | 46 days | B to A | 834.32 kg DM ha^-1 | 627 / 895 kJ | 39,507 / 38,872 kJ |

Every move begins with the occupied patch at the `500 kg DM ha^-1` residual
threshold and an adequate destination above `830 kg DM ha^-1`. No move day is
stock-limited. The intervals contract from 58 to 46 days and the last two are
both 46 days. Absolute destination-forage differences between corresponding
same-direction moves decline successively from `154.16` to `37.55`, `11.52`,
and `3.93 kg DM ha^-1`. Same-direction gut and body states also converge rather
than diverge. The minimum body reserve is `38,860 kJ`; later move-day reserves
do not continue a monotonic decline.

The myopic and oracle actions disagree only on days 212 and 304, immediately
before moves 4 and 6. At opening occupied-patch biomasses of `501.00` and
`501.06 kg DM ha^-1`, the opening cues are `0.020` and
`0.021 kg DM h^-1`. The myopic rule stays while the full oracle moves, and the
selected stay days become stock-limited for nine and eight hours. The realized
regrets are `57` and `44 kJ`, for `101 kJ` cumulatively. On both next days the
cue moves and agrees with the oracle. All 850 daily counterfactuals close their
forage, coupling, gut, body, and combined-energy accounts.

## Interpretation

The evidence supports approach toward a bounded alternating recurrence, not
chattering, secular deterioration, or indefinite acceleration. Six moves do
not prove an exact asymptotic cycle, but the stabilized late intervals and
converging same-direction forage and physiological states are sufficient for
this diagnostic decision.

The two oracle disagreements clarify the information limit. Slightly above the
residual, the opening one-hour cue is treated as if it persists through the
feeding bout; it cannot anticipate that same-day removal will make staying
stock-limited. This delays two later moves by one day, with small energetic
costs, and the closed loop self-corrects without oscillation.

This is an emergent-looking pattern from understood depletion, renewal,
movement cost, appetite, and state carry-over. It is not evidence of optimal
foraging, learned resource maps, realistic movement frequency, carrying
capacity, chronic viability, or a general behavioral policy.
