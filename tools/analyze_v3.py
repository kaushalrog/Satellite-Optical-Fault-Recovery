"""Paired run-seed bootstrap analysis of the revised held-out evaluation (seeds 201-220).
Tables use the Python standard library only; figures need matplotlib."""
from pathlib import Path
import csv,glob,json,math,random,statistics
from freeze_v3 import verify
import os
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/('results/'+os.environ.get('V3_DIR','v3'))
METHODS=['ideal','periodic','eo_chain','eo_star','zoh_star','dynamic_star','self_star','clac','gat_fixed','gat']
LABEL={'ideal':'Ideal comm.','periodic':'Periodic','eo_chain':'EO chain','eo_star':'EO star','zoh_star':'Static ETC (ZOH)',
       'dynamic_star':'Dynamic ETC','self_star':'Self-triggered','clac':'CLAC','gat_fixed':'GAT fixed','gat':'GAT'}
CASES=['healthy','pointing_single','pointing_multilink','pointing_all_links','actuator_isolated','attenuation_severe',
       'combined','beam_mismatch','network_transfer','jitter_high','slow_acquisition','random_link_pointing',
       'random_link_outage','two_link_outage','ramp_link_pointing','intermittent_link_outage','outage_plus_actuator']
FIELDS={'fault_pair_rms_rad':180/math.pi,'fault_follower_tracking_rms_rad':180/math.pi,'attempted_packets':1,'state_payload_bytes':1,
        'fault_control_effort_N2m2s':1}
def load():
    rows=[]
    for f in sorted(glob.glob(str(OUT/'trials_heldout_*.csv'))):
        rows+=list(csv.DictReader(open(f,newline='',encoding='utf-8-sig')))
    return rows
