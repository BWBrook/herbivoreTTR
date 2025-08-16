# Outstanding C++ Functions (Not Yet Translated to R)

Based on the conversation context and the contents of the `herbivore-ttr` repository (zip provided), the following C++ functions remain untranslated.  They are not present in the provided R scripts and therefore require translation.

| Function Name | Signature (C++) | Description | Full Function Body* |
|---|---|---|---|
| `transport_resistance(Plant& plant, Condition Conditions[], const int PLANTS_PER_PLOT, int dayofsim)` | See `daily_per_plant.cpp` | Implements the Thornley Transport Resistance (TTR) model for daily plant growth and nutrient transport. Updates carbon (C) and nitrogen (N) pools, biomass allocations (leaf, stem, root, defence), and related fluxes based on environmental conditions. | Code resides in `src/daily_per_plant.cpp`; includes sub‐functions such as `calc_SWforcer`, `trap1`, `trap2`, `monod`, `calc_RsC`, `calc_RrC`, `calc_tauC`, `calc_UC`, etc. |
| `herbivory_run(Herbivore& herbivore, Plant Plants[], const int PLOT_SIZE, const int PLANTS_IN_PLOT, const int PLANTS_IN_X, int dayofsim, std::mt19937_64& rnd_num_gen, std::ofstream& ofs_output)` | See `daily_per_plot.cpp` | Core daily behavioural loop for a single herbivore. Manages foraging, movement, intake, digestion, energy/water budgets, and outputs. Calls functions such as `calc_gut_capacity`, `calc_bite_size`, `calc_handling_time`, `calc_foraging_velocity`, `calc_required_energy_ratio`, `calc_cost_maintenance`, `calc_cost_locomotion`, `calc_plant_density`, `calc_difference_between_CN_ratios`, `pick_a_plant`, `herbivore_move`, `eat`, `incorporate_energy`, `digest_and_excrete`, `calc_water_requirement`. | Defined in `src/daily_per_plot.cpp`.  The logic is extensive; translation will require porting these helper functions as well. |
| `init_plants(Plant Plants[])` (C++) | See `init_aDGVM.cpp` | Initializes plant grid: assigns positions, vegetation types, biomass, carbon and nitrogen concentrations, and water content. Equivalent R function exists (`init_plants()`), but additional fields (e.g., `Md`, `Gd`, `RsC`, etc.) from C++ structure may not be fully represented.  Check and align. | Implementation in `src/init_aDGVM.cpp`. |
| `init_herbivore(Herbivore& herbivore)` (C++) | See `init_aDGVM.cpp` | Sets initial state of a herbivore: mass, type (grazer/browser/mixed), random position, foraging parameters, gut state, and behavioural flags.  The R version (`init_herbivore()`) covers most of these fields but may differ in units or missing parameters (e.g., digestion times for different food types). | Implementation in `src/init_aDGVM.cpp`. |
| **Many small helper functions** (e.g., `calc_gut_capacity`, `calc_bite_size`, `calc_foraging_velocity`, `calc_handling_time`, `calc_cost_maintenance`, `calc_cost_locomotion`, `calc_required_energy_ratio`, `calc_plant_density`, `calc_difference_between_CN_ratios`, `pick_a_plant`, `herbivore_move`, `eat`, `incorporate_energy`, `digest_and_excrete`, `calc_water_requirement`) | Various signatures | These support the main simulation. Some have been translated into R (`herbivore_calculations.R` and `herbivore_behaviour.R`), but not all.  Carefully verify each function has an R counterpart with equivalent logic and units. | See `src/daily_per_plot.cpp` and `inc/daily_per_plot.hpp`. |

\*Note: Full function bodies are not replicated here to avoid redundancy.  Refer to the original C++ files (not in the provided zip) for exact code.

### Ambiguities / Missing Context

The original conversation does not provide the entire list of C++ functions; some names and details may be missing.  Any function not appearing in the current R scripts should be considered potentially outstanding.  Flag uncertain or overloaded functions for closer examination during translation.


# Roadmap for Completing the Translation and Packaging

1. **Review and Catalogue Untranslated Functions**  
   – For each C++ function not present in the R code, document its role, parameters, and interdependencies.  
   – Confirm whether any functions have partial implementations in R (e.g., `init_plants` vs. `init_aDGVM` differences).  
   – Clarify ambiguous or overloaded functions.

