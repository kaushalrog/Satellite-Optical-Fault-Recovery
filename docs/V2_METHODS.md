# Revision for IEEE Transactions: physical optics, certified coordination, new evaluation

This document describes everything added on branch `ieee-transactions-revision`. The previous state is tag `manuscript-v1`; the legacy optical model (`c.optics='legacy'`) is untouched and still reproduces the earlier 440-run results to 1e-9 (`tests/test_legacy_regression.m`).

## 1. Physical optical model (`src/isc_optics.m`, `src/isc_physical_config.m`, `src/isc_step.m`)

| Stage | Model | Source of parameters |
|---|---|---|
| Link budget | transmit power, optics loss, Gaussian-beam gain 16 ln2 / FWHM², pointing loss exp(-4 ln2 (e/FWHM)²), range spreading, receive aperture and loss | arithmetic validated against NASA TBIRD (below) |
| Receiver | PIN photodiode + transimpedance noise, shot noise, background, OOK bit-error rate from Q-factor | design values |
| Coding | shortened RS(88,72) over GF(2^8), t=8; packet (codeword) error from symbol errors | design values |
| Availability | threshold is the received power where packet error = 0.1 (an output, 0.112 µW) | derived |
| Lock | lock lost after 0.5 s below threshold; re-acquisition needs power ≥ 1.5 × threshold for the acquisition dwell (3 s nominal) | assumed hysteresis; dwell stress 15 s from TBIRD pull-in 10–30 s |
| Terminal | two cascaded 0.03 s lags, rate limit, tracking jitter 10 µrad RMS (35 µrad stress), encoder noise 5 µrad | jitter from TBIRD (<10 µrad body pointing; 20–35 µrad uplink tracking) |
| Beam | FWHM 380 µrad | measured on orbit, TBIRD |

`validation/validate_link_budget.m` reproduces the published TBIRD downlink irradiance budget line by line (−52.97 vs −52.9 dB W/m², all line items within 0.15 dB). **What is real and what is modelled:** the budget, beam width, jitter, pull-in range and FEC-threshold structure are published NASA/MIT-LL values (SPIE 2023, NTRS 20230000434; ICSOS 2023, NTRS 20230014010). The crosslink geometry, the receiver, the RS code, the lock thresholds and the 5 mW transmitter are modelled. Raw flight telemetry is not public, and no ISRO inter-satellite-link data was found; none is used.

## 2. Certified, link-aware coordination (CLAC) (`src/isc_clac.m`)

Each spacecraft i carries an online bound (H_i, W_i) on its attitude and rate error against the **true** desired attitude q_ref ⊗ o_i. A packet from j carries (H_j, W_j) and j's chosen parent. A receiver i bounds its target error from the packet's bounds and the packet age a with the reference-class constants (ω̄, ᾱ):

E_att(a) = e^{ω̄ a} ( H (1 + ω̄ a) + W a + ᾱ a²/2 ),  E_rate(a) = W + ᾱ a + ω̄ (E_att + H)

(Lemma 1). After a horizon h the target is frozen and E_att grows by ω̄ per second. The follower's own bound is E_att + (exact local error to its target) (Theorem 1). Decisions use only these bounds:

1. **Certified horizon:** extrapolate while W + ᾱ a < ω̄, i.e. while extrapolation has a smaller worst-case rate error than holding.
2. **Parent re-selection:** pick the candidate with the smallest certified bound; switch only if the best candidate's bound is below 0.8 × the current one and the last switch is ≥ 2 s old, or if the current parent has no data.
3. **Link scheduling:** event-triggered (same thresholds as the authors' previous rule) on links the child reported as its tree link; 3 s heartbeats on standby links; 1 s reports on the child's own parent link; 1.6 s retry when the sender's own terminal is not locked.

Soundness needs no acyclicity: every bound is built from strictly earlier bounds (delay ≥ one step), and leader-anchored bounds are the only finite ones. Constants are checked numerically in `tests/test_certificate.m` (|ω| ≤ 2.31e-3 vs ω̄ = 2.45e-3; |ω̇| ≤ 2.38e-4 vs ᾱ = 2.6e-4). **Not proven:** closed-loop stability of the saturated, delayed controller; the theorem bounds the error of the *target* relative to the true reference and the carried bound, given the local error. Packet payload is 88 B (64 B state + two bounds + parent id).

## 3. Comparison methods (adapted, not the original authors' code)

Static event trigger with zero-order hold (Tabuada 2007 style), dynamic event trigger with internal variable (Girard 2015 style, used with the same prediction receiver), self-triggered next-transmission time from a model-based deviation bound (Heemels/Mazo style), the authors' previous event + prediction rule on the chain and on a leader-fed star tree, periodic exchange, and ideal communication. Each baseline's one free parameter was set on development seeds to the most accurate value within 1.05 × CLAC's payload (`tuning/tune_v2.m`, `results/v2/tuning_*.csv`).

## 4. Fault coverage

Isolated actuator degradation (no optical fault); pointing bias with different vectors on all three chain links; bias on all six links; random-link pointing and outage (balanced over the six links on held-out seeds); two-link outage; plus healthy, severe attenuation, combined, beam mismatch, network transfer, 35 µrad jitter and 15 s pull-in.

## 5. Reproduce

```matlab
run_tests_v2                                   % optics, certificate, 14 x 9 cases, legacy regression
run_v2_evaluation(201:220,1:14,'heldout')      % needs results/v2/lock.json (python tools/freeze_v2.py --freeze)
```
```bash
python tools/analyze_v2.py && python tools/recompute_v2.py
```
Protocol and lock history: `docs/V2_PROTOCOL.md`.
