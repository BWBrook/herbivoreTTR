# Decision 0033: Explicit Known-Route Spatial Anchor

Date: 2026-08-14

Status: accepted in the Arc 04 closure

## Context

Decision 0024 established that a minimally realistic known-route move has two
separable consequences: one lost feeding hour and one incremental `100 kJ`
movement charge. Those effects existed only as schedule edits without package
state for patches, animal location, or routes.

## Spatial Contract

Represent the first landscape as a plain patch table and a unique directed
route table. Do not introduce coordinates or a graph dependency before either
is needed by a scientific question.

Represent animal location as one patch identifier at an hourly boundary. Every
current route occupies exactly one hour: the animal starts at the origin, is in
transit and unable to feed during the interval, and occupies the destination at
the closing boundary. The route reports incremental movement expenditure
separately from maintenance and ordinary routine activity.

The animal is assumed to know the route. Route selection, search, uncertainty,
learning, and navigation remain absent.

## Verification

The package transition was composed with the existing hour-16 movement anchor.
Ordinary `50 kJ` activity continued, the route added `100 kJ`, maintenance
continued, and feeding was suspended for the hour.

| Treatment | Opening patch | Closing patch | Intake | Combined change |
| --- | --- | --- | ---: | ---: |
| Limited to adequate | limited | adequate | 0.282 kg DM | -481 kJ |
| Adequate to limited | adequate | limited | 0.265 kg DM | -650 kJ |

Both outcomes reproduce Decision 0024 within numerical tolerance. Location is
valid at both boundaries, travel duration and feeding time lost are exactly one
hour, movement expenditure is exactly `100 kJ`, and energy accounting closes.

## Interpretation

The historical movement evidence now has the smallest explicit spatial home.
Patch identity and movement are real package state and transition outputs, but
the transition does not manipulate appetite or body energy itself. This keeps
spatial state change separate from its physiological composition.

This transition is now composed by the prescribed deterministic itinerary in
Decision 0034. Choice, patch properties, multi-hour transit, distance, speed,
search, water, spatial forage stock, and depletion remain absent.
