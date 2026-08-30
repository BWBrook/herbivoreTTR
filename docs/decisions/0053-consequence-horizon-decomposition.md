# Decision 0053: Consequence-Horizon Decomposition

Date: 2026-08-30

Status: accepted diagnostic; short-horizon failure localized

## Question

Does the Goal 052 rapid rotation remain favourable when the same move-now and
stay-now choices are evaluated beyond two days, or does a longer consequence
horizon reveal value in resting a recently released patch?

## Design

The exact Goal 052 opening states are captured before its first two reciprocal
rotation decisions:

- day 60, while the animal is in depleted higher-quality patch B and is about
  to move into well-rested lower-quality patch A; and
- day 62, while the animal is in A and is about to return to B after only two
  days of release.

From each identical opening state, two prescribed policies are compared over
`1, 2, 4, 7, and 14` days: stay now and remain in the opening patch, or move now
and remain in the destination. There are no later choices within a policy.
Animal physiology, forage turnover and removal, density, patch qualities, and
the `900 kJ` route are unchanged.

The evaluator records final animal-system energy, ingested energy, movement
expenditure, body reserve, and both forage stocks. It is diagnostic information
unavailable to the animal and is not a proposed cognitive mechanism.

## Observations

| Horizon | Day 60: B to A advantage | Action | Day 62: A to B advantage | Action |
| ---: | ---: | --- | ---: | --- |
| 1 day | `-295 kJ` | stay | `-350 kJ` | stay |
| 2 days | `511 kJ` | move | `450 kJ` | move |
| 4 days | `2,121 kJ` | move | `407 kJ` | move |
| 7 days | `4,537 kJ` | move | `-2,009 kJ` | stay |
| 14 days | `10,174 kJ` | move | `-7,646 kJ` | stay |

Every comparison pays exactly `900 kJ` when moving, closes its accounts, and
satisfies:

```text
move advantage = intake-energy advantage - movement disadvantage
```

At day 60, moving into A gains `1,411 kJ` of intake over two days and
`11,074 kJ` over fourteen days. A has received a long release interval, so the
benefit of moving strengthens monotonically with horizon despite its lower
energy density. Over fourteen days, moving leaves A/B at
`762.98/642.75 kg DM ha^-1`, whereas staying leaves A/B at
`1,000/500 kg DM ha^-1`; closing body reserve is `10,029 kJ` higher after the
move policy.

At day 62, returning to B gains `1,350 kJ` of intake over two days and
`1,307 kJ` over four days. Over seven days the intake difference reverses to
`-1,109 kJ`; over fourteen days it reaches `-6,746 kJ`. If the animal stays in
A for fourteen days, B recovers to `659.50 kg DM ha^-1`. If it returns
immediately, B closes at the `500 kg DM ha^-1` residual boundary while released
A recovers to `972.93 kg DM ha^-1`. Moving leaves closing body reserve
`552 kJ` higher over four days, but `1,864 kJ` lower over seven and `7,501 kJ`
lower over fourteen.

## Interpretation

The rapid rotation is not symmetric. Leaving depleted B for well-rested A is
supported at every horizon of two days or longer. The damaging step is the
return to B after only two days: high food quality makes that move attractive
briefly, but B cannot sustain the resulting intake and the decision reverses
between four and seven days.

Goal 052 therefore failed because its learned scalar return describes how good
a patch is immediately after release, but not how long that return can persist.
The missing information is expected resource depth or bout duration, not a
slower recovery rate and not a generic aversion to movement. The operational
null's long residence intervals protected the system accidentally by allowing
the destination to accumulate durable feeding opportunity.

Do not give the animal a seven- or fourteen-day perfect forecast, and do not add
an arbitrary cooldown. The next behavioral design should ask whether an animal
can learn a simple persistence cue from its own prior residence duration or
declining experienced returns, then test that cue without current unvisited-
patch biomass information.
