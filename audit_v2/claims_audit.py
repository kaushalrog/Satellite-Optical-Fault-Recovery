"""AUDIT: re-derive every quantitative manuscript claim from the raw held-out trial CSVs (not from means_ci.csv)."""
import csv,glob,math,json
import numpy as np
rows=[]
for f in sorted(glob.glob('results/v2/trials_heldout_*.csv')):rows+=list(csv.DictReader(open(f,encoding='utf-8-sig')))
D={(r['case_name'],r['method'],int(r['seed'])):r for r in rows}
seeds=sorted({int(r['seed']) for r in rows});cases=list(dict.fromkeys(r['case_name'] for r in rows))
rng=np.random.default_rng(777);B=rng.integers(0,20,size=(40000,20))
def v(c,m,f,k=1.0):
    if c=='ALL':return np.mean([[float(D[(cc,m,s)][f])*k for s in seeds] for cc in cases],axis=0)
    return np.array([float(D[(c,m,s)][f])*k for s in seeds])
DEG=180/math.pi
def pct(c,m,b,f='fault_pair_rms_rad'):
    x=100*(v(c,m,f)/v(c,b,f)-1);bs=x[B].mean(1);return x.mean(),*np.quantile(bs,[.025,.975])
out=[];fails=0
def chk(name,got,exp,tol,note=''):
    global fails
    ok=abs(got-exp)<=tol;fails+=(not ok);out.append((name,'PASS' if ok else 'FAIL',f'{got:.4g}',f'{exp:.4g}',note))
def chkci(name,got,exp):
    for g,e,lab in zip(got,exp,['mean','lo','hi']):chk(f'{name} {lab}',g,e,0.35 if lab!='mean' else 0.06)
chk('run count',len(rows),2520,0);chk('conditions',len(cases),14,0);chk('seeds',len(seeds),20,0)
chkci('A: CLAC vs EO star ALL pair %',pct('ALL','clac','eo_star'),(-58.4,-61.2,-55.8))
chk('A: CLAC vs DET ALL pair %',pct('ALL','clac','dynamic_star')[0],-58.1,.06);chk('A: CLAC vs ST ALL pair %',pct('ALL','clac','self_star')[0],-57.6,.06)
chkci('A: payload vs EO star',pct('ALL','clac','eo_star','state_payload_bytes'),(14.5,12.7,16.2))
chkci('A: payload vs ST',pct('ALL','clac','self_star','state_payload_bytes'),(8.9,6.9,10.7))
chk('payload vs DET %',pct('ALL','clac','dynamic_star','state_payload_bytes')[0],9.6,.06);chk('payload vs periodic %',pct('ALL','clac','periodic','state_payload_bytes')[0],-45.4,.06)
chkci('healthy CLAC vs EO star',pct('healthy','clac','eo_star'),(0.1,-0.3,0.7))
for c in ['healthy','actuator_isolated']:
    chk(f'{c} CLAC vs DET %',pct(c,'clac','dynamic_star')[0],1.8,.06);chk(f'{c} CLAC vs ST %',pct(c,'clac','self_star')[0],2.3,.06)