def main():
    lock=verify();rows=load()
    assert len(rows)==lock['planned_trials'],len(rows)
    assert set(int(r['seed']) for r in rows)==set(lock['evaluation_seeds'])
    assert all(float(r['queue_overflows'])==0 for r in rows)
    assert max(float(r['quaternion_norm_error']) for r in rows)<1e-12
    seeds=lock['evaluation_seeds'];n=len(seeds)
    rng=random.Random(lock['bootstrap_analysis_seed'])
    idx=[rng.choices(range(n),k=n) for _ in range(lock['bootstrap_resamples'])]
    def interval(v):
        assert len(v)==n and all(math.isfinite(x) for x in v)
        s=sorted(sum(v[i] for i in d)/n for d in idx)
        def q(p):
            pos=(len(s)-1)*p;i=int(pos);f=pos-i
            return s[i]*(1-f)+s[min(i+1,len(s)-1)]*f
        return statistics.mean(v),q(.025),q(.975)
    table={}
    for r in rows:table[(r['case_name'],r['method'],int(r['seed']))]=r
    def vec(case,method,field,scale=None):
        k=FIELDS[field] if scale is None else scale
        return [float(table[(case,method,s)][field])*k for s in seeds]
    summary=[];contrasts=[]
    for case in CASES:
        for m in METHODS:
            for field,k in FIELDS.items():
                mean,lo,hi=interval(vec(case,m,field))
                summary.append(dict(case_name=case,method=m,metric=field,n=n,mean=mean,ci_low=lo,ci_high=hi))
    # pooled over all conditions: per-seed average across conditions, then bootstrap over seeds
    for m in METHODS:
        for field in FIELDS:
            per=[statistics.mean(vec(c,m,field)[i] for c in CASES) for i in range(n)]
            mean,lo,hi=interval(per);summary.append(dict(case_name='ALL_CONDITIONS',method=m,metric=field,n=n,mean=mean,ci_low=lo,ci_high=hi))
    base=['eo_chain','eo_star','zoh_star','dynamic_star','self_star','periodic','clac','gat_fixed']
    for foc in ['gat','clac']:
      for case in CASES+['ALL_CONDITIONS']:
        for b in base:
            if b==foc:continue
            for field in ['fault_pair_rms_rad','state_payload_bytes']:
                if case=='ALL_CONDITIONS':
                    x1=[statistics.mean(vec(c,foc,field)[i] for c in CASES) for i in range(n)]
                    z=[statistics.mean(vec(c,b,field)[i] for c in CASES) for i in range(n)]
                else:x1=vec(case,foc,field);z=vec(case,b,field)
                for scale in ['absolute','percent']:
                    v=[x-y for x,y in zip(x1,z)] if scale=='absolute' else [100*(x/y-1) for x,y in zip(x1,z)]
                    mean,lo,hi=interval(v)
                    contrasts.append(dict(case_name=case,comparison=f'{foc}_minus_{b}',metric=field,scale=scale,n=n,mean=mean,ci_low=lo,ci_high=hi))
    certrows=[r for r in rows if r['method'] in('clac','gat_fixed','gat')]
    cert_att=sum(1 for r in certrows if float(r['cert_violation_fraction'])>0);cert_rate=sum(1 for r in certrows if float(r['cert_rate_violation_fraction'])>0)
    g={}
    for m in ['gat_fixed','gat']:
        rs=[r for r in rows if r['method']==m and r['case_name']=='healthy']
        g[m]={k:statistics.mean(float(r[k]) for r in rs) for k in ['gat_guarantee_locked_prefault','gat_guarantee_fraction_prefault']}
        g[m]['all_conditions_locked']=statistics.mean(float(r['gat_guarantee_locked']) for r in rows if r['method']==m)
    def write(name,data):
        with (OUT/name).open('w',newline='',encoding='utf-8') as f:
            w=csv.DictWriter(f,fieldnames=list(data[0]));w.writeheader();w.writerows(data)
    write('means_ci.csv',summary);write('paired_contrasts_ci.csv',contrasts)
    json.dump({'certificate_runs':len(certrows),'runs_with_attitude_violation':cert_att,'runs_with_rate_violation':cert_rate,'guarantee_healthy':g},open(OUT/'certificate_summary.json','w'),indent=1)
    def res(case,m,f):return next(r for r in summary if r['case_name']==case and r['method']==m and r['metric']==f)
    def ctr(case,b,f,s='absolute',foc='gat'):return next(r for r in contrasts if r['case_name']==case and r['comparison']==f'{foc}_minus_{b}' and r['metric']==f and r['scale']==s)
    def fmt(r,d=3):return f'{r["mean"]:.{d}f} [{r["ci_low"]:.{d}f}, {r["ci_high"]:.{d}f}]'
    L=['# Revised held-out evaluation (seeds 201–220, physical optics)','',
       f'{len(rows)} runs: 14 conditions x 9 methods x {n} seeds. 95% percentile bootstrap intervals (10,000 resamples, seed as unit); exploratory; not adjusted for multiplicity.','',
       f'Certificate violations (attitude / rate): {cert_att} / {cert_rate} of {len(certrows)} CLAC, GAT-fixed and GAT runs.','',
       '## Fault-window pair RMS (deg), mean [95% CI]','',
       '| Condition | '+' | '.join(LABEL[m] for m in METHODS)+' |','|---|'+'---:|'*len(METHODS)]
    for case in CASES+['ALL_CONDITIONS']:
        L.append(f'| {case} | '+' | '.join(fmt(res(case,m,"fault_pair_rms_rad")) for m in METHODS)+' |')
    L+=['','## Payload (kB per run), mean','','| Condition | '+' | '.join(LABEL[m] for m in METHODS)+' |','|---|'+'---:|'*len(METHODS)]
    for case in CASES+['ALL_CONDITIONS']:
        L.append(f'| {case} | '+' | '.join(f'{res(case,m,"state_payload_bytes")["mean"]/1000:.1f}' for m in METHODS)+' |')
    for foc in ['gat','clac']:
        L+=['',f'## {foc.upper()} minus baseline, pair RMS change (%), mean [95% CI]','','| Condition | '+' | '.join(LABEL[b] for b in base if b!=foc)+' |','|---|'+'---:|'*len([b for b in base if b!=foc])]
        for case in CASES+['ALL_CONDITIONS']:
            L.append(f'| {case} | '+' | '.join(fmt(ctr(case,b,"fault_pair_rms_rad","percent",foc),1) for b in base if b!=foc)+' |')
        L+=['',f'## {foc.upper()} minus baseline, payload change (%)','','| Condition | '+' | '.join(LABEL[b] for b in base if b!=foc)+' |','|---|'+'---:|'*len([b for b in base if b!=foc])]
        for case in CASES+['ALL_CONDITIONS']:
            L.append(f'| {case} | '+' | '.join(fmt(ctr(case,b,"state_payload_bytes","percent",foc),1) for b in base if b!=foc)+' |')
    (OUT/'REPORT.md').write_text('\n'.join(L)+'\n',encoding='utf-8')
    print('ANALYSIS_DONE',len(summary),'summary rows',len(contrasts),'contrasts')
if __name__=='__main__':main()
