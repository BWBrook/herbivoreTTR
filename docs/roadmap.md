# Roadmap

## Stage Map

| Stage | Question | Status |
| --- | --- | --- |
| 1. Herbivore core | Can intake, gut delay, expenditure, appetite, and simple forage constraints be understood as one energy system? | Closed |
| 2. Isolated plant-forage | Can a simple forage biomass stock remain stable under growth, loss, and later seasonal forcing without herbivory? | Closed; controlled forcing deferred until required |
| 3. Non-spatial coupling | How do herbivore intake and forage depletion alter one another in a homogeneous system? | Ready |
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
hourly and daily accounting. A linear turnover reference adds constant
production and proportional loss around a positive equilibrium, with an exact
analytic trajectory. A fixed residual threshold then derives non-negative
accessible biomass without changing the plant stock or defining animal intake.

The minimum constant core is ready for coupling. Controlled environmental
forcing is deferred so the stable plant null can anchor the first homogeneous
coupled reference. Herbivory begins in Stage 3; seasonality remains deferred.

## Deferred Animal Layers

Protein, water, thermoregulation, explicit mass feedback, gut composition,
reproductive allocation, and survival thresholds remain scientifically
important. They should be added one at a time after the forage and basic
coupling stages reveal which physiological detail can change a decision.
