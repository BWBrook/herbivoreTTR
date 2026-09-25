# Feeding-access ratios and one-block benchmark

This note defines compact diagnostics for the existing synthetic model and an
analytical no-travel benchmark. It does not add an empirical animal, a new
policy or a simulator result. The target is the model's capacity to maintain
the reference energetic cycle under its declared plant, encounter and movement
rules. The scope of inference is therefore the deterministic model contract,
not herbivore persistence in nature.

## Declared quantities

The homogeneous feeding-access system uses

\[
 r=0.002\ {\rm h}^{-1},\quad s=0.001\ {\rm h}^{-1},\quad
 K=2000\ {\rm kg\ DM\ ha}^{-1},\quad R=200\ {\rm kg\ DM\ ha}^{-1}.
\]

The growth multiplier is \(f=1\) at baseline and \(f=0.6\) during the
declared reduction. A feeding block has area \(A=0.01\) ha (100 m2). The
reference animal has 16 feeding-opportunity hours per day, specifically hours
0--7 and 16--23, and reference intake \(d_0=0.020\) kg DM per feeding hour.
Thus

\[
 D_0=16d_0=0.32\ {\rm kg\ DM\ d}^{-1}.
\]

Food supplies 10,000 kJ per kg DM. Daily reference expenditure is also 3,200
kJ: 24 hours of 100 kJ maintenance plus 16 open hours of 50 kJ routine
activity. The appetite target varies with gut and body state and is capped at
0.025 kg DM/h; \(D_0\) is a reporting reference, not the full model's fixed
request.

## Dimensionless reporting definitions

### Renewal supply

For a fixed growth multiplier, net ungrazed plant production is

\[
 g_f(B)=(rf-s)B-\frac{rf}{K}B^2.
\]

Define the optimistic accessible-renewal ceiling

\[
 \gamma_f=\max_{B\in[R,K]}\max\{g_f(B),0\}
\]

and the demand-to-renewal ratio for support area \(A_s\)

\[
 \Pi_S(f,A_s)=\frac{D_0}{24A_s\gamma_f}.
\]

Values above one mean that even the pointwise maximum positive net production
over all 24 hours is smaller than reference daily demand. This is an upper-bound
diagnostic: it does not assert that \(\gamma_f\) can be maintained along a
grazed trajectory.

| Growth | Maximising biomass above the residual (kg DM/ha) | \(\gamma_f\) (kg DM/ha/h) | 100 m2 renewal ceiling (kg DM/day) | \(\Pi_S\), 100 m2 | 0.08 ha renewal ceiling (kg DM/day) | \(\Pi_S\), 0.08 ha |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Baseline, \(f=1\) | 500 | 0.250 | 0.06000 | 5.333 | 0.48000 | 0.667 |
| Reduced, \(f=0.6\) | 200 (the constrained boundary) | 0.016 | 0.00384 | 83.333 | 0.03072 | 10.417 |

The 0.08 ha entries aggregate all eight blocks. They describe a different
no-travel, pooled-support benchmark, not the physical support available while
resident at one station. Under baseline growth, four permanently used blocks
have a renewal ceiling of 0.24 kg DM/day and therefore cannot maintain the
0.32 kg DM/day reference indefinitely. That result does not prove a day-228
exit: finite opening stock and energy reserve still matter, and the set of
visited blocks can change with encounter rate and policy.

As an integer support bound, baseline reference demand requires at least
`ceiling(5.333) = 6` such blocks. This is necessary, not sufficient for a
sustainable rotation: it assumes the pointwise production maximum throughout,
and omits encounter, travel, residence and rest constraints. Five blocks do
not suffice. During reduced growth, all eight blocks supply at most 9.6% of
reference demand through renewal. A finite successful trajectory can still
draw on opening forage and animal reserves; it does not establish a sustained
rotation. The 60-day initialization is likewise not a grazed-equilibrium test.

### Encounter access

Let \(q\) be search area in m2/h. In a homogeneous footprint, the raw
encounter rate above the residual is

\[
 c_q(B-R)_+,\qquad c_q=\frac{q}{10000},
\]

in kg DM/h. Define

\[
 \Pi_A(B,q)=\frac{c_q(B-R)_+}{d_0}.
\]

This is physical encounter opportunity relative to reference intake. It is not
realized intake: the appetite target subsequently caps intake at at most 0.025
kg DM/h. The reference-adequacy density is

\[
 B_{\rm adequate}(q)=R+\frac{10000d_0}{q}.
\]

| \(q\) (m2/h) | \(B_{\rm adequate}\) (kg DM/ha) | \(\Pi_A\) at baseline biomass 1000 | \(\Pi_A\) at baseline production optimum 500 |
| ---: | ---: | ---: | ---: |
| 0.3 | 866.667 | 1.20 | 0.45 |
| 0.6 | 533.333 | 2.40 | 0.90 |
| 1.5 | 333.333 | 6.00 | 2.25 |
| 3.0 | 266.667 | 12.00 | 4.50 |
| 5.0 | 240.000 | 20.00 | 7.50 |

