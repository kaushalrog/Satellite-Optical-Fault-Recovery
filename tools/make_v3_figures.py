"""Figures/tables for the GAT paper from results/v3 (held-out) and the development sweeps."""
from pathlib import Path
import csv,sys
import numpy as np
import matplotlib;matplotlib.use('Agg')
import matplotlib.pyplot as plt
ROOT=Path(__file__).resolve().parents[1];import os
R3=ROOT/('results/'+os.environ.get('V3_DIR','v3'));R2=ROOT/'results/v2';RT=ROOT/'results/v3'
DEST=Path(sys.argv[1]);DEST.mkdir(parents=True,exist_ok=True)
plt.rcParams.update({'font.size':7,'font.family':'serif','axes.linewidth':.6,'lines.linewidth':1.0,'pdf.fonttype':42})
COL={'periodic':'#999999','eo_chain':'#7a5195','eo_star':'#0072b2','zoh_star':'#e69f00','dynamic_star':'#009e73','self_star':'#cc79a7','clac':'#d55e00','gat_fixed':'#56b4e9','gat':'#b2182b'}
LAB={'periodic':'Periodic','eo_chain':'EO chain','eo_star':'EO star','zoh_star':'Static ETC','dynamic_star':'Dynamic ETC','self_star':'Self-triggered','clac':'CLAC','gat_fixed':'GAT fixed','gat':'GAT'}
rows=list(csv.DictReader(open(R3/'means_ci.csv')));con=list(csv.DictReader(open(R3/'paired_contrasts_ci.csv')))
cases=list(dict.fromkeys(r['case_name'] for r in rows))
names={'healthy':'Healthy','pointing_single':'Pointing, 1 link','pointing_multilink':'Pointing, 3 links','pointing_all_links':'Pointing, 6 links','actuator_isolated':'Actuator only','attenuation_severe':'Severe attenuation','combined':'Combined','beam_mismatch':'Beam mismatch','network_transfer':'Network transfer','jitter_high':'35 $\\mu$rad jitter','slow_acquisition':'15 s pull-in','random_link_pointing':'Pointing, random link','random_link_outage':'Outage, random link','two_link_outage':'Outage, two links','ramp_link_pointing':'Pointing ramp*','intermittent_link_outage':'Intermittent outage*','outage_plus_actuator':'Outage + actuator*','ALL_CONDITIONS':'Mean of 17'}
def get(c,m,f='fault_pair_rms_rad'):return next(r for r in rows if r['case_name']==c and r['method']==m and r['metric']==f)
# pair bars
M=['periodic','eo_star','dynamic_star','self_star','clac','gat']
fig,ax=plt.subplots(figsize=(7.1,2.9));w=.8/len(M);x=np.arange(len(cases))
for k,m in enumerate(M):
    v=np.array([[float(get(c,m)[q]) for q in ('mean','ci_low','ci_high')] for c in cases])
    ax.bar(x+(k-len(M)/2+.5)*w,v[:,0],w,yerr=[v[:,0]-v[:,1],v[:,2]-v[:,0]],color=COL[m],label=LAB[m],error_kw=dict(lw=.5,capsize=.8))
ax.set_xticks(x);ax.set_xticklabels([names[c].replace('$\\mu$','µ') for c in cases],rotation=38,ha='right');ax.set_ylabel('Fault-window pair RMS (deg)')
ax.legend(ncol=6,frameon=False,loc='upper center',bbox_to_anchor=(.5,1.16),fontsize=6.5);fig.tight_layout(pad=.3);fig.savefig(DEST/'fig_v3_pair.pdf');plt.close(fig)
# trade-off (held-out, mean of 17)
fig,ax=plt.subplots(figsize=(3.4,2.5))
for m in ['periodic','eo_chain','eo_star','zoh_star','dynamic_star','self_star','clac','gat_fixed','gat']:
    e=get('ALL_CONDITIONS',m);b=get('ALL_CONDITIONS',m,'state_payload_bytes')
    ax.errorbar(float(b['mean'])/1e3,float(e['mean']),yerr=[[float(e['mean'])-float(e['ci_low'])],[float(e['ci_high'])-float(e['mean'])]],fmt='o',ms=4,color=COL[m],elinewidth=.6,capsize=1)
    ax.annotate(LAB[m],(float(b['mean'])/1e3,float(e['mean'])),xytext=(3,3),textcoords='offset points',fontsize=6)
ax.set_xlabel('Mean payload per run (kB)');ax.set_ylabel('Pair RMS, mean of 17 conditions (deg)');ax.set_xlim(0,160)
fig.tight_layout(pad=.3);fig.savefig(DEST/'fig_v3_tradeoff.pdf');plt.close(fig)
# tolerance dial (development seeds)
fig,ax=plt.subplots(figsize=(3.4,2.5))
for name,col,lab in [('gat',COL['gat'],'GAT'),('gat_fixed',COL['gat_fixed'],'GAT fixed')]:
    d=[r for r in csv.DictReader(open(RT/f'tuning_{name}.csv'))]
    for ov in sorted({(r['standby_s'],r['report_s']) for r in d}):
        s=[r for r in d if (r['standby_s'],r['report_s'])==ov]
        if name=='gat' and ov!=('6','2'):continue
        ax.plot([float(r['payload_bytes'])/1e3 for r in s],[float(r['pair_rms_deg']) for r in s],'-o',ms=3,color=col,label=lab)
        for r in s:ax.annotate(f"{float(r['tol_rad'])*1e3:g}",(float(r['payload_bytes'])/1e3,float(r['pair_rms_deg'])),xytext=(2,2),textcoords='offset points',fontsize=5)
