# Roadmap

## Stage Map

| Stage | Question | Status |
| --- | --- | --- |
| 1. Herbivore core | Can intake, gut delay, expenditure, appetite, and simple forage constraints be understood as one energy system? | Closed |
| 2. Isolated plant-forage | Can a simple forage biomass stock remain stable under prescribed growth, loss, and later seasonal forcing without herbivory? | In progress: stock accounting implemented |
| 3. Non-spatial coupling | How do herbivore intake and forage depletion alter one another in a homogeneous system? | Planned |
| 4. Explicit patches and movement | How do location, patch choice, travel time, and travel energy change intake and state? | Planned |
| 5. Landscape constraints and scenarios | How do water, depletion, heterogeneity, climate, and disturbance produce chronic stress? | Planned |

The detailed contracts are stored under `docs/arcs/`.

## Completed Herbivore Core

The retained animal system now provides:

1. an hourly body-energy ledger;
2. delayed energy release from one gut stock;
3. dry-matter to metabolizable-energy conversion;
4. periodic reference initialization;
5. maintenance and routine-activity expenditure;
6. a bounded body- and gut-responsive appetite target;
7. an external non-depleting forage-acquisition ceiling;
8. repeated-day state carry-over;
9. derived reserve tissue and total body mass; and
10. diagnostic treatments for feeding duration, implicit patch order,
    movement cost, and food quality.

The diagnostic treatments remain outside the package when they do not yet
justify generalized production state or behavior.

## Isolated Forage Progress

The plant side now has one homogeneous standing-biomass stock in
`kg DM ha^-1`, prescribed hourly growth and background-loss fluxes, and exact
hourly and daily accounting. These fluxes are diagnostic forcing, not plant
process equations.

The next decision gate is a minimal endogenous growth-and-loss formulation with
a known positive equilibrium and intelligible recovery from high and low
starting biomass. Herbivory, seasonality, and animal-facing availability remain
deferred.

## Deferred Animal Layers

Protein, water, thermoregulation, explicit mass feedback, gut composition,
reproductive allocation, and survival thresholds remain scientifically
important. They should be added one at a time after the forage and basic
coupling stages reveal which physiological detail can change a decision.