The uncapped ratios are intentional. For example, at \(q=0.6\), raw encounter
at 1000 kg DM/ha is 0.048 kg DM/h, but realized intake cannot exceed the 0.025
kg DM/h appetite maximum. At 500 kg DM/ha, encounter is 0.018 kg DM/h and is
below reference demand.

### Movement opportunity and direct energy

Movement time and movement expenditure should remain separate. Over \(n\)
complete days, define the total-travel potential ratio

\[
 \Pi_{T,{\rm potential}}=\frac{\sum_t v_t}{16n},
\]

where \(v_t\) is the fraction of hour \(t\) spent travelling. This reports
travel duration against the daily feeding budget; it is only potential loss
because travel can occur outside the split feeding windows. Define observed
feeding-opportunity loss as

\[
 \Pi_{T,{\rm observed}}=
 \frac{16n-\sum_t h^{\rm feed}_t}{16n}.
\]

In the current transition, \(h^{\rm feed}_t=u_t(1-v_t)\), so the observed
quantity counts actual overlap between travel and the open feeding clock.
Matched counterfactuals are still needed if other processes can also change
feeding opportunity.

Define direct movement expenditure separately:

\[
 \Pi_C=\frac{\sum_t C^{\rm move}_t}{3200n}.
\]

The denominator excludes movement. In the implementation, maintenance
continues during travel and the scheduled 50 kJ/h routine expenditure continues
during open feeding hours; movement cost is added to those expenditures.

For a one-way forage move at 40 m/h and 1 kJ/m, the current layouts imply the
following possible pairwise burdens. These are route potentials, not observed
move frequencies or cumulative treatment costs.

| Layout | Non-zero distance range (m) | travel h / 16 range | incremental kJ / 3200 range |
| --- | ---: | ---: | ---: |
| Continuous | 10--31.623 | 0.0156--0.0494 | 0.0031--0.0099 |
| Clustered | 10--70.711 | 0.0156--0.1105 | 0.0031--0.0221 |
| Fragmented | 25--106.302 | 0.0391--0.1661 | 0.0078--0.0332 |

### Reserve relative to plant response

For body reserve \(E\), define gross reference-demand coverage

\[
 T_{\rm buffer}=\frac{E}{3200}\quad {\rm days}.
\]

For the 40,000 kJ opening reserve, this is 12.5 days. The positive ungrazed
plant equilibrium is

\[
 B_f^*=K\left(1-\frac{s}{rf}\right),
\]

and its local relaxation time in days is

\[
 \tau_f=\frac{1}{24(rf-s)}.
\]

The baseline values are \(B_1^*=1000\) kg DM/ha and \(\tau_1=41.67\) days;
under \(f=0.6\), they are 333.33 kg DM/ha and 208.33 days. The descriptive
ratios \(T_{\rm buffer}/\tau_f\) are therefore 0.30 and 0.06 at the opening
reserve.

These are not failure thresholds. The denominator of the actual time to a
reserve boundary is the changing net daily deficit, not gross reference
demand. Intake changes with biomass, search, appetite feedback, policy and
travel; gut energy delays transfer to body reserve; movement adds expenditure;
and the deficit may shrink, grow or change sign. If a deficit timescale is
reported, it must use a declared interval and the observed or counterfactual
cumulative deficit over that interval. No universal rule such as
\(T_{\rm buffer}/\tau_f<1\) establishes chronic decline.

For scale, exact ungrazed recovery after switching from reduced to baseline
growth is available analytically. With baseline equilibrium \(B_1^*=1000\),
recovery from 333.33 to the \(q=0.6\) reference-adequacy density 533.33 takes

\[
 \frac{1}{24(r-s)}\log\left[
 \frac{533.33(1000-333.33)}{333.33(1000-533.33)}
 \right]=34.44\ {\rm days}.
\]

This is an ungrazed threshold-crossing time, not \(\tau_1\), and it does not
apply while the block is being eaten.

## Exact one-block hourly map

This is a stationary, no-forage-travel benchmark with adequate free water;
water constraints and water excursions are omitted. It retains the full
gut/body appetite feedback on the actual feeding clock, but it is not the full
spatial animal. The plant transition is applied before grazing. Write

\[
 a_f=rf-s,\qquad b_f=\frac{rf}{K},
\]

and, for a one-hour autonomous plant step,

\[
 \Phi_f(B)=
 \frac{B\exp(a_f)}
 {1+b_fB\{\exp(a_f)-1\}/a_f},
\]

with the continuous limit \(\Phi_f(B)=B/(1+b_fB)\) when \(a_f=0\).
Let \(u_t=1\) at hours 0--7 and 16--23 and zero otherwise. Let body and gut
energy at the start of hour \(t\) be \(E_t\) and \(G_t\), and let the
time-matched period-24 reference states be \(E_t^0,G_t^0\). The full appetite
request is

\[
 d_t=u_t\,\operatorname{clip}_{[0,0.025]}\left(
 0.020-\frac{0.05(E_t-E_t^0)+0.10(G_t-G_t^0)}{10000}
 \right).
\]

