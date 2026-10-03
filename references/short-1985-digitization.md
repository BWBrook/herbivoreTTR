# Short 1985: reconstructed plotted observations

`short-1985-figure4.csv` contains approximate readings of all 12 visible
kangaroo symbols in Fig. 4, printed page 440 (PDF page 7), in the supplied
paper identified by SHA-256
`f4461cf991cffea467bcfda4797b110daa39661d42346c1b07b3323ad0e676ce`.
The primary reference is Short (1985), Journal of Applied Ecology 22:435–447,
[JSTOR](https://www.jstor.org/stable/2403176).

The page was rendered with Poppler at 200 dpi, 1300 × 1923 pixels. Pixel
coordinates use the full page, origin at upper left. The horizontal axis is
linear, 0–600 kg DM/ha of combined pasture and bluebush; the vertical axis is
linear, 0–1000 g DM/animal/day. The CSV retains selected symbol centres and
values rounded to 5 units, with conservative plot-reading allowances of
±10 kg DM/ha and ±20 g DM/animal/day. These are not standard errors or total
measurement uncertainty. The printed fitted curve did not determine point
values. Filled symbols are yard 1 (five points), open symbols yard 2 (seven).

Short describes intake as trampling-corrected vegetation loss, divided by
animals and elapsed time, followed by running two-point averages. Kangaroo
vegetation was assessed every two days according to the methods. The paper
does not specify which biomass timestamp accompanies each smoothed intake
point or whether biomass was also averaged. Yard identities are known, but
interval dates and raw intake observations cannot be assigned from Fig. 4
alone. The values must not be smoothed again or treated as twelve independent
experimental replicates.

`short-1985-figure1c.csv` separately reconstructs 32 visible pasture and
bluebush symbols in Fig. 1(c), printed page 438 (PDF page 5), at days
1, 3, 5, 7, 9, 10, 11 and 12. Triangles are yard 1, circles yard 2;
filled symbols are pasture and open symbols bluebush. Days without visible
symbols are omitted. This is not an independent intake dataset and does not
uniquely identify the intervals of the Fig. 4 symbols. The cross-figure
candidate reconstruction below supplies additional, qualified timing evidence.

This page used the same 200-dpi full-page render and pixel origin. Its biomass
axis is logarithmic: ticks 1000, 500, 100, 50, 10, 5 and 1 kg DM/ha occur at
y pixels 913, 963, 1075, 1123, 1235, 1284 and 1397. Least-squares calibration
gives `log10(B) = 8.67559899115359 - 0.00621180011577811 * pixel_y`.
Back-transform the centre and its ±6-pixel reading allowance, widened to
±10 pixels for overlapping symbols; the CSV rounds biomass to 0.1 kg DM/ha.
Bounds express visual ambiguity only, not sampling uncertainty. The selected
x pixels for the retained days are 860, 912, 964, 1015, 1066, 1092, 1117 and
1143. No additional separation of overlapping symbols was inferred.

Summing the two plotted components gives approximate day-1 combined stocks
of 588 and 610 kg DM/ha and day-12 stocks of 79 and 98 kg DM/ha in yards 1
and 2. These contextual sums describe depletion; they neither estimate a
constant rejected offset nor separate growth, trampling and ingestion.

Local source renders, labelled overlays and extraction notes are retained
only in ignored `outputs/short-065-reconstruction/`. The full PDF remains in
ignored `references/papers/`. Numerical readings and this provenance note are
research inputs; the original paper and rendered pages are not redistributed.

## Cross-figure timing audit, 2 October 2026

Fable's correspondence message 814 proposed matching Fig. 4 x values to
combined pasture-plus-bluebush stocks at Fig. 1(c) sampling occasions. An
independent R calculation and source-figure inspection reproduce the following
11 nearest-centre, same-yard matches. This is a candidate reconstruction,
not recovered date metadata. The CSV inputs above remain unchanged.

| Point | Yard | Shared day | Fig. 4 x (kg DM/ha) | Fig. 1(c) combined stock (kg DM/ha) | Adjacent intervals (days) | Raw loss (g DM/animal/day) | Raw minus plotted intake (g DM/animal/day) |
| --- | ---: | ---: | ---: | ---: | --- | ---: | ---: |
| K05 | 1 | 3 | 495 | 475.8 | 2 + 2 | 1153.5 | 508.5 |
| K04 | 1 | 5 | 360 | 357.2 | 2 + 2 | 1225.5 | 300.5 |
| K03 | 1 | 9 | 185 | 183.6 | 2 + 1 | 925.5 | 100.5 |
| K02 | 1 | 10 | 115 | 114.6 | 1 + 1 | 916.0 | 91.0 |
| K01 | 1 | 11 | 90 | 92.0 | 1 + 1 | 358.0 | 63.0 |
| K12 | 2 | 3 | 500 | 493.9 | 2 + 2 | 1187.0 | 672.0 |
| K11 | 2 | 5 | 370 | 373.1 | 2 + 2 | 1166.0 | 431.0 |
| K10 | 2 | 7 | 265 | 260.7 | 2 + 2 | 822.5 | 237.5 |
| K08 | 2 | 9 | 200 | 208.6 | 2 + 1 | 1062.5 | 202.5 |
| K06 | 2 | 10 | 125 | 128.4 | 1 + 1 | 725.0 | 290.0 |
| K07 | 2 | 11 | 135 | 136.1 | 1 + 1 | 303.0 | 128.0 |

The median absolute x discrepancy is 3.1 kg DM/ha; ten are at most 9 kg/ha.
K05 differs by 19.2 kg/ha, but all eleven pairs have overlapping combined
reading ranges. These ranges do not uniquely assign all dates: K01 overlaps
days 11 and 12, and both K06 and K07 overlap days 10 and 11. Day 12 has no
plotted subsequent sample to centre an ordinary running pair. K09 overlaps
yard-2 days 7 and 9, already assigned to K10 and K08. Its x=235 is close to
the otherwise missing yard-1 day-7 stock, 230.7, but its visibly open symbol
denotes yard 2. Do not silently change that identity; K09 remains unresolved.

Fig. 1(c) implies daily observations after day 9, although the methods on
page 436 say every two days and do not explain the change. Under the plotted
schedule, the six low-stock matches use three-day or two-day spans. Page 437
defines daily loss rates between successive observations, then a running
two-point average. At 50 animals/ha, the uncorrected rate is therefore

`I_raw = 10 * ((B_prev - B_shared) / d_left + (B_shared - B_next) / d_right)`

in g DM/animal/day, for B in kg DM/ha and durations in days. Each adjacent
daily rate has weight one half even when the durations differ. A 2+1-day
pair gives `5*B_prev + 5*B_shared - 10*B_next`; averaging total loss over
three days would be a different operator. The candidate x value pairs with
the shared sampling occasion, day 9, rather than the temporal midpoint,
day 8.5. Thus a common four-day operator is not a faithful reconstruction of
all historical intervals, even if retained as a declared synthetic benchmark.

The central raw-minus-plotted differences are all positive, spanning 63–672
g DM/animal/day or 9.9–56.6% of raw loss. K06 is 40% of raw loss, equivalent
to 11.3% of its shared-event standing stock per day. Fable clarified on
3 October (message 840) that his earlier 11% referred to the latter quantity;
there is no disagreement once the denominators are distinguished. Fitting
these differences through the origin against shared-event combined stock
gives a coefficient of 1.10285
g/animal/day per kg/ha, equivalent to a stock-loss rate of 0.05514/day. The
in-sample RMSE is 76.6 g/animal/day; Short's published curve evaluated at these
eleven reconstructed stocks gives 207.4. This is an exploratory correction
fit to a response derived from the same stock series, not independent
validation or identification of a trampling mechanism.

Propagating the component-reading ranges and Fig. 4 y allowances through the
linear calculation leaves only two correction ranges wholly above zero.
Both the proportional prediction and a constant 275-g/day correction lie
inside every pointwise range. Pointwise overlap does not establish joint
compatibility when the points share stock observations, and these visual
allowances are not sampling-error distributions or confidence intervals.
Short's correction was based on pasture loss in muzzled-sheep yards over
four days, assumed transferable to kangaroos; neither its numerical value
nor functional form is reported. A 5.5% law on combined pasture and bluebush
therefore remains a fitted reconstruction rather than the recovered method.

Stock-series variation plausibly contributes to the intake scatter, but this
comparison cannot allocate it among sampling error, growth, other loss, true
intake variation, correction choices and digitization, or exclude scatter
introduced in later processing. No benchmark was rerun. Any prospective
historical comparison needs an explicit timing/mapping contract, including
the ambiguous low-stock matches and unresolved K09. Audit calculations,
tables and inspected source renders are in ignored
`outputs/short-dating-review-20261002/`.
