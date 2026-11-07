# Revised evaluation protocol (physical optics, certified coordination)

This protocol was written and hash-locked **before** the held-out seeds were run.

## Seeds

| Role | Seeds | Use |
|---|---|---|
| Development | 11, 23, 47 | every tuning decision (`tuning/tune_v2.m`, results in `results/v2/tuning_*.csv`) |
| Validation | 901, 902 | smoke check of all 14 conditions x 9 methods before the lock; not used for tuning |
| Held-out | 201–220 | final comparison, run once after the lock |

Held-out seeds were never used in any earlier version of this project (earlier held-out seeds were 101–120).

## Conditions (14)

healthy; pointing_single; pointing_multilink (three different bias vectors on the three chain links); pointing_all_links (all six physical links); actuator_isolated (SC2 actuator effectiveness 0.30/0.45/0.35, optics untouched); attenuation_severe (gain 0.08 on link 1–2); combined (pointing + attenuation + actuator); beam_mismatch (true beam 10 % narrower); network_transfer (alternate tree, 0.2 s delay, 10 % extra loss); jitter_high (35 µrad tracking RMS); slow_acquisition (15 s pull-in); random_link_pointing; random_link_outage; two_link_outage. In the three random-link conditions the faulty link(s) are drawn from the seed (held-out seeds: balanced over the six links) and are identical for every method.

## Methods (9)

ideal, periodic, eo_chain, eo_star, zoh_star, dynamic_star, self_star, clac_fixed, clac (see `docs/V2_METHODS.md`).

## Budget matching

Each baseline's single free parameter is set on development seeds to the most accurate value whose mean payload does not exceed 1.05 x the payload of CLAC (76.7 kB). The authors' previous event rule (eo_chain, eo_star) keeps its published thresholds, which fall inside that budget. Selected values are frozen in `src/isc_v2_method.m`.

## Outcomes

Primary: pair attitude RMS in the fault window (degrees). Secondary: follower tracking RMS, attempted packets, payload bytes (64 B baseline packet; 88 B CLAC packet), certificate violations (CLAC), parent switches. Statistics: paired run-seed bootstrap, 10,000 resamples, 95 % percentile intervals, seed as the unit, exploratory and not adjusted for multiplicity. An independent standard-library Python recomputation re-derives every mean.

## Integrity

`results/v2/lock.json` stores SHA-256 hashes of all sources, tuning outputs and this protocol; `tools/freeze_v2.py` refuses to run the held-out evaluation analysis if any hash changed. The lock is a local record, not a public preregistration.

## Lock history

A first lock (`results/v2/superseded_lock1/lock.json`) was created and the held-out batch started. Before any held-out result was read or analysed, the proof of Lemma 1 showed that the extrapolation bound needed a larger constant (factor `1+wbar*a` on the incoming attitude bound, and a rate-bound term `wbar*(E+H)`). The batch was stopped, its partial output deleted, the bound in `src/isc_clac.m` corrected, the proposed method's one tuned parameter re-checked on development seeds (unchanged at 0.8; payload 76.7 kB, so baseline budgets are unchanged), the tests re-run, and a second lock created. Only the second lock governs the reported results.
