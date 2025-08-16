.PHONY: setup run smoke test lint render clean

## Initialise the project: install packages via renv, set up pre-commit
setup:
	R -q -e "source('R/packages.R'); renv::init(bare = TRUE); renv::restore(prompt=FALSE)"
	- pre-commit install || true

## Run the full pipeline
run:
	R -q -e "targets::tar_make()"

## Run a smoke test pipeline (uses CI profile)
smoke:
	TARGETS_PROFILE=ci R -q -e "targets::tar_make(callr_function = NULL, ask = FALSE)"

## Run unit tests
test:
	R -q -e "testthat::test_dir('tests/testthat', reporter='summary')"

## Run linters
lint:
	R -q -e "lintr::lint_package(error_on_lint = TRUE)"

## Render the Quarto report
render:
	R -q -e "quarto::quarto_render('reports/paper.qmd')"

## Clean generated data and pipeline artifacts
clean:
	R -q -e "targets::tar_destroy(confirm = FALSE)"; rm -rf data/interim data/processed logs