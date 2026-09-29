# Red-kangaroo accounting and acquisition benchmark (065)

Declared 29 September 2026 before executing the new comparison. Barry approved
the red-kangaroo work in Codex; correspondence 56, message 774 records his
exact approval. The source papers, published fitted curve and earlier mean
budget arithmetic were already inspected. This is a prospective computational
design using known evidence, not registration before seeing the data.

## Question, scope and stopping point

Can documented red-kangaroo records close Munn's daily energy/water budgets,
and what conditional compatibility does the existing appetite/encounter/stock
minimum have with Short's observed yard-scale response?

Implement no-write R experiment clients and study-specific empirical records
alongside the synthetic reference. Munn is daily accounting; Short is
acquisition and shared-stock accounting, without gut, body-reserve or movement
dynamics. Preserve the existing package, synthetic fixture and frozen 061–064
experiments. Neither a full dynamic species fixture, Ash plant variants,
departure-memory repair nor a chronic-decline experiment is included.

Stop after the declared comparisons, a compact figure and tables, targeted
verification, one independent scientific audit, and a decision/evidence update.
Commit and push source/docs under Barry's standing authorisation and report on
the board. An unexpected mismatch is a result; do not enlarge the grid or
tune a mechanism to remove it.

## Munn: daily closure and a feasible water family

The source records are Munn 2009 Tables 1–2, Munn 2010 methods and the 2011
corrigendum, as documented in [the evidence assessment](empirical-anchor-evidence.md).
Retain the mature dry female context, 23.6-kg mean mass, 4,872-kJ/day FMR,
2,141-kJ/day predicted BMR, 66.7% body-water fraction, 1.5-L/day water turnover
and 10.4-h/day active harvesting. Treat litres of water as kilograms for this
accounting. Reported standard errors stay labelled as standard errors.

1. Reproduce the corrected energy-derived DM requirement with the printed
   9.4-kJ/g DE. Separately use assumed ME:DE = 0.9, yielding 8.46-kJ/g ME.
   The former replicates the published conversion; it does not measure ME:DE=1.
   FMR is the total expenditure target, not maintenance plus extra costs.
   The package's food-energy conversion checks units and totals using uniform
   hourly bookkeeping; it does not imply an observed feeding schedule.
2. Report the product of mean mass and body-water fraction, unresolved FMR
   minus predicted BMR, and mean intake per observed active harvesting hour.
   None estimates reserve capacity, dehydration thresholds, hourly appetite
   capacity or a locomotion coefficient. Steady mean body energy is an
   assumption of energy-derived intake.
3. For a steady mean water pool, calculate
   `required_drinking = turnover - food_yield * intake - metabolic_water`.
   Show food yields 0, 0.5, 1, 1.5, 2, 2.5 and the synthetic 3.28 kg/kg DM;
   metabolic water 0 and illustrative 0.15 kg/day. These are accounting
   scenarios, not measurements or a fitted physiology model. Negative required
   drinking marks an infeasible combination, not a flux to clip away. Keep
   food-derived and metabolic water separate; do not alter the water API.
4. Report deterministic corners using FMR and apparent DM digestibility at
   their reported mean ± one SE, gross energy fixed at 18 kJ/g, both energy
   conversions, and turnover at mean ± one SE. These are sensitivity corners,
   not a joint confidence interval, a population range or independent draws.
   Also report the small difference between printed DE and 18 × 0.521.

The corrected DMI is derived from FMR; its energy closure is a calibration and
unit check, not independent biological validation. Food water above mean
turnover rejects a particular steady-budget combination, not all uncertain
diets or individual water states. Preserve seven introduced versus six/five
analysed animals when reporting the whole-enclosure removal scale. Prescribed
nonlimiting food suffices here; no individual competitors are needed.

## Short: source reconstruction and the observation operator

Use the supplied Short 1985 PDF identified in `references/README.md`.
Reconstruct the 12 clearly visible Fig. 4 points, retaining the five filled
yard-1 and seven open yard-2 symbols. Preserve pixel centres, page/render
calibration and approximate reading allowances of ±10 kg DM/ha and
±20 g DM/animal/day. Those allowances concern digitization only. The points
are already running two-point intake averages; do not smooth them again or
invent their interval dates. Fig. 1(c) pasture/bluebush stock readings can
provide a separate contextual depletion check, with their log-axis reading
uncertainty. Do not equate those dates to Fig. 4 intervals.

For the model use a 400-m2 shared yard with two consumers, density
`D = 50 animals/ha`. Edible standing stock is `B` (kg DM/ha), its unavailable
residual is `R`, and constant rejected standing material `J` is a separate
observation offset: combined vegetation is `V = B + J`.

