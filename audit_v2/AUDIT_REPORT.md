# Pre-submission audit of the CLAC manuscript (certificate, implementation, experiments)

Audited state: branch `ieee-transactions-revision`, commit `9d2bba9`+ (frozen code, lock `results/v2/lock.json`), manuscript source `paper_v2/main.tex`. The file `main(7).pdf` named in the request was not available to me; I audited the repository's `paper_v2/main.tex`/`main.pdf` and assumed they match.
Nothing in `src/`, `results/v2/` (original), or `paper_v2/` was changed. Work is on branch `audit/clac-certificate`, folder `audit_v2/`. Re-runs write only to `audit_v2/results/`.

## Verdict

The central certificate (Lemma 1, Theorem 1, E, F) is **mathematically valid as typeset** and **consistent with the implementation**; no correction is required, so the 2,520-run re-evaluation was not triggered. One reading of E(a) that drops the outer parentheses (as in the request text) would be invalid. Two reporting errors and one coverage gap were found. **The paper is not declared submission-ready**: the proposals below (wording, coverage) are unapplied, and the limits in the paper (no closed-loop stability, simulation only, adapted baselines, novelty judged by reviewers) remain.

## Priority 1 — Lemma 1, equations for E(a)

Derivation. With θ(0)≤H and θ′ ≤ W + ᾱs + ω̄(θ+H), Grönwall gives the exact solution
θ(a) ≤ e^{ω̄a}H + (W+ω̄H)(e^{ω̄a}−1)/ω̄ + ᾱ(e^{ω̄a}−1−ω̄a)/ω̄².
Using (e^x−1)/ω̄ ≤ a e^{x} and (e^x−1−x)/ω̄² ≤ (a²/2)e^{x}, this is ≤ e^{ω̄a}[H(1+ω̄a) + Wa + ᾱa²/2], which is the implemented and typeset E(a).

| Item | Status | Evidence |
|---|---|---|
| E(a) = e^{ω̄a}[H(1+ω̄a)+Wa+ᾱa²/2] (outer brackets as in `main.tex` l.163 and `isc_clac.m`) | **PASS** | `math_check.m` A: E_impl − exact ≥ 0 on the whole grid; looser than exact by at most 10.2 % at a=60 s (ω̄=2.45e-3); negligible for a ≤ 3 s |
| Reading without outer brackets: e^{ω̄a}H(1+ω̄a) + Wa + ᾱa²/2 | **FAIL (invalid)** | min(E_unparenthesised − exact) = −0.070 rad at a ≤ 60 s, −4.9 rad at a=300 s; the exponential factor on the W and ᾱ terms is missing. If the PDF renders it this way it must be fixed; the TeX source does not |
| Monte-Carlo vs true motion (real reference; class-extremal random references with ω̄,ᾱ saturated; 7,200 trials incl. ages to 60 s, frozen targets) | **PASS** | 0 violations; max θ/E = 1.000 (reached at a=0, where θ=H) |
| Smallest safe correction | none needed | exact-integral form is the tightest bound this proof gives (proposal P1, optional) |

## Priority 2 — Theorem 1 and F(a)

| Item | Status | Notes |
|---|---|---|
| F(a) = W + ᾱa + ω̄(E+H); F = ω̄ after the horizon | **PASS** | follows from ‖R(𝓔)a₁−a₂(s)‖ ≤ W+ᾱs+ω̄(θ+H) with θ ≤ E; MC max rate/F = 1.000, no violation |
| Frozen-target branch (a>h): E(h)+ω̄(a−h) | **PASS** | desired attitude moves ≤ ω̄ per second |
| Body-rate of 𝓔 = a₁ − R(𝓔)ᵀa₂, |θ′| ≤ ‖R(𝓔)a₁−a₂‖ | **PASS** | rederived: Ė = −[a₂]ₓ𝓔 + 𝓔[a₁]ₓ; angle is 1-Lipschitz in the bi-invariant metric |
| Quaternion/frame conventions (Hamilton, Log = full rotation vector, body rates, ρ = o_jᵀ⊗o_i, ω*_i = R(o_i)ᵀω_r) | **PASS** | `isc_math` Log returns 2·atan2 rotation vector; transport identities checked |
| Triangle inequalities (attitude, rate transport, pair error ϑ ≤ H_i+H_j) | **PASS** | geodesic distance on SO(3) is bi-invariant |
| Induction under arbitrary delay, loss, outage, parent switching | **PASS** | each stored bound derives from strictly earlier bounds (delay ≥ one step); H=∞ base case; cache stores (state, H, W) from one packet |
| Remark: no acyclicity needed | **PASS** | finite bounds always trace to the leader |
| Assumption 1 constants ω̄=2.45e-3, ᾱ=2.6e-4 | **NOTE** | verified numerically (measured 2.31e-3, 2.38e-4), not proved analytically; stated as numerical in the paper |
| Closed-loop stability | not claimed | correctly excluded |

## Priority 3 — Implementation map and consistency

