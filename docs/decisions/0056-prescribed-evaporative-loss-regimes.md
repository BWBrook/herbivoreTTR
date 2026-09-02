# Decision 0056: Prescribed Evaporative-Loss Regimes

Date: 2026-09-02

Status: accepted prescribed forcing layer; thermoregulation remains deferred

## Question

Does the temporal pattern of an externally prescribed increment to evaporative
water loss alter drinking travel, hydration, and energy even when cumulative
water loss is held constant?

## Minimum Contract

The body-water schedule gains one non-negative hourly input,
`prescribed_incremental_evaporative_water_loss_kg_h`. It is subtracted from the
physical water stock separately from ordinary loss and is reported separately
in hourly and daily ledgers. A zero schedule is the exact Goal 055 model.

This is a forcing interface, not a thermoregulation model. Temperature,
humidity, radiation, body temperature, panting, licking, shade choice, renal
adjustment, activity shifts, and dynamic plant moisture remain absent.

Each treatment branches from the same state after 60 baseline days, runs for
84 treatment days, and then receives 42 days with no incremental loss. Positive
loss is applied equally across hours 10 through 15.

| Regime | Treatment schedule | Added loss |
| --- | --- | ---: |
| Control | None | `0 kg` |
| Clustered | Days 36-49 at `0.44 kg d^-1` | `6.16 kg` |
| Repeated | Seven two-day events at `0.44 kg d^-1` | `6.16 kg` |
| Diffuse dose control | `6.16 kg` spread over all 84 days | `6.16 kg` |
| Sustained | All 84 days at `0.44 kg d^-1` | `36.96 kg` |

The event increment raises total daily loss from the accepted ordinary
`1.56 kg d^-1` to `2.00 kg d^-1`. This is a transparent synthetic contrast,
not a temperature calibration.

## Prespecified Predictions

1. Zero incremental loss reduces exactly to Goal 055.
2. Equal cumulative loss need not produce equal energetic outcomes because
   drinking journeys are threshold-triggered.
3. Repeated events may impede recovery more than one clustered event.
4. Energy decline may precede critical dehydration under sustained forcing.

The predictions were frozen before the runs and were not acceptance tests.

## Results

All ten treatment branches completed 126 days with independently closed water,
energy, and, where active, forage accounts. No treatment crossed the declared
`24 kg` critical-water boundary.

### Isolated Non-Depleting Forage System

| Regime | Water visits | Added visits | Minimum water | Minimum energy | Debt at treatment end | Debt after recovery |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Control | 21 | 0 | `25.65 kg` | `38,387 kJ` | `0 kJ` | `0 kJ` |
| Clustered | 23 | 2 | `25.30 kg` | `38,079 kJ` | `-428 kJ` | `-428 kJ` |
| Repeated | 23 | 2 | `25.65 kg` | `38,289 kJ` | `-642 kJ` | `-643 kJ` |
| Diffuse dose control | 24 | 3 | `25.59 kg` | `38,352 kJ` | `790 kJ` | `755 kJ` |
| Sustained | 35 | 14 | `25.65 kg` | `38,074 kJ` | `1,068 kJ` | `0 kJ` |

Negative debt means the treatment reserve was above the control at that
checkpoint. It is not an energy benefit assigned directly to water loss.
Perturbing visit timing changes appetite compensation relative to the
control's ongoing trajectory, so a fixed endpoint can reverse the sign even
though every additional visit still incurs `1,800 kJ` of travel.

### Accepted Water-Constrained Patch System

| Regime | Water visits | Added visits | Source-travel increment | Food switches | Minimum water | Minimum energy | Debt at treatment end | Debt after recovery |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Control | 16 | 0 | `0 kJ` | 4 | `25.37 kg` | `25,850 kJ` | `0 kJ` | `0 kJ` |
| Clustered | 19 | 3 | `5,400 kJ` | 5 | `25.36 kg` | `25,850 kJ` | `3,133 kJ` | `2,914 kJ` |
| Repeated | 18 | 2 | `3,600 kJ` | 5 | `25.32 kg` | `24,050 kJ` | `3,136 kJ` | `2,061 kJ` |
| Diffuse dose control | 18 | 2 | `3,600 kJ` | 5 | `25.33 kg` | `24,050 kJ` | `3,136 kJ` | `1,116 kJ` |
| Sustained | 33 | 17 | `30,600 kJ` | 5 | `25.32 kg` | `851 kJ` | `30,133 kJ` | `28,112 kJ` |

Total movement also includes food-patch switches. The table therefore reports
the fixed source-travel component separately; each water visit uses two
`900 kJ` legs.

## Prediction Check

1. **Supported.** Zero schedules reproduce the Goal 055 transition and full
   patch-choice anchor exactly.
2. **Supported.** The three `6.16 kg` treatments differ in visit timing and
   recovery debt despite equal cumulative forcing. In the coupled system,
   recovery-end debt spans `1,116` to `2,914 kJ`.
3. **Not supported.** Repeated forcing did not impede recovery more than the
   clustered pulse. Coupled energy debt fell by `1,075 kJ` during recovery
   after repeated events but only `219 kJ` after the clustered event.
4. **Supported for this synthetic contrast.** Sustained forcing reduced the
   coupled minimum reserve to `851 kJ` while minimum body water remained
   `25.32 kg`, above the declared critical boundary.

## Interpretation

The forcing interface is accepted. Timing matters because a continuous water
stock is observed by a discrete daily-opening trigger, and the resulting trips
alter energy, appetite, and later patch use. Equal water dose is therefore not
equivalent to equal physiological consequence in the coupled model.

The sustained result strengthens the Goal 055 amber signal: energetic failure
can approach before critical dehydration when reaching water is costly. It is
not a viability estimate, and the residual debt after 42 recovery days is a
path-dependent outcome rather than evidence of irreversible physiological
damage.

The next thermal layer should map environmental conditions to this forcing
interface only after choosing an explicit heat-balance question. Laboratory
work shows temperature-dependent shifts among respiratory, cutaneous, and dry
heat-loss routes, with differences between red and eastern grey kangaroos;
dehydration and heat can also alter heterothermy. Recent field evidence links
high temperature to species-specific shade and water use. Those observations
justify a future mechanistic contract, but none is inferred from the current
synthetic `0.44 kg d^-1` increment.

## Evidence For The Deferred Thermal Layer

- Dawson, T. J., Blaney, C. E., Munn, A. J., Krockenberger, A., & Maloney,
  S. K. (2000). Thermoregulation by kangaroos from mesic and arid habitats:
  influence of temperature on routes of heat loss in eastern grey kangaroos
  and red kangaroos. *Physiological and Biochemical Zoology* 73:374-381.
  https://doi.org/10.1086/316751
- Dawson, T. J., Blaney, C. E., McCarron, H. C. K., & Maloney, S. K. (2007).
  Dehydration, with and without heat, in kangaroos from mesic and arid
  habitats: different thermal responses including varying patterns in
  heterothermy in the field and laboratory. *Journal of Comparative
  Physiology B* 177:797-807. https://doi.org/10.1007/s00360-007-0176-1
- Juillard, L. Q., Ashby, L. M., McEvoy, T. J., & Ramp, D. (2025).
  Thermoregulation strategies differ for large macropods during high
  temperatures. *Journal of Thermal Biology* 132:104245.
  https://doi.org/10.1016/j.jtherbio.2025.104245

## Deliberate Deferrals

Temperature calibration, humidity, radiation, body-temperature state,
panting, licking, shade choice, altered activity timing, plant moisture, renal
response, multiple water sources, mortality, reproduction, and species claims
remain separate decisions.