chk('severe attenuation CLAC pair deg',v('attenuation_severe','clac','fault_pair_rms_rad',DEG).mean(),0.195,.0006)
chkci('severe attenuation vs EO star',pct('attenuation_severe','clac','eo_star'),(-81.1,-82.6,-79.6))
star=[v('attenuation_severe',m,'fault_pair_rms_rad',DEG).mean() for m in ['periodic','eo_chain','eo_star','zoh_star','dynamic_star','self_star','clac_fixed']]
out.append(('text "star and chain methods stay at about 1.05 deg"','NOTE',f'{min(star):.3f}-{max(star):.3f}','~1.05','range 1.00-1.07: wording should give the range'))
chkci('random-link outage vs EO star',pct('random_link_outage','clac','eo_star'),(-44.9,-61.9,-27.9))
chkci('two-link outage vs EO star',pct('two_link_outage','clac','eo_star'),(-71.4,-80.5,-59.2))
for c,e in [('pointing_single',-21.2),('pointing_multilink',-18.6),('pointing_all_links',-16.9)]:chk(f'{c} vs EO star %',pct(c,'clac','eo_star')[0],e,.06)
chkci('jitter vs EO star',pct('jitter_high','clac','eo_star'),(-71.2,-77.3,-64.1));chkci('slow acquisition vs EO star',pct('slow_acquisition','clac','eo_star'),(-42.6,-55.3,-29.8))
chk('CLAC jitter pair deg',v('jitter_high','clac','fault_pair_rms_rad',DEG).mean(),.293,.0006);chk('CLAC slow-acq pair deg',v('slow_acquisition','clac','fault_pair_rms_rad',DEG).mean(),.363,.0006)
chk('ideal actuator-only deg',v('actuator_isolated','ideal','fault_pair_rms_rad',DEG).mean(),.343,.0006);chk('ideal healthy deg',v('healthy','ideal','fault_pair_rms_rad',DEG).mean(),.333,.0006)
chk('CLAC actuator-only deg',v('actuator_isolated','clac','fault_pair_rms_rad',DEG).mean(),.119,.0006);chk('CLAC healthy deg',v('healthy','clac','fault_pair_rms_rad',DEG).mean(),.116,.0006)
chk('CLAC payload kB',v('ALL','clac','state_payload_bytes').mean()/1e3,78.6,.06);chk('CLAC attempts',v('ALL','clac','attempted_packets').mean(),893,.6)
chk('CLAC-fixed payload kB',v('ALL','clac_fixed','state_payload_bytes').mean()/1e3,49.1,.06)
chk('ALL pair CLAC-fixed deg',v('ALL','clac_fixed','fault_pair_rms_rad',DEG).mean(),.604,.0006);chk('ALL pair periodic deg',v('ALL','periodic','fault_pair_rms_rad',DEG).mean(),.604,.0006)
chk('healthy chain/star ratio (EO chain/CLAC)',v('healthy','eo_chain','fault_pair_rms_rad').mean()/v('healthy','clac','fault_pair_rms_rad').mean(),3.17,.1,'text says "about 3 times"')
cl=[r for r in rows if r['method']=='clac'];cf=[r for r in rows if r['method']=='clac_fixed']
chk('CLAC runs',len(cl),280,0);chk('CLAC-fixed runs',len(cf),280,0)
chk('parent switches mean (CLAC runs only)',np.mean([float(r['parent_switches']) for r in cl]),4.3,.06);chk('parent switches max',max(float(r['parent_switches']) for r in cl),10,0)
chk('median tightness (median of per-run medians, CLAC)',float(np.median([float(r['cert_tightness_median']) for r in cl])),0.95,.006)
chk('CLAC+fixed metric violations',sum(float(r['cert_violation_fraction'])>0 for r in cl+cf),0,0,'stored metric = attitude only')
out.append(('abstract "never violated in 560 CLAC runs"','FAIL','280 CLAC + 280 CLAC-fixed','560 CLAC','wording error; fix to 560 trajectories (280+280)'));fails+=1
eo=v('ALL','eo_chain','state_payload_bytes').mean()/1e3
out.append(('EO chain within 1.05x budget on held-out',('PASS' if eo<=1.05*78.6 else 'NOTE'),f'{eo:.1f} kB',f'{1.05*76.7:.1f} (dev budget)','budget defined on development seeds'))
for m in ['eo_star','zoh_star','dynamic_star','self_star']:
    p=v('ALL',m,'state_payload_bytes').mean()/1e3;out.append((f'baseline payload {m}','NOTE',f'{p:.1f} kB','78.6 kB (CLAC)',f'{100*(p/78.6-1):.1f}% vs CLAC: "matched" is an upper bound, not equality'))
w=csv.writer(open('audit_v2/results/claims_audit.csv','w',newline=''));w.writerow(['claim','status','recomputed','manuscript','note']);w.writerows(out)
for r in out:
    if r[1]!='PASS':print(r)
print(f'{sum(r[1]=="PASS" for r in out)} PASS, {sum(r[1]=="FAIL" for r in out)} FAIL, {sum(r[1]=="NOTE" for r in out)} NOTE of {len(out)}')
