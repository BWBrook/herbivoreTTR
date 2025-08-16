# diamond

This repository implements a **diamond‑standard** research compendium template for quantitative ecology projects built with R.  It is intended as a starting point: clone or copy this directory, rename it for your project, and then replace the placeholder files and code with your own.  The structure emphasises reproducibility, separation of concerns, and automation.

## Structure overview

```
diamond/
├─ R/                     # Project functions and options
│  ├─ packages.R          # Centralised package installation/loading
│  └─ options.R           # Random seed, RNGkind, global options and logging
├─ _targets.R             # {targets} pipeline definition
├─ profiles/targets/      # Execution profiles for {targets}
│  ├─ local.R
│  └─ ci.R
├─ config/
│  └─ config.yaml         # Project configuration for data paths, profiles, etc.
├─ data/                  # Data hierarchy (raw/external/interim/processed)
│  ├─ raw/                # Immutable raw data (tracked by DVC/git‑annex)
│  ├─ external/           # Reference datasets
│  ├─ interim/            # Parquet/DuckDB caches (ignored by git)
│  └─ processed/          # Output tables/rasters ready for reports
├─ metadata/
│  ├─ data_manifest.csv   # Manifest of raw data files with checksums
│  └─ (additional EML or RO‑Crate files)
├─ reports/
│  └─ paper.qmd           # Quarto manuscript/report stub
├─ tests/testthat/        # Unit tests for functions and pipeline checks
├─ inst/containers/
│  ├─ Dockerfile          # Container specification for reproducible environment
│  └─ apptainer.def       # Apptainer/Singularity spec for HPC environments
├─ .github/workflows/ci.yml   # GitHub Actions continuous integration
├─ .pre-commit-config.yaml    # Pre‑commit hooks (styler, lintr, spell‑check, file size)
├─ .lintr                # Project linter configuration
├─ .gitignore            # Ignore logs, caches, and large intermediates
├─ .gitattributes        # Set LF line endings and diff drivers
├─ DESCRIPTION           # Research compendium metadata
├─ CITATION.cff          # Citation metadata
├─ LICENSE               # MIT license
├─ Makefile              # Conveniences: setup, run, test, lint, render, clean
└─ .env.example          # Example environment variables for secrets
```

### Quick start

After copying or cloning this repository, follow these steps:

```bash
# Initialise git and install hooks
git init
pre-commit install || echo "Pre‑commit not found; skipping hook installation"

# Set up R dependencies and lock them
make setup

# Run a smoke test of the pipeline (uses ci profile)
make smoke

# Run the full pipeline
make run
```

Raw data should live under `data/raw/` and be tracked with a large file management tool such as **git‑annex** or **DVC**; commit only the manifest and checksums.  Intermediates written by the pipeline are stored in `data/interim/` and are ignored by git.
