# Decision 0055: Water-Constrained Herbivore

Date: 2026-09-02

Status: accepted synthetic water layer; water-constrained herbivore tranche closed

## Question

Can one physical body-water stock connect forage moisture, a familiar drinking
source, and the accepted patch-choice system while keeping hydration, feeding
opportunity, and travel energy separately attributable?

## Minimum Contract

The model adds one dynamic stock, `body_water_kg`. Food-derived water and
realized drinking add to it; one fixed ordinary loss and any excess above the
declared normal stock remove water. A lower critical boundary is reported but
does not alter a transition. Drinking is possible only while the animal is
stationary in a patch with positive declared drinking-water availability, and
only enough water is realized to approach the normal stock.

The synthetic reference declares:

| Quantity | Value |
| --- | ---: |
| Normal body water | `28 kg` |
| Thirst trigger at the daily opening boundary | `26 kg` |
| Critical interpretation boundary | `24 kg` |
| Ordinary loss | `1.56 kg d^-1` |
| Baseline forage-water yield | `3.28 kg water kg^-1 DM` |
| Drinking availability while stationary at source | `10 kg h^-1` |

The `28 kg` normal stock is a transparent 70% of the existing synthetic
`40 kg` animal. The `1.56 kg d^-1` ordinary loss is the dry-condition water
requirement obtained by applying the allometric relation used by Underhill et
al. (2007) to `40 kg`. The forage-water yield, thirst trigger, and critical
boundary are synthetic scale choices, not macropod calibration.

The daily controller is deliberately small: inspect opening body water, visit
the single known source when it is at or below `26 kg`, travel out during hour
8, drink while stationary during hour 9, and return during hour 10. There is no
search, water-source choice, anticipation, renal response, or thermal forcing.

## Isolated Accounting

With no drinking, matched daily food-water inputs produce the expected result:

| Case | Food water | Ordinary loss | Excess eliminated | Daily change |
| --- | ---: | ---: | ---: | ---: |
| Deficit | `1.00 kg` | `1.56 kg` | `0 kg` | `-0.56 kg` |
| Neutral | `1.56 kg` | `1.56 kg` | `0 kg` | `0 kg` |
| Surplus | `1.80 kg` | `1.56 kg` | `0.24 kg` | `0 kg` |

Hourly and daily water balances close numerically. The normal stock is a cap,
not an unbounded storage pool.

## Water-Source Attribution

Adding one stationary drinking hour to the accepted two-leg excursion retains
its energy result. The off-window visit closes `1,400 kJ` below the no-trip
reference and the within-window visit closes `1,800 kJ` below it. Both realize
`2.13 kg` of drinking water, while the within-window route still loses two
feeding hours. Water benefit, route expenditure, and feeding opportunity are
therefore distinct outputs.

## Repeated Single-Patch Result

Over 60 days, the baseline forage-water yield produces 10 visits, no closer
than six days apart, and keeps body water between `25.64` and `28 kg`. Wetter
forage reduces visits to four; drier forage raises them to 20; greater ordinary
loss raises them to 18. Raising route cost changes energetic state but not the
thirst rule in this isolated comparison. A dry-forage treatment without a
source crosses the critical boundary on day 4, providing the explicit positive
control.

## Patch-System Integration

The water-disabled anchor exactly reproduces the accepted Goal 054 switch days
`1, 59, 98, 141, 170, 207, 234, 270, 297`, its `36,221 kJ` minimum body reserve,
and its `39,962 kJ` closing reserve. The water layer therefore does not alter
the existing food-patch system when disabled.

| Scenario | Completed days | Food switches | Water visits | Minimum water | Minimum energy reserve |
| --- | ---: | ---: | ---: | ---: | ---: |
| Baseline water | 305 | 12 | 40 | `25.37 kg` | `25,850 kJ` |
| Wetter forage | 305 | 9 | 11 | `25.88 kg` | `35,533 kJ` |
| Drier forage | 131 | 4 | 43 | `24.98 kg` | `1,593 kJ` |
| Greater ordinary loss | 213 | 8 | 56 | `24.91 kg` | `156 kJ` |
| Water route at `1,200 kJ` per leg | 305 | 13 | 38 | `25.27 kg` | `24,418 kJ` |

The drier-forage and greater-loss treatments terminate when the next energy
transition would make body reserve negative. Neither crosses the declared
critical water boundary first. This is an informative coupled result: frequent
`1,800 kJ` drinking excursions can create an energetic limit even when each
visit restores hydration. It is not evidence of real-animal viability, because
the parameters and endpoint remain synthetic.

The costlier route produces slightly fewer visits because its added energy
deficit raises appetite, increasing dry-matter intake and therefore food-derived
water. That small feedback is a consequence of the composed model, not
clairvoyance or a direct effect of route cost on thirst.

## Interpretation

The minimum water layer is accepted. It adds one conserved stock and one
familiar-source trigger without reopening the accepted forage-choice rule or
embedding a full water physiology. The results are green for implementation
and attribution, with one scientifically useful amber boundary: in dry or
high-loss conditions, access to water can be energetically unaffordable before
the animal becomes critically dehydrated.

Do not tune that boundary away. The next water-related layer should be earned
by a new question. Thermal forcing, dynamic plant moisture, renal adjustment,
multiple sources, search, and species calibration remain deferred.

## Primary Scale Evidence

- Underhill, L. G., Cherry, M. I., Oatley, T. B., & Kritzinger, J. J. (2007).
  A physiological assessment of the use of water point closures to control
  kangaroo numbers. *Wildlife Research* 34:280-288.
  https://doi.org/10.1071/WR06041
- Ealey, E. H. M., Bentley, P. J., & Main, A. R. (1965). Studies on water
  metabolism of the hill kangaroo, *Macropus robustus*. *Ecology* 46:473-479.
  https://doi.org/10.2307/1934878
- Denny, M. J. S., & Dawson, T. J. (1975). Effects of dehydration on body-water
  distribution in desert kangaroos. *American Journal of Physiology*
  229:251-254. https://doi.org/10.1152/ajplegacy.1975.229.1.251