2. **Translate Outstanding Functions to R**  
   – Implement `transport_resistance()` and its helper functions in R.  Ensure unit consistency (kg vs. g) and vectorised operations.  
   – Translate `herbivory_run()` and its helper functions.  Maintain R style (snake_case, modular design).  
   – Validate logic against C++ code and update constants accordingly.

3. **Refactor and Organize Code**  
   – Adopt one-function-per-file rule for R functions within `R/` directory; allow a shared utilities file for small helpers.  
   – Place translated C++ functions into a `c/` directory, one function per file, preserving any header declarations.  
   – Update namespace and exports accordingly (use `NAMESPACE` or roxygen tags in R).

4. **Construct a Devtools-Compatible Package**  
   – Create package skeleton with `DESCRIPTION`, `NAMESPACE`, `R/` directory, `man/` for documentation.  
   – Use roxygen2 comments in each R function for automatic documentation.  
   – Configure `renv` for isolated dependency management and `pak` for reproducible installs.  Commit `renv.lock`.

5. **Testing and Continuous Integration**  
   – Develop unit tests (e.g., using `testthat`) for each translated function, particularly the TTR and herbivory components.  
   – Include example data and a vignette to illustrate model usage.  
   – Set up GitHub Actions for R CMD check across multiple platforms.

6. **Future Extensions**  
   – After translation, incorporate soil nutrient cycling, excretion, and reproduction modules.  
   – Explore parameter calibration or sensitivity analyses.  
   – Integrate with `aDGVM2` or other ecological models, as suggested in the conversation context.


# Proposed Repository Structure for Devtools-Compatible Package

```
herbivoreTTR/                     # Package root (use a descriptive name)
├── DESCRIPTION                   # Package metadata (name, version, dependencies)
├── NAMESPACE                     # Exported functions and imports (auto-generated by roxygen)
├── R/                            # All R functions (one per file, except utilities)
│   ├── init_conditions.R         # Contains init_conditions()
│   ├── init_plants.R             # Contains init_plants() and placeholders for plant TTR fields
│   ├── init_herbivore.R          # Contains init_herbivore() and reset_daily_variables()
│   ├── herbivore_behaviour.R     # Contains functions: get_plants_within_range, calc_plant_tastiness, pick_a_plant, make_foraging_decision, herbivore_move, herbivore_step
│   ├── herbivore_calculations.R  # Contains: calc_gut_capacity, calc_bite_size, calc_handling_time, calc_foraging_velocity, calc_water_requirement, calc_foraging_traits, hourly_digestion_step, update_gut_content, check_daily_water_balance, calc_daily_energy_balance
│   ├── plants_TTR.R              # (Future) TTR-related functions (e.g., transport_resistance) when translated
│   ├── utils.R                   # General helper functions: select_randomly, calc_toroidal_distance, etc.
│   └── ...
├── c/                            # C++ source files (translated code from original)
│   ├── daily_per_plant.cpp       # TTR translation (one file per function)
│   ├── daily_per_plot.cpp        # Herbivory translation
│   └── ...
├── inst/
│   └── extdata/                  # Example input data or configuration files
├── man/                          # Auto-generated documentation (via roxygen2)
├── tests/
│   └── testthat/                 # Unit tests for package functions
├── vignettes/                    # Vignettes illustrating model usage
├── renv/                         # Dependency management; renv.lock stored here
│   └── renv.lock
├── .Rbuildignore                 # Files to exclude from package build (e.g. dev scripts, data)
└── next_steps_plan.md            # Planning document (this file)
```

### Configuration Notes
- **renv/pak**: Run `renv::init()` at project start to capture package dependencies; use `pak::pkg_install()` for package installation.  Commit `renv.lock` for reproducibility.  
- **DESCRIPTION**: Include package name (e.g., `herbivoreTTR`), version, title, description, author (Barry et al.), license, and imports (e.g., `dplyr`, `ggplot2`, `purrr`).  
- **NAMESPACE**: Generated via roxygen comments; ensures correct export of functions.  

# Suggested Sharing Method

Place `next_steps_plan.md` in the root of the reorganized repository.  Once the files are reorganized, create a zip archive and provide it to the user via the download facility.