At each one-hour accounting step, apply prescribed net plant flux, record
actual growth/loss (loss bounded by standing stock), and then candidate
per-animal intake

`min(C / 24, S * max(B_before_grazing - R, 0) / (10000 * 24))`.

Use the existing `step_forage_herbivory` mass-removal primitive to apply animal
density and the shared accessible-stock bound. The fixed daily cap is
`C = 0.709 kg DM/animal/day`; reference effective daily search exposure is
`S = (0.709 / 84) * 10000 m2/day`, derived conditionally from Short's printed
curve. Uniformly distributing these daily rates is an explicit timing
approximation, not 24 measured feeding hours. Short does not identify hourly
q or feeding duration. The fitted asymptote is a model scenario cap, not an
observed maximum that every reconstructed point must fall below.

Probe independent four-day windows starting at edible stocks 0, 5, ..., 700
kg DM/ha. These define a response locus, not reconstructed yard histories.
The corrected stock-loss estimator for each adjacent two-day interval is
`1000 * (V_start - V_end) / (D * 2)` g/animal/day, then the two adjacent
estimates are averaged once. Trampling is already corrected in the observed
points; the benchmark assumes that correction is exact. Net uncorrected
production or loss remains visible as the difference between stock-loss
intake and true ingestion. No claim of recovering the trampling correction
is made.

The unknown x pairing is a declared observation sensitivity. Use four-day
opening, temporal midpoint and closing stocks (`V0`, `V2`, `V4`), with midpoint
primary. The source does not state that x was smoothed. Report the
endpoint-weighted alternative `(V0 + 2*V2 + V4)/4` once for the primary locus
as a sensitivity within that bracket; do not multiply the full grid by further
unsupported pairing conventions or select one by fit.

## Frozen Short scenarios and reporting

- Primary: reference S, R=0, net plant flux=0, J=0, four-day midpoint pairing.
- Cross S multipliers {0.5, 1, 2}, R {0, 20 kg DM/ha}, and net plant flux
  {-2.5, 0, +2.5 kg DM/ha/day}: 18 acquisition scenarios. The flux scale shifts
  stock-loss intake by about 50 g/animal/day when not stock-bounded; it is an
  effect-scale sensitivity, not an empirical growth bound. R=20 is a stress
  value, not a fitted threshold or lower bound inferred from "below 20".
- Apply J {0, 84 kg DM/ha}, one published response-density scale as a
  horizontal-shift stress, and all three x pairings as observation transforms.
  Constant J has no effect on ingestion or stock loss.
- Include one separate synthetic-threshold reference with S at its reference,
  R=200, zero net plant flux and J=0. It is an intentionally contrasting
  threshold scenario, not part of estimating a red-kangaroo residual.

Interpolate each response locus only within its supported combined-biomass
domain. Report signed residuals, RMSE overall and by yard, and whether model
and observation overlap under digitization-only allowances. Compare with the
published curve evaluated at the same points, clearly as an in-sample
descriptive reference. No RMSE cutoff, likelihood, P-value, uncertainty
interval for parameters or biological-validation pass is defined. Do not
count the dependent smoothed points as treatment replication or select a
preferred nuisance scenario on goodness of fit.

Retain R/J as different concepts but do not infer them separately from this
response. A no-growth matched-total-offset comparison of `(R,J)=(0,84)` and
`(20,64)` demonstrates their aliasing over common combined-biomass support.
No additional coefficient fitting or grid search follows the observed errors.
Check the primary response locus with half-hour numerical steps once; require
differences below the digitization allowances above, or report numerical
sensitivity before interpreting the comparison. Step refinement tests the
numerics, not the unmeasured feeding schedule. No scientific scenarios change.

## Verification and outputs

Check exact animal-density scaling, conservation, nonnegative stock, residual
protection during grazing, limiter accounting, and stock-loss/ingestion
equality with no net plant flux. Verify four-day smoothing, every x transform,
and invariance to the constant rejected offset. Reproduce independent
analytical depletion cases and compare numerical step sizes. Check Munn's
energy conversion and water identities, including infeasible combinations.
Run affected package tests, parse retained R and use `git diff --check`.

Retain source inputs and reconstruction provenance under `references/`;
do not commit the PDFs, overlays or generated analysis. Functions return
plain tables and optional plotting writes only to a supplied path. Generated
tables, RDS and a standalone review PDF belong in ignored
`outputs/red-kangaroo-065/`. Accepted conclusions go in Decision 0065.