for name,lab in [('eo_star','EO star'),('self','Self-trig.'),('dynamic','Dynamic ETC'),('zoh','Static ETC')]:
    d=list(csv.DictReader(open(R2/f'tuning_{name}.csv')));c=COL.get({'self':'self_star','dynamic':'dynamic_star','zoh':'zoh_star'}.get(name,name))
    ax.plot([float(r['payload_bytes'])/1e3 for r in d],[float(r['pair_rms_deg']) for r in d],'-',lw=.6,color=c,label=lab)
d=list(csv.DictReader(open(R2/'tuning_clac.csv')));ax.plot([float(r['payload_bytes'])/1e3 for r in d],[float(r['pair_rms_deg']) for r in d],'s',ms=3,color=COL['clac'],label='CLAC')
ax.set_xscale('log');ax.set_xlabel('Payload (kB), development seeds');ax.set_ylabel('Pair RMS (deg)');ax.legend(frameon=False,fontsize=5.5,ncol=2)
fig.tight_layout(pad=.3);fig.savefig(DEST/'fig_v3_dial.pdf');plt.close(fig)
# trace
a=np.genfromtxt(R3/'figdata_trace_eo_star.csv',delimiter=',',names=True);b=np.genfromtxt(R3/'figdata_trace_gat.csv',delimiter=',',names=True)
fig,ax=plt.subplots(2,1,figsize=(3.4,3.5),sharex=True,gridspec_kw=dict(height_ratios=[3,1.1]))
for q in ax:q.axvspan(25,60,color='#eeeeee',lw=0)
ax[0].plot(a['t'],a['err4_deg'],color=COL['eo_star'],label='EO star');ax[0].plot(b['t'],b['err4_deg'],color=COL['gat'],label='GAT')
ax[0].set_yscale('log');ax[0].set_ylim(1e-2,5e1);ax[0].set_ylabel('SC4 error (deg)');ax[0].legend(frameon=False,fontsize=6,loc='lower right')
ax[1].step(b['t'],b['parent4'],color=COL['gat'],where='post');ax[1].set_yticks([1,2,3]);ax[1].set_ylabel('SC4 parent');ax[1].set_xlabel('Time (s)')
fig.tight_layout(pad=.3);fig.savefig(DEST/'fig_v3_trace.pdf');plt.close(fig)
# tables
def cc(c,b,f,s,foc='gat'):return next(r for r in con if r['case_name']==c and r['comparison']==f'{foc}_minus_{b}' and r['metric']==f and r['scale']==s)
MM=['periodic','eo_chain','eo_star','zoh_star','dynamic_star','self_star','clac','gat_fixed','gat'];H=['Per.','EO ch.','EO st.','ETC','DET','ST','CLAC','GAT-F','GAT']
t=['\\begin{tabular}{@{}l'+'r'*9+'@{\\,}l@{}}','\\toprule','Condition & '+' & '.join(H)+' & \\multicolumn{1}{c}{GAT 95\\% CI}\\\\','\\midrule']
for c in cases:
    if c=='ALL_CONDITIONS':t.append('\\midrule')
    vals=[float(get(c,m)['mean']) for m in MM];best=min(vals[1:]);cells=[(f'\\textbf{{{v:.3f}}}' if k>=1 and abs(v-best)<1e-12 else f'{v:.3f}') for k,v in enumerate(vals)]
    g=get(c,'gat');t.append(f'{names[c]} & '+' & '.join(cells)+f' & [{float(g["ci_low"]):.3f}, {float(g["ci_high"]):.3f}]\\\\')
t+=['\\bottomrule','\\end{tabular}'];(DEST.parent/'tab_pair.tex').write_text('\n'.join(t)+'\n')
B=[('eo_star','EO star'),('dynamic_star','DET'),('self_star','ST'),('clac','CLAC')]
t=['\\begin{tabular}{@{}lrrrr@{}}','\\toprule','Condition & '+' & '.join(f'vs {l}' for _,l in B)+'\\\\','\\midrule']
for c in cases:
    if c=='ALL_CONDITIONS':t.append('\\midrule')
    t.append(f'{names[c]} & '+' & '.join('{:.1f} [{:.1f}, {:.1f}]'.format(*[float(cc(c,b,'fault_pair_rms_rad','percent')[q]) for q in ('mean','ci_low','ci_high')]) for b,_ in B)+'\\\\')
t+=['\\bottomrule','\\end{tabular}'];(DEST.parent/'tab_contrast.tex').write_text('\n'.join(t)+'\n')
lab={'periodic':'Periodic','eo_chain':'EO, chain','eo_star':'EO, star','zoh_star':'Static ETC (ZOH)','dynamic_star':'Dynamic ETC','self_star':'Self-triggered','clac':'CLAC','gat_fixed':'GAT, no re-selection','gat':'GAT'}
t=['\\begin{tabular}{@{}lrrr@{}}','\\toprule','Method & Payload (kB) & Attempts & Pair RMS (deg)\\\\','\\midrule']
for m in ['ideal']+MM:
    p=float(get('ALL_CONDITIONS',m,'state_payload_bytes')['mean'])/1e3;a=float(get('ALL_CONDITIONS',m,'attempted_packets')['mean']);e=get('ALL_CONDITIONS',m)
    t.append(f'{lab.get(m,"Ideal communication")} & {p:.1f} & {a:.0f} & {float(e["mean"]):.3f} [{float(e["ci_low"]):.3f}, {float(e["ci_high"]):.3f}]\\\\')
t+=['\\bottomrule','\\end{tabular}'];(DEST.parent/'tab_cost.tex').write_text('\n'.join(t)+'\n')
print('done')
