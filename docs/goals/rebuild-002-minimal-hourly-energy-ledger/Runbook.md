# Rebuild Goal 002 Runbook

## Purpose

This is guarded execution guidance for Goal 002 after explicit authorization.
It does not itself authorize implementation, commit, or push.

## Stop Rules

- Stop on any unexpected dirty path, changed upstream, missing tool, failed
  command, or ambiguous scientific requirement.
- Do not reset, clean, stash, force, amend, delete unrelated material, or widen
  the changed-path set.
- Do not add a package dependency, configurable time step, gut process,
  activity cost, calibration, or persistent output.
- Do not copy from `herbivoreTTR-legacy`.
- Treat temporary command timeouts as observation intervals, not process
  deadlines.

## 1. Authorization And Preflight

After explicit execution authorization, verify the expected formulation state:

```zsh
set -euo pipefail
REPO=/Users/bwbrook/git/herbivoreTTR
BASE=ca2c9711f8e81831180a1c4875de44f84f964498

: "${AUTHORIZED_GOAL_SHA256:?Use the SHA-256 reported in the approved closeout}"
: "${AUTHORIZED_PLAN_SHA256:?Use the SHA-256 reported in the approved closeout}"
: "${AUTHORIZED_RUNBOOK_SHA256:?Use the SHA-256 reported in the approved closeout}"

test -d "$REPO/.git"
test "$(git -C "$REPO" branch --show-current)" = main
test "$(git -C "$REPO" rev-parse HEAD)" = "$BASE"
test "$(git -C "$REPO" rev-parse origin/main)" = "$BASE"
test "$(git -C "$REPO" ls-remote origin refs/heads/main | awk '{print $1}')" = "$BASE"
test "$(git -C "$REPO" remote get-url origin)" = \
  git@github.com:BWBrook/herbivoreTTR.git
test "$(git -C "$REPO" remote get-url --push origin)" = \
  git@github.com:BWBrook/herbivoreTTR.git
test ! -e "$REPO/outputs"

printf '%s  %s\n' \
  "$AUTHORIZED_GOAL_SHA256" \
  "$REPO/docs/goals/rebuild-002-minimal-hourly-energy-ledger/Goal.md" \
  "$AUTHORIZED_PLAN_SHA256" \
  "$REPO/docs/goals/rebuild-002-minimal-hourly-energy-ledger/Plan.md" \
  "$AUTHORIZED_RUNBOOK_SHA256" \
  "$REPO/docs/goals/rebuild-002-minimal-hourly-energy-ledger/Runbook.md" \
  | shasum -a 256 -c -

diff -u \
  <(printf '%s\n' \
    '?? docs/goals/rebuild-002-minimal-hourly-energy-ledger/Goal.md' \
    '?? docs/goals/rebuild-002-minimal-hourly-energy-ledger/Log.md' \
    '?? docs/goals/rebuild-002-minimal-hourly-energy-ledger/Plan.md' \
    '?? docs/goals/rebuild-002-minimal-hourly-energy-ledger/Runbook.md' \
    | LC_ALL=C sort) \
  <(git -C "$REPO" status --short --untracked-files=all | LC_ALL=C sort)
```

If any observation differs, stop without editing.

## 2. Test-First Implementation

Work only in the declared file surface. Create tests before each corresponding
implementation unit and show that they fail for the expected missing behavior.

Before each red run, parse the new test file with `parse(file = ...)`. Inspect
the structured testthat results and call stacks. The red phase is valid only if
all failures identify the expected missing public interface or unmet declared
contract, with no malformed test, package-load failure, missing dependency,
unexpected warning, or skip. Otherwise stop before implementation.

Focused test commands:

```zsh
cd /Users/bwbrook/git/herbivoreTTR
Rscript --vanilla -e \
  'testthat::test_local(".", filter = "body-energy-records")'
Rscript --vanilla -e \
  'testthat::test_local(".", filter = "body-energy-transition")'
Rscript --vanilla -e \
  'testthat::test_local(".", filter = "body-energy-scenarios")'
```

For each file, retain a compact red/green result in the live execution report,
not in the repository. Do not retain test transcripts.

The implementation must preserve these interface boundaries:

```text
records:    state, parameters, schedule validation
transition: one fixed one-hour state change and flux report
runner:     24 transitions and summary derived from the ledger
experiment: fixture construction, in-memory assertions, stdout summaries only
```

## 3. Generate Declared Package Documentation

Use the existing roxygen convention only after the public interfaces are
stable:

```zsh
cd /Users/bwbrook/git/herbivoreTTR
Rscript --vanilla -e \
  'stopifnot(requireNamespace("roxygen2", quietly = TRUE)); roxygen2::roxygenise()'
```

Inspect `NAMESPACE` and every changed `man/` file. Stop if roxygen changes an
undeclared path or if satisfying documentation would require a new dependency.
`DESCRIPTION` may be edited manually for package metadata, but roxygen must not
alter it.

## 4. Functional Validation

Run all focused tests and the full package tests:

```zsh
cd /Users/bwbrook/git/herbivoreTTR
Rscript --vanilla -e \
  'testthat::test_local(".", filter = "body-energy-records")'
Rscript --vanilla -e \
  'testthat::test_local(".", filter = "body-energy-transition")'
Rscript --vanilla -e \
  'testthat::test_local(".", filter = "body-energy-scenarios")'
Rscript --vanilla -e 'testthat::test_local(".")'
```

Verify repository integrity and dependency stability:

