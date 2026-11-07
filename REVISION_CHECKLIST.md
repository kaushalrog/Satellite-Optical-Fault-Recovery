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

- [ ] 0.1 Old state tagged `manuscript-v1`; revision branch created
- [ ] 0.2 Legacy optics kept as `optics='legacy'`; old 440-run results still reproduce (regression test)

## 1. Realistic optical model (reviewer: Gaussian beam + instantaneous threshold)

- [ ] 1.1 Physical link budget from first principles (transmit power, optics losses, Gaussian-beam gain, range, receive aperture)
- [ ] 1.2 Receiver noise (thermal, shot, background) and bit-error rate from received power
- [ ] 1.3 Forward error correction: codeword and packet error probability from BER (replaces the constant 2 % random loss)
- [ ] 1.4 Acquisition, tracking and lock-loss state machine with hysteresis and acquisition dwell
- [ ] 1.5 Terminal dynamics: two-stage lag with rate limit, tracking jitter, encoder noise
- [ ] 1.6 Derived availability threshold (an output of the receiver model, not an input)
- [ ] 1.7 Unit tests for budget, BER monotonicity, FEC, lock hysteresis

## 2. Validation against official data (reviewer: use NASA/ISRO data)

- [ ] 2.1 NASA TBIRD published downlink budget (−52.9 dB W/m²) reproduced by the link-budget code within 0.25 dB
- [ ] 2.2 Beam width, tracking jitter, pointing loss and acquisition time calibrated to published TBIRD measurements, each with its source table or section
- [ ] 2.3 Written statement of what is real published data and what is modelled; raw flight telemetry not public; no ISRO inter-satellite-link data found
- [ ] 2.4 Evaluation stress cases taken from published TBIRD values (35 µrad tracking RMS, 10–30 s pull-in)

## 3. Fault coverage (reviewer: isolated actuator, multi-link pointing)

- [ ] 3.1 Isolated actuator-degradation held-out case (no optical fault)
- [ ] 3.2 Pointing bias on all three active links with different bias vectors
- [ ] 3.3 Worst case: pointing bias on all six physical links
- [ ] 3.4 Healthy (no-fault) case to measure false actions

## 4. Novel method with proven properties (reviewer: originality)

- [ ] 4.1 Literature check of closest work, with a claim limited to what the search supports
- [ ] 4.2 Method specified: certified, link-aware coordination (CLAC)
- [ ] 4.3 Lemma: prediction-error certificate on SO(3), full proof
- [ ] 4.4 Theorem: online-computable bound on every follower's tracking error under arbitrary delay, loss and outage, full proof
- [ ] 4.5 Assumptions stated explicitly; what is not proven (closed-loop stability of the saturated controller) stated
- [ ] 4.6 Implemented in the simulator
- [ ] 4.7 Certificate soundness checked on every evaluation run (count of violations reported)

## 5. Comparison with existing methods (reviewer: compare with existing models)

- [ ] 5.1 Periodic time-driven communication
- [ ] 5.2 Static event-triggered (Tabuada-style)
- [ ] 5.3 Dynamic event-triggered (Girard-style, as in Xie et al. TAES 2024)
- [ ] 5.4 Self-triggered (Heemels/Mazo-style)
- [ ] 5.5 The authors' previous event rule with prediction
- [ ] 5.6 Same simulator, seeds, disturbances and channel draws for all methods
- [ ] 5.7 Adaptation of each published method documented honestly (not the original authors' code)

## 6. Evaluation protocol

- [ ] 6.1 Development seeds (11, 23, 47) used for all tuning
- [ ] 6.2 Validation seeds (901, 902)
- [ ] 6.3 Source, protocol and parameter lock with SHA-256 hashes created before held-out runs
- [ ] 6.4 Held-out run on new seeds 201–220 (never used before)
- [ ] 6.5 Paired bootstrap, 10,000 resamples, 95 % intervals
- [ ] 6.6 Independent re-computation of the statistics
- [ ] 6.7 All tests pass (`run_tests` plus new tests)

## 7. Paper

- [ ] 7.1 Contributions rewritten around the new method, theory, realistic optics and official-data validation
- [ ] 7.2 New sections: certified coordination, realistic optical model, official-data validation, comparison
- [ ] 7.3 Every number in the paper comes from the new held-out CSVs
- [ ] 7.4 Figures regenerated
- [ ] 7.5 Reference list verified (unverifiable reference [24] resolved)
- [ ] 7.6 Limitations updated to the new evidence
- [ ] 7.7 IEEEtran PDF builds, page count checked
- [ ] 7.8 Repository link and data statement correct

## 8. Project hygiene

- [ ] 8.1 README, CHANGELOG and START_HERE updated
- [ ] 8.2 Everything committed on the revision branch
