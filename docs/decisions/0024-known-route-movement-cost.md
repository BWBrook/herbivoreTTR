# Decision 0024: Known-Route Movement Cost

Date: 2026-08-10

Status: implemented for ecological review; evidence only

## Context

Goals 022 and 023 established that prescribed patch order affects appetite,
intake, and energy partition under cost-free switching. Goal 024 adds the
smallest known-route movement representation: one lost feeding hour and one
additional locomotion charge, decomposed before any distance, search, choice,
or water process is considered.

## Decision

Retain one one-day `2 x 2` evidence diagnostic for each mixed patch order.
Use hour 16 as a prescribed transition. The time factor closes feeding and
acquisition for that hour while retaining its ordinary `50 kJ` activity charge.
The energy factor adds `100 kJ`, raising hour-16 activity to `150 kJ` while
maintenance continues. The combined treatment applies both.

The time-only and energy-only arms are attribution counterfactuals. The
combined arm is the minimally realistic known-route transition. All movement
objects and contrasts remain experiment evidence.

## Verification And Observations

Both cost-free arms reproduce Goal 022 exactly. Time-off arms retain 16
feeding hours and `800 kJ` routine activity. Time-on arms have 15 feeding
hours, zero intake at hour 16, and seven hours in the second patch. Energy-on
arms incur exactly `900 kJ` routine activity. All accounting closes.

The factor effects on closing combined energy are:

| Patch order | Lost feeding hour (kJ) | Movement energy (kJ) | Combined (kJ) |
|---|---:|---:|---:|
| limited then adequate | -133 | -73 | -205 |
| adequate then limited | -150 | -100 | -250 |

For limited-then-adequate exposure, the adequate destination patch permits
approximately `0.003 kg DM`, or `27 kJ`, of extra later intake after the
movement charge. Its nominal `100 kJ` energy penalty therefore closes at
`73 kJ`. The missed hour likewise costs `133 kJ`, less than its immediate
forgone intake because later intake partly compensates.

For adequate-then-limited exposure, the limited destination ceiling prevents
compensation. The missed hour costs exactly `150 kJ` of intake and the movement
charge costs exactly `100 kJ`. The combined penalty is `250 kJ`.

Time and energy effects are additive at numerical precision in both orders.
The combined treatments close as follows:

| Patch order | Realized intake (kg DM) | Closing combined deviation (kJ) |
|---|---:|---:|
| limited then adequate | 0.282 | -481 |
| adequate then limited | 0.265 | -650 |

Movement therefore increases the limited-then-adequate advantage from
`124 kJ` cost-free to `169 kJ` under both costs. This does not mean movement is
beneficial: both schedules become more negative. It means movement is less
damaging when the destination patch has enough acquisition capacity to permit
appetite-driven compensation.

No appetite bound engages, body reserve remains positive, and gut, body, and
whole-system accounting closes.

## Interpretation

The two-part movement representation is coherent and diagnostically useful.
Lost feeding time is the larger cost at this synthetic scale, while locomotion
energy can be partly offset only when the destination environment permits
additional intake. Patch order therefore matters through both forage exposure
and the animal's capacity to compensate after travel.

The result supports retaining one explicit movement duration and one explicit
energy charge in later spatial work. It does not justify distance, speed,
search, route choice, memory, or navigation mechanisms yet.

## Limits And Stop Boundary

This is one deterministic one-hour transition and one synthetic `100 kJ`
increment on one day. There is no alternate movement scale, repeated travel,
multi-day exposure, distance, speed, search, choice, water-source excursion,
geometry, forage stock, depletion, vegetation, calibration, or production
movement interface.

Further movement elaboration is unlikely to change the current architectural
decision. The next environmental discussion should instead consider a second
static patch property, preferably metabolizable food-energy density, before
depletion or plant dynamics are introduced.

The retained no-write client is:

```text
```

Generated evidence remains disposable under the ignored Goal 024 output
directory. Any food-quality or production promotion requires a separate
approved goal.
