# Protocol v3: guaranteed-accuracy triggering (GAT)

Written and hash-locked before the held-out run. The v2 study (CLAC, seeds 201–220) is kept unchanged at tag `v2-clac-heldout-frozen`; its results are in `results/v2/` and still reproduce with the current code (`tests/test_gat.m`, 6 exact re-runs).

## New method (one idea)
The user sets a tolerance ε (rad). After each transmission the sender computes, from the bounds it is sending and the command-class constants, the time at which the receiver's certified *communication-induced* target error E(a) − H would reach ε, and sends again that time minus a delay margin (0.25 s), never later than 2 s and never sooner than 0.1 s. No state is monitored. Parents are chosen by the smallest certified bound (as in CLAC). Variant `gat_fixed` keeps a static leader-fed star.
Guarantee (proved in the paper): if the link is up, the previous packet arrived within the delay margin and the parent knows it is the parent, E(a) − H ≤ ε at every instant. Losses and outages void it, and the certificate then reports the actual bound.

## Development tuning (seeds 11/23/47 only; `tuning/tune_v3.m`, `results/v3/tuning_*.csv`)
Five of the 17 held-out condition types were used for tuning (pointing_single, combined, random_link_pointing, random_link_outage, actuator_isolated). Rule: ε is the largest grid value at which traffic still depends on ε (above 2 mrad traffic saturates at the 2 s cap): ε = 1 mrad. Overhead periods (standby 6 s, report 2 s) were chosen because (3 s, 1 s) added 13 kB for under 1 % accuracy at ε = 1 mrad. All other methods keep their frozen v2 settings (payload cap 1.05 × 76.7 kB).

## Held-out evaluation
Seeds 401–420 (never used before). 17 conditions: the 14 of v2 plus three never used in tuning or earlier runs: ramp_link_pointing (bias ramps to 1.4 x on a random link), intermittent_link_outage (3 s outages every 8 s on a random link), outage_plus_actuator (random-link outage with SC3 actuator effectiveness 0.30/0.45/0.35). Ten methods: ideal, periodic, eo_chain, eo_star, zoh_star, dynamic_star, self_star, clac, gat_fixed, gat. 3,400 runs.
Primary outcome: fault-window pair RMS (deg); secondary: payload bytes, attempts; certificate violations (attitude and rate) for clac, gat_fixed, gat; fraction of samples meeting the tolerance (all, pre-fault, and restricted to samples with a locked parent link). Paired bootstrap, 10,000 resamples, 95 % percentile intervals over seeds, exploratory, unadjusted. Independent recomputation by `tools/recompute_v3.py`.