```zsh
cd /Users/bwbrook/git/herbivoreTTR
Rscript --vanilla -e \
  'status <- renv::status(); stopifnot(isTRUE(status$synchronized))'
git diff --check
test ! -e outputs
test "$(git diff -- renv.lock)" = ''
```

Also run `git diff --no-index --check /dev/null -- FILE` for every untracked
file, accepting only exit status 0 or 1 and requiring empty command output.
This extends whitespace/error checking to files that `git diff --check` cannot
see.

## 5. External Package Validation

Build and check outside the repository, with guarded cleanup:

```zsh
set -euo pipefail
REPO=/Users/bwbrook/git/herbivoreTTR
TMP=$(mktemp -d /tmp/rebuild002-check.XXXXXX)
cleanup() {
  case "$TMP" in
    /tmp/rebuild002-check.*) rm -rf -- "$TMP" ;;
    *) printf '%s\n' 'Unsafe temporary path; stop.' >&2; return 1 ;;
  esac
}
trap cleanup EXIT

cd "$TMP"
R CMD build "$REPO"
TARBALL=$(find "$TMP" -maxdepth 1 -type f \
  -name 'herbivoreTTR_*.tar.gz' -print -quit)
test -n "$TARBALL"
mkdir "$TMP/library"
R CMD INSTALL --library="$TMP/library" "$TARBALL"
R_LIBS_USER="$TMP/library" Rscript --vanilla \
  "$REPO/experiments/rebuild-002-body-energy-ledger.R"
R CMD check --no-manual "$TARBALL"
grep -Fx 'Status: OK' "$TMP/herbivoreTTR.Rcheck/00check.log"

cd "$REPO"
test ! -e "$REPO/outputs"
test ! -e "$REPO/herbivoreTTR.Rcheck"
test -z "$(find "$REPO" -maxdepth 1 -type f \
  -name 'herbivoreTTR_*.tar.gz' -print -quit)"
```

Stop on any warning, note, error, retained product, or failed cleanup.

The installed-package experiment must assert its own expected values and print
exactly three daily rows whose status, observed daily change, and final reserve
are:

```text
neutral    0        5000
deficit  -240       4760
surplus   240       5240
```

It must create no file or directory.

## 6. Exact Scope Review

Before closeout, compare the changed paths with this exact whitelist:

```text
DESCRIPTION
NAMESPACE
R/herbivoreTTR-package.R
R/body-energy-records.R
R/body-energy-transition.R
R/body-energy-run.R
README.md
docs/decisions/0002-ledger-before-gut.md
docs/model-charter.md
docs/model-specification.md
docs/roadmap.md
docs/variable-dictionary.md
experiments/rebuild-002-body-energy-ledger.R
man/herbivoreTTR-package.Rd
man/new_body_energy_state.Rd
man/new_body_energy_parameters.Rd
man/new_assimilated_energy_schedule.Rd
man/step_body_energy.Rd
man/run_body_energy_day.Rd
tests/testthat/test-body-energy-records.R
tests/testthat/test-body-energy-transition.R
tests/testthat/test-body-energy-scenarios.R
docs/goals/rebuild-002-minimal-hourly-energy-ledger/Goal.md
docs/goals/rebuild-002-minimal-hourly-energy-ledger/Plan.md
docs/goals/rebuild-002-minimal-hourly-energy-ledger/Runbook.md
docs/goals/rebuild-002-minimal-hourly-energy-ledger/Log.md
```

Missing paths are acceptable only when roxygen groups documentation without
losing an interface. Extra paths are not acceptable without review and explicit
scope amendment.

Construct the actual changed-path inventory from both
`git diff --name-only` and `git ls-files --others --exclude-standard`, sort it
uniquely, and prove that every result is in the whitelist above. Require
`git diff --cached --name-only` to be empty at this pre-authorization review
gate. Review every tracked diff and every complete untracked file; a summary or
`git diff` alone is insufficient.

The review packet consists of:

- complete Git diff and changed-path inventory;
- exact public interfaces and schemas;
- red/green and final test counts;
- the three compact scenario summaries;
- synchronized `renv`, build, and check evidence;
- proof of absent persistent outputs; and
- final local and remote Git state.

Use at least one independent scientific-contract reviewer and one independent
code/diff reviewer. Treat their reports as evidence leads and verify material
claims directly.

## 7. Commit And Push Boundary

Do not stage, commit, or push unless Barry's authority explicitly includes
those operations after review. If authorized, stage exact reviewed paths only,
create one commit named:

```text
Implement minimal hourly energy ledger
```

Immediately before staging, recheck that the three frozen packet hashes match
the values Barry authorized, the index is empty, local `HEAD` and `origin/main`
equal `BASE`, and live `refs/heads/main` from `git ls-remote origin` still equals
`BASE`. Recheck that both `git remote get-url origin` and
`git remote get-url --push origin` equal
`git@github.com:BWBrook/herbivoreTTR.git`. Stop if any check differs.

Immediately before pushing, run `git fetch --prune origin` and require
`origin/main` and live `refs/heads/main` to remain at `BASE`. Then push `main`
by ordinary fast-forward only after again verifying both fetch and push URLs
equal `git@github.com:BWBrook/herbivoreTTR.git`. Verify local `HEAD`,
`origin/main`, and the remote `main` SHA are identical. No amend, force push,
tag, release, or additional commit is permitted.

## 8. Stop

Report the implemented outcome, exact equations and assumptions, scenarios,
validation, changed paths, Git state, and residual scientific risks. Stop before
food, gut, digestion, activity, or any later layer.
