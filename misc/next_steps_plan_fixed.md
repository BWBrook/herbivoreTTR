## Post-Translation Roadmap
1. **Review and prioritise function translations**: Evaluate the outstanding functions above, group them into logical modules (e.g., plant physiology, herbivore behaviour, climate processing) and prioritise translation to R. Responsible: Lead developer. Prerequisite: understanding of TTR model and simulation requirements.
2. **Translate C++ functions into R**: For each outstanding function, implement an equivalent R function preserving the original logic. Utilise vectorised operations where possible. Responsible: Assigned R developer. Prerequisite: R coding skills and knowledge of numerical methods.
3. **Integrate translated functions into the R package**: Place new R functions into the `R/` directory, update `NAMESPACE` via roxygen2 tags, and ensure consistent naming conventions. Responsible: Package maintainer.
4. **Write unit tests**: Create tests in `tests/testthat/` comparing outputs of the new R functions with expected results or with the original C++ implementation (if callable). Responsible: QA engineer. Prerequisite: Completed R translations.
5. **Update documentation**: For each new function, add roxygen2 comments to generate Rd files and update vignettes or docs explaining the model. Responsible: Documentation lead.
6. **Set up renv and pak**: Initialise an `renv` environment (`renv::init()`) to lock dependencies, and use `pak` for installing packages. Snapshot the environment (`renv::snapshot()`) and commit `renv.lock`. Responsible: DevOps / package maintainer.
7. **Prepare for devtools release**: Ensure the package passes `R CMD check`, update `DESCRIPTION` with metadata, and set up continuous integration (e.g., GitHub Actions) for automated testing and build. Responsible: Package maintainer. Prerequisite: Completed translations and tests.

## Repository Directory Layout
```markdown
/
  DESCRIPTION
  NAMESPACE
  R/
    # R function scripts (translated functions)
  C/
    cpp/
      # Original C++ source files
    hpp/
      # C++ headers
  C_to_do/
    # Outstanding C++ functions to translate (extracted)
  docs/
    # Documentation and design notes
  tests/
    testthat/
      # Unit tests for R functions
  man/
    # Generated Rd documentation via roxygen2
  renv/
    # renv environment files and library
  renv.lock
  next_steps_plan.md
```

- Configuration for `renv` and `pak`:
  - Use `renv::init()` to initialise a project-local library and lockfile.
  - Install dependencies with `pak::pkg_install()` which respects the lockfile.
  - Regularly run `renv::snapshot()` to update the lockfile after adding packages.
  - Share `renv.lock` in the repository to ensure reproducible environments for all developers.
