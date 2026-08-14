# Decision 0034: Prescribed Explicit-Patch Itinerary

Date: 2026-08-14

Status: accepted in the Arc 04 closure

## Question

Can explicit location and known-route movement be composed with the accepted
appetite-energy model for one deterministic day without introducing patch
heterogeneity or route choice?

## Contract

Prescribe the patch occupied at each of the 24 closing hourly boundaries. If
that patch equals the opening location, the animal stays. Otherwise, the runner
requires one declared directed route, suspends feeding during its one-hour
travel interval, adds route expenditure to ordinary routine activity, and
closes at the destination.

Actual feeding time lost is contextual: travel always suspends feeding, but it
loses an opportunity only when the interval would otherwise be open. For this
reference, all patches have the same static, non-depleting acquisition ceiling.

## Evidence

Two identical patches were connected by reciprocal routes costing `100 kJ`
each. The all-stay itinerary reduced exactly to the accepted one-day reference.
The round trip moved `A -> B` during closed hour 8 and `B -> A` during open hour
16.

| Itinerary | Moves | Travel | Feeding time lost | Intake | Movement cost | Combined change |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| All stay | 0 | 0 h | 0 h | 0.320000 kg DM | 0 kJ | 0 kJ |
| Round trip | 2 | 2 h | 1 h | 0.313494 kg DM | 200 kJ | -265 kJ |

The round trip recovered part of the missed `0.020 kg DM` through subsequent
appetite feedback. Its unrecovered `0.006506 kg DM` corresponds to about
`65 kJ`; together with `200 kJ` movement expenditure, this explains the
`-265 kJ` whole-system change. Hourly and daily energy identities closed. No
parameter was tuned to obtain the result.

## Interpretation

The spatial composer behaves as intended. It distinguishes travel duration
from feeding time actually lost, keeps location explicit at every boundary,
and exposes partial appetite compensation rather than hiding it in a movement
penalty. This is a mechanistic diagnostic result, not biological calibration.

Decision 0035 now varies static patch acquisition capacity under a prescribed
itinerary. Choice, spatial forage stocks, depletion, search, water, and
multi-day spatial dynamics remain deferred.
