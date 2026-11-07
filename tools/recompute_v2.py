"""Independent re-computation of means and bootstrap intervals with a different code path
(numpy, different RNG stream). Means must match exactly; interval ends within Monte-Carlo error."""
from pathlib import Path
import csv,glob
import numpy as np
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'results/v2'
rows=[]
for f in sorted(glob.glob(str(OUT/'trials_heldout_*.csv'))):rows+=list(csv.DictReader(open(f,encoding='utf-8-sig')))
ref=list(csv.DictReader(open(OUT/'means_ci.csv')))
K={'fault_pair_rms_rad':180/np.pi,'fault_follower_tracking_rms_rad':180/np.pi,'attempted_packets':1,'state_payload_bytes':1,'fault_control_effort_N2m2s':1}
d={}
for r in rows:d.setdefault((r['case_name'],r['method'],r['seed']),r)
cases=list(dict.fromkeys(r['case_name'] for r in rows));seeds=sorted(set(r['seed'] for r in rows),key=int)
rng=np.random.default_rng(12345);B=rng.integers(0,len(seeds),size=(20000,len(seeds)))
worst_mean=0;worst_ci=0
for x in ref:
    c,m,f=x['case_name'],x['method'],x['metric']
    if c=='ALL_CONDITIONS':v=np.mean([[float(d[(cc,m,s)][f])*K[f] for s in seeds] for cc in cases],axis=0)
    else:v=np.array([float(d[(c,m,s)][f])*K[f] for s in seeds])
    mean=v.mean();bs=v[B].mean(axis=1);lo,hi=np.quantile(bs,[.025,.975])
    worst_mean=max(worst_mean,abs(mean-float(x['mean']))/max(abs(mean),1e-12))
    w=max(hi-lo,1e-12);worst_ci=max(worst_ci,abs(lo-float(x['ci_low']))/w,abs(hi-float(x['ci_high']))/w)
print(f'RECOMPUTE: {len(ref)} cells; worst relative mean difference {worst_mean:.2e}; worst CI-end difference {worst_ci:.3f} interval widths')
assert worst_mean<1e-9 and worst_ci<0.08
print('RECOMPUTE_PASS')
