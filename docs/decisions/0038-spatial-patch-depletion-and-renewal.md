# Decision 0038: Spatial Patch Depletion And Renewal

Date: 2026-08-14

Status: accepted

## Question

Can one co-located representative herbivore load create and release local
forage depletion while every patch and animal ledger remains conserved and the
new spatial coupling reduces to the accepted non-spatial and isolated models?

## Design

Each landscape patch receives one dynamic standing-forage stock, separate from
its static acquisition capacity. The same constant-production,
proportional-loss turnover acts in every patch each hour. Herbivory acts only
in the occupied opening patch during a prescribed stay; movement suspends
intake and removal. Location, gut energy, body reserve, and every patch stock
are carried explicitly between one-day runner calls.

The fixed diagnostic starts patches A and B at `1,000 kg DM ha^-1`, with common
equilibrium `1,000 kg DM ha^-1`, turnover `0.001 h^-1`, residual threshold
`500 kg DM ha^-1`, acquisition capacity `0.025 kg DM h^-1`, and representative
density `10 animals ha^-1`. It prescribes 30 days in A, one move from A to B at
closed hour 8 costing `900 kJ`, and 30 days in B. No parameter was adjusted
after the run began.

## Evidence

| Checkpoint | Patch A | Patch B |
| --- | ---: | ---: |
| Opening | 1,000.00 kg DM ha^-1 | 1,000.00 kg DM ha^-1 |
| End day 30 | 931.54 kg DM ha^-1 | 1,000.00 kg DM ha^-1 |
| End transfer day | 931.60 kg DM ha^-1 | 998.13 kg DM ha^-1 |
| End day 61 | 966.72 kg DM ha^-1 | 930.32 kg DM ha^-1 |

During the first 30 days, patch A lost `68.46 kg DM ha^-1` while patch B
remained exactly at equilibrium. After transfer, patch A gained
`35.12 kg DM ha^-1` and patch B lost `67.81 kg DM ha^-1` over 30 days. No stock
ceiling bound. The transfer occurred once, lost no feeding opportunity, and
added exactly `900 kJ` movement expenditure.

An all-stay two-patch run reproduces the accepted non-spatial animal and
occupied-patch trajectories exactly. Its unoccupied equilibrium patch
reproduces isolated forage turnover exactly. Hourly herbivory summed across
patches equals realized per-animal intake times density, and hourly and daily
patch, gut, body, and combined-energy balances close within arithmetic
tolerance.

## Interpretation

The expected directions are recovered cleanly. Local depletion follows
occupancy, autonomous renewal begins on release, and movement changes neither
patch through herbivory during the travel interval. This is the intended
dynamic-resource foundation, not yet a model of resource-aware animal choice.

Patch-specific production, patch areas, repeated or adaptive choice, water
physiology, richer forage composition, multiple animals, weather, and chronic
stress interpretation remain deferred. The next substantive decision is
whether to add one transparent choice that can observe current resource state
before considering a repeated policy.
