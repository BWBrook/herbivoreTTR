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
vegetation was assessed every two days. The paper does not specify which
biomass timestamp accompanies each smoothed intake point or whether biomass
was also averaged. Yard identities are known, but interval dates and raw
intake observations cannot be assigned from Fig. 4. The values must not be
smoothed again or treated as twelve independent experimental replicates.

`short-1985-figure1c.csv` separately reconstructs 32 visible pasture and
bluebush symbols in Fig. 1(c), printed page 438 (PDF page 5), at days
1, 3, 5, 7, 9, 10, 11 and 12. Triangles are yard 1, circles yard 2;
filled symbols are pasture and open symbols bluebush. Days without visible
symbols are omitted. This is not an independent intake dataset and does not
identify the intervals of the Fig. 4 symbols.

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
