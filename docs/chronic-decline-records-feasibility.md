# Matched kangaroo records: feasibility assessment

Assessed 1 October 2026 after Barry approved the search in correspondence
56, message 801, following Fable's proposal in message 799.

## Finding

The Kinchega–Tandou programme did collect overlapping pasture, rainfall,
kangaroo abundance, condition and reproductive observations through the
1982–83 drought. Fowlers Gap supplies complementary matched studies in
1988–92 and 1994–97. Published tables and figures offer a partial recovery
route, and a downstream copy of the Kinchega paired counts was downloaded.
The search has not located the original individual-animal and site-level
pasture datasets. Their survival and present custodianship remain unconfirmed.

The clearest overlap is August 1980–February 1984 for pasture and aerial
surveys, with female condition/recruitment samples from June 1982. These
records could test seasonal condition decline and recovery at an aggregate
level. They do not yet supply a calibrated mapping from model energy reserve
to body condition, nor an individual condition-to-survival relationship.

This assessment supports recovering the matched observations before choosing
a chronic-decline comparison. It does not select a new plant model, change
the synthetic physiology or authorize fitting a dynamic species model.

## Kinchega and Tandou

| Record | Period and sampling | Variables and matching | Obtainable form and remaining gap |
| --- | --- | --- | --- |
| Bayliss, *Kangaroo dynamics*, chapter 8 and Appendix 8.2 in *Kangaroos* | Kinchega and surrounding properties, approximately quarterly, 1973–84; paired consecutive-day Kinchega aerial counts | Red and western-grey abundance; pasture measurements coincide with surveys during 1980–early 1984 | [Publisher summary](https://www.cambridge.org/core/books/abs/kangaroos/kangaroo-dynamics/8557D55B46A7C0562ABEE144B93FBB80) and [author-uploaded chapter/appendices](https://www.researchgate.net/publication/314230723_Kangaroo_dynamics) are readable. The appendix prints dated counts and corrections; OCR requires checking against page images. A downstream numerical copy was recovered, as detailed below. |
| Robertson, *Plant dynamics*, chapter 4 | Quarterly, August 1980–February 1984; 213 Kinchega and 100 Tandou sites | Pasture biomass, composition and phenology; pasture and shrubs distinguished | [Publisher methods summary](https://www.cambridge.org/core/books/abs/kangaroos/plant-dynamics/91112B5BFD22A4029592CCA2A791DDDA) confirms the design. Published summaries are a recovery route; original site-by-date measurements were not located. The related [1988 paper](https://doi.org/10.1111/j.1442-9993.1988.tb01000.x) is a lead for the longer plant record. |
| Shepherd, *Condition and recruitment of kangaroos*, chapter 9 | June 1982–December 1984; quarterly samples of 20 female reds and 20 female western greys at Kinchega, and 20 female reds at Tandou; additional Kinchega red samples between quarters | Condition, nutritional status and reproduction/recruitment related to weather and vegetation | [Publisher summary](https://www.cambridge.org/core/books/abs/kangaroos/condition-and-recruitment-of-kangaroos/2745A22E4588812C8547641C632E0EB4) verifies the sampling and says the wider investigation continued to February 1986. Published summaries do not establish access to individual records or a complete 1982–86 series. |
| Robertson (1986), *The Mortality of Kangaroos in Drought* | Kinchega, 1982–83 drought | Count decline and carcass evidence, including age/sex composition | [Publisher record](https://doi.org/10.1071/WR9860349) and published paper provide a drought mortality contrast. This is not a marked-individual survival panel. The survey dates used in each calculation need checking against the count appendix before reconstruction. |

Knape, Jonzén and Sköld's [2011 reanalysis](https://doi.org/10.1111/j.1365-2656.2011.01868.x)
used 41 occasions of replicated Kinchega red-kangaroo counts, confirming that
this historical series was recoverable for later analysis. The within-occasion
replicates inform observation error; they are not independent ecological
replicates. Aerial abundance also combines births, deaths and movement. It
must not be relabelled physiological survival.

The downloaded [commit-pinned downstream copy](https://github.com/pierrejacob/bayeshscore/blob/f73a998f006c9080bd0d6fe17ff78d3f7d97c657/data/kangaroo.RData)
contains one numeric `3 x 41` matrix, `data_kangaroo`, with rows `y1`, `y2`
and `time`. It provides 82 counts in 41 pairs and fractional-year times from
1973.497 to 1984.413. Its first five count pairs match the inspected printed
appendix entries, but all counts, corrections and dates still need checking
against the primary source before analytical use. This is an acquired copy,
not a validated dataset or author/publisher deposit. Its local location is
`outputs/chronic-records-feasibility-20261001/kinchega/bayeshscore-kangaroo-f73a998.RData`;
SHA-256 is `0188330088a3ff5bf0156fc37a63ed64ef1334c38ddc634187680be71a4e69e7`.
It remains untracked and has not been used to fit a model.

Wiley lists a Word supplement to Knape et al. containing figures, methods,
Table S1 and Matlab code, but no separate data file. Retrieval returned HTTP
403; whether the code embeds observations remains unresolved. The apparent
June/September 1982 discrepancy between Robertson and Bayliss concerns
different mortality and visibility-correction calculations; it should not be
treated as an established contradiction.

The [1982–83 NPWS annual report](https://nswdpe.intersearch.com.au/nswdpejspui/bitstream/1/7942/1/National%20Parks%20and%20Wildlife%20Service%201982-83%20Annual%20Report_01.pdf)
documents the integrated NPWS–CSIRO research programme. This identifies
institutional inquiry routes, not a confirmed archive holding. The most useful
request would name Shepherd's animal-by-date condition/reproduction records,
Robertson's site-by-date vegetation records, and the accompanying weather,
survey and management metadata. NSW NPWS/DCCEEW and CSIRO are plausible
starting points. Bayliss's 1980 University of Sydney MSc thesis is a further
library lead, but an exact accessible catalogue record was not found.

## Fowlers Gap

| Record | Matched design | Access and value |
| --- | --- | --- |
| [Moss and Croft (1999)](https://doi.org/10.1046/j.1442-9993.1999.241949.x), December 1988–February 1992 | Mating and Lambing paddocks; on-site rainfall, 13 seasonal pasture surveys with clipped-biomass calibration, and seasonal body-mass, structural and reproductive measurements from 231 distinct red kangaroos | Published methods, figures and tables are readable through an online paper transcription; no raw archive was found. The wet-to-dry transition and reported lag between pasture and condition make this the strongest direct condition complement to Kinchega. Recover individual records before assuming repeated measurements can be reconstructed from published summaries. |
| Witte and Croft (2025 publications), April 1994–March 1997 | Four paddocks; monthly rain and repeated kangaroo counts, quarterly pasture observations, carcass and reproductive evidence, and radio-tracked red females | Open [grazing-pressure paper](https://www.mdpi.com/3042-4526/2/1/5) and [mobility/demography paper](https://www.mdpi.com/1424-2818/17/6/389). Their data statements offer original summaries on request, not a downloadable raw archive. This adds a drought/recovery window, with movement and reproductive status explicitly relevant to interpretation. |

The Witte methods and availability statements were checked in the publisher's
[Wild XML](https://mdpi-res.com/d_attachment/wild/wild-02-00005/article_deploy/wild-02-00005.xml)
and [Diversity XML](https://mdpi-res.com/d_attachment/diversity/diversity-17-00389/article_deploy/diversity-17-00389.xml),
downloaded to the ignored assessment directory. Article-page retrieval was
unreliable, but both publisher XML files were obtained successfully.

The Moss paper's detailed methods were inspected in a [full-text transcription](https://doczz.net/doc/8225431/body-condition-of-the-red-kangaroo--macropus);
the primary publisher PDF should be recovered before extracting numerical
inputs. Neither paddock is a closed population, and livestock treatments
must be retained. UNSW's [Fowlers Gap contact](https://www.unsw.edu.au/research/fowlers-gap/contact)
provides an institutional inquiry route. A single bounded request could cover
the Moss–Croft and Witte–Croft animal, pasture and rainfall sheets, along with
record identifiers, methods and reuse conditions. No request was sent.

Public ancillary data do exist: the [Fowlers hydrology deposit](https://doi.org/10.6084/m9.figshare.24882120)
advertises daily rain since 1970 and dense gauge observations for 2013–2023.
Its API lists a roughly 500-MB downloadable ZIP under CC BY 4.0; the payload
was not downloaded. The daily component may overlap the historical animal
studies, whereas the dense modern component does not. Exact gauge coverage
and gaps remain unverified, and neither component supplies animal condition.

## Rainfall and broader population context

Rainfall access appears less restrictive than access to historical condition
and pasture observations. BoM's [Menindee Post Office station metadata](https://www.bom.gov.au/clim_data/cdio/metadata/pdf/siteinfo/IDCJMD0040.047019.SiteInfo.pdf)
identifies station 047019 and rainfall holdings from January 1876, with 97%
completeness over the full recorded span. That percentage does not establish
completeness during the study years. [Climate Data Online](https://www.bom.gov.au/climate/data/)
provides an observation-retrieval route; no historical rainfall payload was
downloaded in this assessment. Match the original study's gauge and dates
before substituting Menindee town observations for on-site rain.

[SILO point data](https://www.longpaddock.qld.gov.au/silo/point-data/) offer
daily series from 1889. Its [documentation](https://www.longpaddock.qld.gov.au/silo/faq/)
distinguishes observed station values from interpolated replacements; grid
series are entirely interpolated. Any recovery must retain source flags and
missing/accumulated-rain conventions. SILO is an alternative forcing source,
not an independent observation of pasture or an assurance of gauge coverage.

NSW's [public monitoring tables](https://www.environment.nsw.gov.au/topics/animals-and-plants/wildlife-management/kangaroo-management/kangaroo-population-monitoring-and-reporting)
contain annual western-plains red/grey estimates for 2010–2024, including
Broken Hill and Lower Darling. The programme extends back to the 1970s, but
these accessible tables are regional context rather than a matched Kinchega
condition record. Survey changes, zone boundaries, harvest and movement
would need explicit treatment in any longer population comparison.

## Next recoverable tranche: review on 2 October 2026

Following Fable's message 815, prioritise the condition observations from
Shepherd's Kinchega–Tandou work and Moss–Croft's Fowlers Gap study, together
with their matched pasture observations. The recovered count matrix is
supporting context; further count verification can wait until a comparison
needs it. Preserve site, species, sex, reproductive state, date and sampling
unit. Distinguish original observations, transcribed tables and digitized
figure summaries. Do not create individual records from plotted means.

The immediate route combines recovery of published condition/pasture methods
and summaries with targeted inquiries about the originals. The
[email drafts and checked contacts](kangaroo-data-request-drafts.md) are ready
for Barry. He explicitly reserves sending emails to people to himself; no
inquiry has been sent by an agent. The papers' offers of data on request do
not establish that UNSW, NPWS or CSIRO holds every original record.

A first animal comparison driven by observed pasture is a useful proposed
design. It can defer plant-structure choices and avoid treating an uncertain
plant model as measured exposure. Interpolation, edible fractions, forage
quality, water access and the condition-observation mapping still need a
declared contract. Observed pasture already reflects field herbivory; removing
simulated intake from that prescribed trajectory would count depletion again.
Quarterly surveys cannot be treated as daily measured forcing, and rainfall
alone does not establish drinking-water availability or food moisture.

Decline and recovery lags are relevant outcomes. A longer recovery lag would
be consistent with persistent depletion, but would not uniquely diagnose
chronic decline: reproductive costs, changing sample composition, movement,
forage quality and coarse observation times can also produce apparent
asymmetry. Nor is asymmetric lag necessary for sustained reserve loss.
Moss–Croft's reported pasture–condition lag does not by itself establish a
separate decline-versus-recovery contrast. Retain both directions as candidate
comparisons rather than declaring their outcome from the published lag.

Only after that inventory can a comparison contract choose outcomes and
separate calibration from held-out evaluation. Multiple seasons integrate
intake, expenditure, reproductive costs and movement; they need not identify
search exposure, residual biomass or memory separately. The useful first
decision is whether the observations resolve the timing and persistence of
condition decline and recovery, with a defensible observation model.

No model, benchmark input, frozen trajectory or package process changed in
this search. No external records inquiry was sent. Source papers and any
downloaded material remain outside tracked model source; this note records
access evidence and unresolved gaps rather than claiming a complete, validated
matched dataset.
