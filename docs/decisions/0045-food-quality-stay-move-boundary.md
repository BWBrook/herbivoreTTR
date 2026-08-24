# Decision 0045: Food-Quality Stay-Move Boundary

Date: 2026-08-20

Status: accepted

## Question

With forage acquisition non-limiting and static, when does moving from a
lower-energy patch to an adequate patch repay one lost feeding hour and the
accepted `900 kJ` route expenditure?

## Design

The animal opens each comparison in a current patch with the accepted reference
gut and body state. Current-patch metabolizable-energy density varies alone
from `4,000` to `10,000 kJ kg DM^-1` in `100 kJ kg DM^-1` steps. The known
destination remains fixed at `10,000 kJ kg DM^-1`. Both patches have equal,
non-limiting `0.025 kg DM h^-1` acquisition capacity.

At each density, matched full-model counterfactuals either stay for the entire
day or move at hour 0. Moving traverses one one-hour route, loses one open
feeding hour, and adds `900 kJ` expenditure. There is no biomass state,
depletion, renewal, water, or repeated choice. The perfect-model oracle moves
only if its closing combined energy is strictly greater; a tie stays.

The existing feeding-bout helper is evaluated alongside the oracle, but its
single supplied energy density remains common to both candidates. It is the
unchanged quality-blind operational null, not the result being tested.

## Evidence

| Current density | Destination density | Common-quality choice | Oracle | Stay change | Move change | Move advantage |
| ---: | ---: | --- | --- | ---: | ---: | ---: |
| 4,000 | 10,000 | Stay | Move | -1,628 kJ | -549 kJ | 1,079 kJ |
| 7,000 | 10,000 | Stay | Move | -618 kJ | -549 kJ | 69 kJ |
| 7,300 | 10,000 | Stay | Move | -556 kJ | -549 kJ | 7 kJ |
| 7,400 | 10,000 | Stay | Stay | -536 kJ | -549 kJ | -14 kJ |
| 8,000 | 10,000 | Stay | Stay | -412 kJ | -549 kJ | -137 kJ |
| 10,000 | 10,000 | Stay | Stay | 0 kJ | -549 kJ | -549 kJ |

The oracle has one transition: it moves through `7,300` and stays from
`7,400 kJ kg DM^-1`. This is a `100 kJ kg DM^-1` diagnostic bracket, not
empirical precision. At the accepted `8,000` versus `10,000` contrast, moving
provides `763 kJ` more ingested energy but costs `900 kJ`, so staying is better
by `137 kJ` over the day.

At every level:

```text
move minus stay combined energy
  = move ingested energy - stay ingested energy - route expenditure
```

Movement advantage declines monotonically as current-patch quality improves.
The move outcome remains constant because the animal cannot feed during the
hour-0 route and then experiences the same adequate destination for the rest
of every treatment. Acquisition never limits intake, and all hourly and daily
energy accounts close.

## Interpretation

Food quality is decision-relevant under a sufficiently severe contrast, but a
higher-quality destination is not automatically worth visiting. Under the
accepted `8,000` versus `10,000` contrast, appetite compensation makes staying
less costly than paying this route. Dry-matter intake alone is not the decision
currency: the low-quality stay can consume more mass while obtaining less
metabolizable energy.

This is a perfect-information, full-model diagnostic benchmark, not an animal
strategy. It does not establish perception, anticipation, learning, endogenous
decision timing, repeated choice, an empirical quality threshold, or a
quality-aware package behavior.