| Quantity | Location | Status |
|---|---|---|
| E(a), F(a) | `src/isc_clac.m` case `'bound'` (l.19–28) | **PASS** identical to typeset |
| Horizon h = clamp((ω̄−W)/ᾱ, 0, 3) | `isc_clac.m` case `'horizon'` (l.31–36) | **PASS** |
| Constants ω̄, ᾱ | `isc_clac('reference')` (l.81), stored in `c.clacRef` (`isc_config.m` l.51) | **PASS** |
| Parent selection (min bound, ratio 0.8, dwell 2 s) | `isc_clac.m` case `'update'` (l.38–56; `canSwitch` l.54) | **PASS** with two notes below |
| Per-node (H,W) | `isc_clac.m` `'update'`; leader exact | **PASS** |
| Extrapolation used by the controller | `isc_tracking_target.m` via `n.parent=s.parent`, `n.predictionHorizon=s.horizon` (`isc_step.m`) | **PASS** same parent/horizon as in the bound |
| Packet fields and cache | `isc_tracking_schedule.m` l.55; `isc_step.m` l.106 | **PASS** |
| Stored soundness metric | `isc_tracking_metrics.m` | **FAIL (coverage)**: checks attitude only; the rate certificate W was never checked in the original 560 runs. Now covered by `audit_trajectories.m` |
| NOTE 1 | `isc_clac.m` l.41 | A parent that reports us as its parent is excluded, so its bound is ∞ and the switch is immediate; the paper says "no data". Cosmetic wording difference |
| NOTE 2 | `isc_clac.m` l.43 | Candidate bounds use each candidate's own horizon; the paper does not state this |
| NOTE 3 | `isc_clac.m` `'bound'` | W=∞ with a=0 gives NaN (∞·0); treated as unavailable, never reached because ages ≥ one step |

## Priority 4 — Experimental impact

No certificate correction is needed, so selection, horizon and results are unchanged. To test sensitivity I replayed all 560 CLAC and CLAC-fixed trajectories two ways (same 20 frozen seeds):

| Replay | Result |
|---|---|
| Frozen code | **PASS.** Reproduces the stored held-out CSV exactly (pair RMS and attempts: 0 difference). Attitude violations 0, rate violations 0 over 2,510,051 follower samples; minimum margins H−χ = 2.0e-6 rad, W−ε = 1.0e-5 rad/s |
| Proposal P1 (exact-integral E) in a separate folder | Attitude and rate violations 0. Parent-switch counts identical in all 560 runs; pair RMS identical in 257 of 560 runs, maximum relative change 1.19 %, mean 3e-5; attempts differ by ≤ 1 packet. So the looser bound does not change parent selection or the horizon in any practical way |

Tables and figures were not regenerated because no result changed. The other seven methods do not use the certificate.

## Priority 5 — Reporting audit (`claims_audit.py`, 67 checks from raw trial CSVs, independent bootstrap)

60 PASS, 1 FAIL, 6 NOTE.

| Claim | Status |
|---|---|
| 2,520 runs = 14 × 9 × 20; 675 summary cells; all means and CIs in Tables III–V and text (58.4 %, 14.5 %, 8.9 %, 81 %, 44.9 %, 71.4 %, 21.2/18.6/16.9 %, jitter, slow acquisition, actuator-only, payloads, 893 attempts, 4.3 switches, 0.95 tightness) | **PASS** (CI ends within bootstrap noise, ≤ 0.35 percentage points) |
| Abstract and Conclusion "never violated in 560 CLAC runs" | **FAIL**: the 560 trajectories are 280 CLAC + 280 CLAC-fixed. Section VII-C states it correctly; the abstract does not |
| Parent switches (4.3, max 10), tightness 0.95 | **PASS**, but computed over the 280 CLAC runs only (paper says so for tightness, not for switches) |
| "star and chain methods stay at about 1.05° under severe attenuation" | **NOTE**: range is 1.00–1.07° |
| "Baselines tuned to the same payload" | **NOTE**: baselines were capped at 1.05 × CLAC on development seeds; held-out payloads are 5–12 % below CLAC (EO star 68.8, ETC 74.3, DET 71.7, ST 72.2 vs 78.6 kB) and EO chain 82.6 kB. Development sweeps show baseline accuracy changes < 3 % when payload rises to 84–237 kB (`results/v2/tuning_*.csv`), so the conclusion is not sensitive to this |
| Explanation that chains lose because lag accumulates over hops | **PASS** (now tested): ideal communication on the star gives 0.103°, on the chain 0.333° (healthy, seeds 201–220) |
| Tuning and evaluation use the same 14 condition types (different seeds) | **NOTE**: a limitation worth one sentence |

## Proposals (individually reviewable; none applied)

- **P1** `proposals/P1/` — optional exact-integral E(a). Not needed; adopting it after the lock changes 303 of 560 CLAC outputs by up to 1.2 % and would require a new lock. Recommendation: keep the current bound, mention the exact form in a remark.
- **P2** wording: abstract/conclusion "560 CLAC runs" → "560 CLAC and CLAC-fixed trajectories (280 each), for both the attitude and the rate certificate"; parent-switch statistic "over CLAC runs"; severe attenuation "about 1.0–1.07°".
- **P3** coverage: add the rate-certificate check to `isc_tracking_metrics.m` (or cite `audit_v2/audit_trajectories.m` in the paper's soundness subsection).
- **P4** state in Section V that ω̄ and ᾱ were verified numerically, and give the analytic bound on ‖v̇_r‖ (2.32e-3) as sanity context.
- **P5** payload wording: "capped at 1.05 × CLAC's payload on development seeds"; add the held-out payloads; add one sentence on tuning/evaluation sharing condition types.

## Reproduce

```
matlab -batch "run('audit_v2/math_check.m')"
matlab -batch "addpath('audit_v2');audit_trajectories(1:14,'','frozen')"
python3 audit_v2/claims_audit.py
```
