# Decision 0057: Causal Hydration Response

Date: 2026-09-02

Status: accepted causal operational null; optimized daily scheduling remains
deferred

## Question

What changes when a familiar-source drinking trip can respond to body-water
state within the hourly day rather than only to the opening daily stock?

## Minimum Contract

The established daily-opening controller remains a frozen comparator. The new
controller uses the same `26 kg` thirst threshold and allows at most one
complete out-and-back source visit per day:

1. If thirst is already present at the opening boundary, retain the familiar
   hour-8 departure.
2. Otherwise, follow the no-source path until closing hourly body water first
   reaches the threshold.
3. Depart no earlier than that observed boundary, remain at the source for one
   drinking hour, and return along the known route.
4. If fewer than three suitable hours remain, defer the visit to the next day.

The implementation first runs the no-source day, locates the first crossing,
inserts the trip after it, and reruns the accepted daily engines. This is causal
rather than clairvoyant: the provisional and revised paths are identical up to
the decision boundary, which is checked directly. It avoids duplicating the
energy, forage, movement, or water transition engines.

Both controllers remain experiment-level behavioral rules. The water stock,
prescribed evaporative-loss interface, and spatial adapter are unchanged.

## Integration Repair

The first coupled comparison revealed that a water-source stay during an open
feeding hour was being included in the denominator for experienced food-patch
return. The animal consequently blamed its feeding patch for time spent
travelling and drinking, accumulated false forage inadequacy, and switched food
patches too often.

Experienced food return now uses only stationary, open feeding opportunities
in a food patch. Water travel still reduces intake and energy, but no longer
corrupts patch memory. The frozen daily-opening diagnostics are unchanged
because their source visits occur outside feeding hours.

## Prespecified Predictions

1. No source visit begins before thirst is observed.
2. Prescribed stress elicits within-day visits under the causal controller.
3. Faster response protects minimum body water under sustained forcing.
4. That protection imposes an energetic opportunity cost in the coupled model.
5. Sustained forcing is the strongest coupled stress and may reach an energy
   boundary before a critical-water boundary.
6. Equal cumulative loss need not produce equal coupled outcomes.

All six predictions were supported. They were frozen before the final
comparison and were not acceptance tests.

## Design

Both the isolated non-depleting forage system and the accepted dynamic
two-food-patch system branch after the same 60-day precondition. Each compares
the daily-opening and causal controllers across the Goal 056 control,
clustered, repeated, diffuse dose-matched, and sustained forcing calendars.
Treatment lasts 84 days and is followed, where the system remains executable,
by 42 days without incremental loss.

The clustered, repeated, and diffuse treatments each add `6.16 kg` of
evaporative loss. Sustained forcing adds `0.44 kg d^-1` for up to 84 days.

## Results

The isolated system completed every treatment and recovery. Causal response
raised minimum water by `0.15` to `0.59 kg` relative to daily opening and added
one to four source visits. Appetite compensation largely absorbed the cost, so
its endpoint energy effect was small and not consistently directional.

The forage-limited coupled system exposed a much sharper trade-off:

| Regime | Daily visits | Causal visits | Causal feeding opportunity displaced | Daily minimum water | Causal minimum water | Causal energy cost at last common day | Causal outcome |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| Control | 16 | 20 | `52 h` | `25.30 kg` | `25.89 kg` | `12,104 kJ` | 126 days |
| Clustered | 19 | 21 | `41 h` | `25.22 kg` | `25.74 kg` | `8,322 kJ` | 126 days |
| Repeated | 18 | 21 | `29 h` | `25.19 kg` | `25.74 kg` | `7,982 kJ` | 126 days |
| Diffuse dose control | 18 | 21 | `31 h` | `25.27 kg` | `25.86 kg` | `8,218 kJ` | 126 days |
| Sustained | 33 | 26 | `25 h` | `25.19 kg` | `25.74 kg` | `6,522 kJ` | energy boundary after 76 days |

Energy cost compares each causal run with its daily-opening counterpart on the
last day both completed. The daily-opening controller always travels at hours
8-10 and therefore displaces no open feeding opportunity. Causal trips respond
one hour after within-day detection and can overlap the evening feeding window.

All non-sustained coupled branches completed treatment and recovery. The causal
sustained branch completed 76 branch days and failed while attempting simulation
day 137 because the next body-energy transition would be negative. Its minimum
recorded reserve was `722 kJ`; minimum water was `25.74 kg`, well above the
`24 kg` critical boundary. It had received `33.44 kg` of the planned
`36.96 kg` incremental loss. This is an explicit energetic-access boundary,
not missing data or inferred mortality.

No branch crossed critical water. Every completed hourly and daily water,
energy, and forage account closed. All causal within-day visits departed at or
after their observed threshold boundary; their median detection-to-drinking
delay was one hour. A last-hour positive-control crossing was deferred rather
than producing an incomplete trip.

## Interpretation

Daily sampling understated the timing consequence of dehydration by routing
all drinking through a non-feeding morning window. Hourly response protects the
water stock, but the benefit is not free. In the isolated system, flexible
intake can mostly compensate. In the coupled system, finite forage opportunity
prevents full compensation, so drinking timing transfers stress from hydration
to energy.

The immediate-response controller is therefore accepted as a transparent
operational null, not as realistic optimal behavior. Its purpose is to expose
the trade-off cleanly. The next behavioral or thermal layer can ask whether an
animal delays, anticipates, or shifts activity to reduce that cost; it must not
silently optimize the present result away.

## Deliberate Deferrals

Temperature calibration, humidity, radiation, body temperature, shade seeking,
panting, licking, renal adjustment, anticipatory trip scheduling, dynamic plant
moisture, multiple sources, mortality, and species-specific inference remain
separate scientific decisions.
