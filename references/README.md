# References

Source interpretation and page-level evidence belong in
[`docs/empirical-anchor-evidence.md`](../docs/empirical-anchor-evidence.md).
The [observation contracts](../docs/empirical-anchor-contracts.md) are separate
from empirical findings and the implemented synthetic model. The approved
red-kangaroo benchmark is recorded in
[Decision 0065](../docs/decisions/0065-red-kangaroo-budget-and-acquisition.md).

`short-1985-figure4.csv` retains 12 approximate intake-response point readings;
`short-1985-figure1c.csv` separately retains 32 pasture/bluebush stock readings.
Their pixel coordinates, reading allowances and limitations are documented
in [the reconstruction note](short-1985-digitization.md). These compact source
inputs may be used to reproduce the benchmark without redistributing the PDF.

Barry supplied three published PDFs on 26 September 2026; Fable placed them in
the local `papers/` folder (correspondence discussion 56, message 563). The
root `.gitignore` excludes that folder. Retain the PDFs locally; do not commit
or redistribute them with the source repository. They are inputs, not model
outputs. The following SHA-256 values were checked against the supplied files:

| Local filename under `papers/` | SHA-256 |
| --- | --- |
| `short-1985-functional-response-kangaroos-sheep-rabbits.pdf` | `f4461cf991cffea467bcfda4797b110daa39661d42346c1b07b3323ad0e676ce` |
| `munn-2009-fmr-water-turnover-red-kangaroo-sheep.pdf` | `05a6bd24bb7467fe10b5559047309fecdd85c078f42fb1603bd70e7d5017b9d7` |
| `munn-2016-fmr-movement-western-grey-kangaroo-sheep.pdf` | `ded1e55fec116d91e7963ceef0cdbe228486e0beb1ddc20e69083ce12a2a4232` |

Text extraction and selected page renders are disposable reading aids under
ignored `outputs/recovery-clock-064/fulltext-review-20260926/`. Printed journal
page numbers in the evidence note refer to the PDFs, not those extracts.