For one stationary block,

\[
 \begin{aligned}
 \widetilde B_t &= \Phi_f(B_t),\\
 I_t &= \min\{d_t,c_q(\widetilde B_t-R)_+\},\\
 B_{t+1} &= \widetilde B_t-I_t/A,\\
 G_{t+1} &= 0.75G_t+10000I_t,\\
 E_{t+1} &= E_t+0.25G_t-100-50u_t.
 \end{aligned}
\]

The proposed step is rejected if \(E_{t+1}<0\). Current intake enters the gut
after release, so it cannot support the body until a later hour.

In the encounter-limited branch, suppose that
\(c_q(\widetilde B_t-R)\le d_t\), \(\widetilde B_t\ge R\), and
\(q\Delta t\le10000A\), where \(\Delta t=1\) h and \(10000A\) is footprint
area in m2. The last condition keeps the package's searched fraction below its
cap of one per hour. The vegetation part then reduces exactly to

\[
 B_{t+1}=
 \begin{cases}
 (1-\eta_q)\Phi_f(B_t)+\eta_qR,&u_t=1,\\
 \Phi_f(B_t),&u_t=0,
 \end{cases}
 \qquad \eta_q=\frac{q\Delta t}{10000A}.
\]

At \(A=0.01\) ha and \(q=0.6\), \(\eta_q=0.006\). The exact daily plant map
is

\[
 \mathcal M_{\rm day}=H_{f,q}^{8}\circ C_f^{8}\circ H_{f,q}^{8},
 \quad
 H_{f,q}(B)=(1-\eta_q)\Phi_f(B)+\eta_qR,
 \quad C_f(B)=\Phi_f(B),
\]

where the rightmost map acts first. It is eight open-hour maps, eight
closed-hour maps, then eight open-hour maps, and must not be replaced by 16
consecutive feeding hours when plant growth is nonlinear.

If \(\widetilde B_t<R\), accessible encounter is zero and the feeding-hour map
is simply \(\Phi_f(B_t)\); if \(q\Delta t>10000A\), the package caps the
searched fraction at one and the affine \(H_{f,q}\) expression above no longer
applies.
The declared homogeneous initial state and growth multipliers \(f\ge0.6\),
together with residual-protected grazing, keep the present benchmark in the
\(\widetilde B_t\ge R\) region. All five sensitivity coefficients are also far
below the searched-fraction cap for a 100 m2 block.

An optional fixed-reference-demand simplification replaces the feedback request
by \(d_t=u_td_0\). Its feeding-hour removal is

\[
 I_t=u_t\min\{d_0,c_q(\widetilde B_t-R)_+\}.
\]

Above \(B_{\rm adequate}\), it removes exactly \(d_0/A=2\) kg DM/ha in each
open hour; below that threshold it follows the encounter-limited map. This is a
piecewise scalar benchmark. It is not the reserve-feedback animal, whose
request and adequacy threshold vary hourly with \(E_t\) and \(G_t\).

## What the benchmark proves

For opening accessible mass \(X_0=A(B_0-R)_+\), cumulative intake over any
horizon is bounded by

\[
 X_0+A\sum_t\gamma_{f_t}.
\]

Consequently, combined gut plus body energy is bounded above by opening
combined energy, plus 10,000 times that harvest bound, minus maintenance,
routine activity and any movement expenditure. A negative combined-energy
upper bound certifies that no appetite or allocation path satisfying the
contract can reach that horizon without a non-negative-energy domain exit. A
positive bound is inconclusive.

For permanent residence on one 100 m2 block, the stronger long-run comparison
is already decisive: baseline renewal is at most 0.06 kg DM/day while reference
energetic expenditure requires 0.32 kg DM/day. Finite opening forage and energy
stocks cannot close that persistent gap indefinitely. This is an area-support
limitation and should not be labelled a feedback trap.

The result does not provide an exit day for the full appetite model, establish
failure over a finite 228-day horizon, or prove that an animal remains confined
to one or four blocks. Nor does it transfer to the 0.08 ha pooled benchmark,
whose baseline renewal ceiling exceeds reference demand. During the temporary
reduced-growth treatment, even the pooled renewal ceiling is far below demand,
but opening forage, reserve, treatment duration and post-treatment recovery
prevent that rate comparison alone from deciding completion.

The Goal 062 statement that encounter, information, allocation and travel
jointly govern the observed physical-versus-pooled contrast remains defensible
as a statement about the composed simulations. It is not an identified causal
decomposition. In particular, using the trivial one-block renewal deficit to
support that statement, treating the pooled-stock control as the same physical
support, or inferring that every search coefficient and policy must fail would
be proof errors.

The equations and constants above follow
[responsive-forage.R](../R/responsive-forage.R),
[feeding-footprint.R](../R/feeding-footprint.R),
[herbivore-core-fixtures.R](../experiments/herbivore-core-fixtures.R), and
[feeding-access-fixtures.R](../experiments/feeding-access-fixtures.R).
