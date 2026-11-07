# IEEE Transactions revision — 7 November 2026 (branch `ieee-transactions-revision`)

- Added a physical optical model (link budget, receiver noise, bit-error rate, RS(88,72) packet error, lock/acquisition state machine, two-stage terminal dynamics, tracking jitter); validated the budget against the published NASA TBIRD downlink budget (0.07 dB). Legacy optics preserved and regression-tested.
- Added certified, link-aware coordination (CLAC) with a proved online error certificate; 0 violations in 560 held-out runs.
- Added static, dynamic and self-triggered baselines, a star-tree baseline, an isolated-actuator case, multi-link, all-link and random-link fault cases.
- New protocol with a SHA-256 lock (first lock superseded before any held-out result was read; see `docs/V2_PROTOCOL.md`), 2,520 held-out runs on new seeds 201–220, bootstrap analysis and an independent recomputation.
- See `docs/V2_METHODS.md` and `REVISION_CHECKLIST.md`.

# Recovery-audit revision — 22 October 2026

## Frozen rule and held-out statistical extension

- Preserved all development policy rows, including adverse scheduling-only outcomes; no general optical classification accuracy claim is added.
- Added an explicit candidate rule: no aggressive retries; throttle only valid estimated infeasibility; extend prediction only with local degraded optical evidence, a bounded message age, and sufficiently slow observed parent-rate change.
- Locally locked protocol, model/policy sources, and analysis code before held-out evaluation. No rule retuning is based on these results.
- Added 20 independent held-out run seeds with paired initial states, reference phases, disturbance phases/amplitudes, and channel realizations; validation uses separate seeds.
- Added new fault magnitudes/durations, a new combined severity, beam mismatch, and an alternate tree/network case: 440 declared runs, with case-specific 95% pointwise paired-seed bootstrap intervals.
- Added five policy/input checks and an independent synthetic bootstrap check. Engineering integration, statistical scope, and algorithmic novelty remain separate in `docs/CLAIMS_AND_LIMITS.md`.

## Communication-dependent tracking extension

- Added a moving-reference mission condition with reference-command access restricted to the leader, known relative offsets, immutable parent-state packets, and a declared sparse logical chain.
- Retained the local feedback/observer structure with a new target/rate wrapper; did not claim the original paper's self-triggered controller.
- Added exact quaternion-geodesic pair/leader/command errors, fault-window metrics, payload overhead, parent age, and conditional optical-estimation scores.
- Declared a pilot gate and hypotheses before policy comparisons. Added diagnosis-derived feasibility/severity and optional scheduling-only, prediction-only, and joint policies.
- Added the full consistent P/A/T factorial plus a separate severe attenuation control: 108 main trials and 45 policy ablations, with paired-seed interaction contrasts.
- Added seven tracking checks, including a blackout test proving followers do not receive a hidden reference, and 32 s live Simulink parity through fault onset.
- Made moving-reference tracking the `start_project` default. Management remains off by default; adverse or neutral policy results are retained.

## Earlier optical audit

- Fixed optical-fit invalidation to clear the sample arrays and reset the ring count and write position together. Partial refits can no longer read stale pre-invalidation slots.
- Added a regression check; all eleven core checks pass.
- Added audit-only physical logs: terminal encoder position, injected boresight offset, optical gain/blockage, estimated offset/validity, and noisy pilot power. Feedback APIs remain limited to observations and nominal parameters.
- Added explicit hidden plant perturbations for beam-width calibration and pointing-fault magnitude tests.
- Added `audit_recovery.m`, ten targeted conditions across three seeds, independent geometry-to-power reconstruction, session-rule checks, steering-bound checks, and a zoomed onset plot.
- Rechecked live Simulink parity, step-size sensitivity, and stale-compensation removal.
- Regenerated the full 90-trial benchmark after the correction and retained per-trial measurements.
- Documented the failed 15% beam-width mismatch test, failed no-dither test, intermittent threshold crossings under severely limited correction, and the difference between instantaneous power eligibility and sustained verified recovery.

The nominal affected-link availability remains 96.86%. That matched-model outcome is a model-level result; the audit does not establish calibration-independent or hardware-validated recovery.
