# Revision checklist: IEEE Transactions submission

Branch `ieee-transactions-revision`. The previous manuscript state is tagged `manuscript-v1` (commit de15c77) and stays reproducible. A box is ticked only after the item was implemented **and** the stated test or run was executed.

## Reviewer comments to address

- Originality and novelty
- Comparison with existing methods
- Evaluation with official data (NASA, ISRO or similar)
- Optical model: Gaussian beam with instantaneous power threshold; no acquisition/lock, coding, BER or link-budget validation
- Actuator degradation evaluated only inside combined-fault cases
- Pointing bias concentrated on one optical link

## 0. Setup

- [x] 0.1 Old state tagged `manuscript-v1`; revision branch created
- [x] 0.2 Legacy optics kept as `optics='legacy'`; old 440-run results still reproduce (regression test) (7 legacy runs match to 1e-9; `run_tests_all` passes the original suite too)

## 1. Realistic optical model (reviewer: Gaussian beam + instantaneous threshold)

- [x] 1.1 Physical link budget from first principles (transmit power, optics losses, Gaussian-beam gain, range, receive aperture)
- [x] 1.2 Receiver noise (thermal, shot, background) and bit-error rate from received power
- [x] 1.3 Forward error correction: codeword and packet error probability from BER (replaces the constant 2 % random loss)
- [x] 1.4 Acquisition, tracking and lock-loss state machine with hysteresis and acquisition dwell (`tests/test_lock_dynamics.m`: loss after 0.45 s, re-lock 2.95 s after fault end)
- [x] 1.5 Terminal dynamics: two-stage lag with rate limit, tracking jitter, encoder noise
- [x] 1.6 Derived availability threshold (an output of the receiver model, not an input)
- [x] 1.7 Unit tests for budget, BER monotonicity, FEC, lock hysteresis

## 2. Validation against official data (reviewer: use NASA/ISRO data)

- [x] 2.1 NASA TBIRD published downlink budget (−52.9 dB W/m²) reproduced by the link-budget code within 0.25 dB (−52.97 vs −52.9, 0.07 dB)
- [x] 2.2 Beam width, tracking jitter, pointing loss and acquisition time calibrated to published TBIRD measurements, each with its source table or section
- [x] 2.3 Written statement of what is real published data and what is modelled; raw flight telemetry not public; no ISRO inter-satellite-link data found (Section IV-C of the paper, `docs/V2_METHODS.md`)
- [x] 2.4 Evaluation stress cases taken from published TBIRD values (35 µrad tracking RMS, 10–30 s pull-in)

## 3. Fault coverage (reviewer: isolated actuator, multi-link pointing)

- [x] 3.1 Isolated actuator-degradation held-out case (no optical fault)
- [x] 3.2 Pointing bias on all three active links with different bias vectors
- [x] 3.3 Worst case: pointing bias on all six physical links
- [x] 3.4 Healthy (no-fault) case to measure false actions

## 4. Novel method with proven properties (reviewer: originality)

- [x] 4.1 Literature check of closest work, with a claim limited to what the search supports (limited web search of event-triggered attitude, dynamic/self-triggered work and optical links; the paper limits the claim to "within the literature we reviewed"; a reviewer-grade survey is still advisable)
- [x] 4.2 Method specified: certified, link-aware coordination (CLAC)
- [x] 4.3 Lemma: prediction-error certificate on SO(3), full proof
- [x] 4.4 Theorem: online-computable bound on every follower's tracking error under arbitrary delay, loss and outage, full proof
- [x] 4.5 Assumptions stated explicitly; what is not proven (closed-loop stability of the saturated controller) stated (Remark after Theorem 1; Limitations)
- [x] 4.6 Implemented in the simulator
- [x] 4.7 Certificate soundness checked on every evaluation run (count of violations reported) (0 violations in 560 held-out CLAC runs and 16 test runs)

## 5. Comparison with existing methods (reviewer: compare with existing models)

- [x] 5.1 Periodic time-driven communication
- [x] 5.2 Static event-triggered (Tabuada-style)
- [x] 5.3 Dynamic event-triggered (Girard-style, as in Xie et al. TAES 2024)
- [x] 5.4 Self-triggered (Heemels/Mazo-style)
- [x] 5.5 The authors' previous event rule with prediction
- [x] 5.6 Same simulator, seeds, disturbances and channel draws for all methods
- [x] 5.7 Adaptation of each published method documented honestly (not the original authors' code) (Section VI-A; `docs/V2_METHODS.md`)

## 6. Evaluation protocol

- [x] 6.1 Development seeds (11, 23, 47) used for all tuning
- [x] 6.2 Validation seeds (901, 902)
- [x] 6.3 Source, protocol and parameter lock with SHA-256 hashes created before held-out runs (first lock superseded before any held-out result was read; second lock governs; one backward-compatible default added to `isc_diagnose.m` afterwards, documented in `results/v2/post_lock_changes.md` with a 6-run exact re-check)
- [x] 6.4 Held-out run on new seeds 201–220 (never used before)
- [x] 6.5 Paired bootstrap, 10,000 resamples, 95 % intervals
- [x] 6.6 Independent re-computation of the statistics (`tools/recompute_v2.py`: means equal to 4e-16, CI ends within 0.02 widths)
- [x] 6.7 All tests pass (`run_tests` plus new tests)

## 7. Paper

- [x] 7.1 Contributions rewritten around the new method, theory, realistic optics and official-data validation
- [x] 7.2 New sections: certified coordination, realistic optical model, official-data validation, comparison
- [x] 7.3 Every number in the paper comes from the new held-out CSVs
- [x] 7.4 Figures regenerated
- [x] 7.5 Reference list verified (unverifiable reference [24] resolved) (reference [24] removed; Girard 2015 and Tabuada 2007 pages/DOI confirmed by search; NASA reports cited with NTRS numbers)
- [x] 7.6 Limitations updated to the new evidence
- [x] 7.7 IEEEtran PDF builds, page count checked (8 pages, IEEEtran, no overfull boxes)
- [ ] 7.8 Repository link and data statement correct (**open**: the branch `ieee-transactions-revision` is committed locally but not pushed; push needs the owner's approval)

## 8. Project hygiene

- [x] 8.1 README, CHANGELOG and START_HERE updated
- [x] 8.2 Everything committed on the revision branch
