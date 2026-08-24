# Decision 0044: Explicit Patch Food Quality

Date: 2026-08-20

Status: accepted

## Question

Can patch-specific metabolizable-energy density enter the explicit spatial
runner without changing acquisition, movement, vegetation, or choice, and does
an all-stay patch reproduce the accepted non-spatial food-quality response
exactly?

## Design

The known-route landscape now stores one strictly positive
`metabolizable_energy_density_kj_kg_dm` value per patch. During every interval,
the explicit spatial runners use the property of the opening patch. The
standalone appetite runner retains its scalar food record; the spatial runner
no longer accepts a second, potentially conflicting food-energy parameter.

The retained comparison uses two static, non-depleting patches with identical
non-limiting acquisition ceilings of `0.025 kg DM h^-1`. The adequate patch is
`10,000 kJ kg DM^-1` and the lower-quality patch is `8,000 kJ kg DM^-1`. Each
animal stays in its opening patch for the whole day, so there is no travel,
feeding-time loss, route expenditure, forage depletion, or patch choice.

## Evidence

Both explicit all-stay cases reduce exactly, field for field, to the existing
non-spatial appetite runner at the corresponding energy density. Neither case
hits the forage-acquisition ceiling, and every hourly and daily energy account
closes.

| Patch | Energy density | Intake | Ingested energy | Combined energy change |
| --- | ---: | ---: | ---: | ---: |
| Adequate | 10,000 kJ kg DM^-1 | 0.3200 kg DM | 3,200 kJ | 0 kJ |
| Lower quality | 8,000 kJ kg DM^-1 | 0.3485 kg DM | 2,788 kJ | -412 kJ |

The lower-quality animal increases dry-matter intake through the accepted
appetite feedback, but the bounded response does not fully replace the lost
metabolizable energy within one day. This is the same accepted physiological
response seen outside explicit space, now transported through patch state.

## Interpretation

The result is expected and green. It establishes patch-specific food-energy
density as an explicit environmental property while retaining exact reduction
to the accepted physiology. It does not yet show a response to quality when
moving or choosing: the retained feeding-bout choice remains a deliberately
common-quality null and does not inspect the patch-specific density field.

The result is not evidence about digestibility, protein, fibre, water,
selection, learning, anticipation, depletion, or plant composition. Those
remain separate scientific decisions.
