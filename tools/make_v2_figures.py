"""Paper figures from results/v2 CSVs."""
from pathlib import Path
import csv,sys
import numpy as np
import matplotlib;matplotlib.use('Agg')
import matplotlib.pyplot as plt
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'results/v2'
DEST=Path(sys.argv[1]) if len(sys.argv)>1 else OUT/'figures';DEST.mkdir(parents=True,exist_ok=True)
plt.rcParams.update({'font.size':7,'font.family':'serif','axes.linewidth':.6,'lines.linewidth':1.0,'pdf.fonttype':42})
COL={'periodic':'#999999','eo_chain':'#7a5195','eo_star':'#0072b2','zoh_star':'#e69f00','dynamic_star':'#009e73','self_star':'#cc79a7','clac':'#d55e00','clac_fixed':'#56b4e9'}
LAB={'periodic':'Periodic','eo_chain':'EO chain','eo_star':'EO star','zoh_star':'Static ETC','dynamic_star':'Dynamic ETC','self_star':'Self-triggered','clac':'CLAC','clac_fixed':'CLAC fixed'}
def num(path):
    return np.genfromtxt(path,delimiter=',',names=True)
# --- receiver model
d=num(OUT/'figdata_receiver.csv');nom=list(csv.DictReader(open(OUT/'figdata_nominal.csv')))[0]
fig,ax=plt.subplots(figsize=(3.4,2.3))
ax.loglog(d['power_uW'],np.maximum(d['ber'],1e-18),color='#0072b2',label='Raw bit error rate')
ax.loglog(d['power_uW'],np.maximum(d['packet_error'],1e-18),color='#d55e00',label='Packet error after RS(88,72)')
ax.axhline(.1,color='k',lw=.5,ls=':');ax.axvline(float(nom['threshold_uW']),color='k',lw=.6,ls='--')
ax.text(float(nom['threshold_uW'])*1.05,1e-14,'derived\nthreshold',fontsize=6)
ax.axvline(float(nom['nominal_uW']),color='#009e73',lw=.6,ls='--');ax.text(float(nom['nominal_uW'])*1.05,1e-6,'nominal\n(+7.1 dB)',fontsize=6)
ax.set_ylim(1e-16,2);ax.set_xlabel('Average received power ($\\mu$W)');ax.set_ylabel('Error probability');ax.legend(frameon=False,fontsize=6,loc='lower left')
fig.tight_layout(pad=.3);fig.savefig(DEST/'fig_v2_receiver.pdf');plt.close(fig)
# --- per-condition pair RMS
rows=list(csv.DictReader(open(OUT/'means_ci.csv')))
cases=list(dict.fromkeys(r['case_name'] for r in rows));methods=['periodic','eo_chain','eo_star','dynamic_star','self_star','clac']
def get(c,m):
    r=next(r for r in rows if r['case_name']==c and r['method']==m and r['metric']=='fault_pair_rms_rad')
    return float(r['mean']),float(r['ci_low']),float(r['ci_high'])
names={'healthy':'Healthy','pointing_single':'Pointing, 1 link','pointing_multilink':'Pointing, 3 links','pointing_all_links':'Pointing, 6 links','actuator_isolated':'Actuator only','attenuation_severe':'Severe attenuation','combined':'Combined','beam_mismatch':'Beam mismatch','network_transfer':'Network transfer','jitter_high':'35 $\\mu$rad jitter','slow_acquisition':'15 s pull-in','random_link_pointing':'Pointing, random link','random_link_outage':'Outage, random link','two_link_outage':'Outage, two links','ALL_CONDITIONS':'All conditions'}
fig,ax=plt.subplots(figsize=(7.1,2.9))
w=.8/len(methods);x=np.arange(len(cases))
for k,m in enumerate(methods):
    v=np.array([get(c,m) for c in cases])
    ax.bar(x+(k-len(methods)/2+.5)*w,v[:,0],w,yerr=[v[:,0]-v[:,1],v[:,2]-v[:,0]],color=COL[m],label=LAB[m],error_kw=dict(lw=.5,capsize=.8))
ax.set_xticks(x);ax.set_xticklabels([names[c] for c in cases],rotation=35,ha='right');ax.set_ylabel('Fault-window pair RMS (deg)')
ax.legend(ncol=6,frameon=False,loc='upper center',bbox_to_anchor=(.5,1.16),fontsize=6.5);fig.tight_layout(pad=.3)
fig.savefig(DEST/'fig_v2_pair.pdf');plt.close(fig)
# --- trade-off
fig,ax=plt.subplots(figsize=(3.4,2.4))
for m in ['periodic','eo_chain','eo_star','zoh_star','dynamic_star','self_star','clac_fixed','clac']:
    e=next(r for r in rows if r['case_name']=='ALL_CONDITIONS' and r['method']==m and r['metric']=='fault_pair_rms_rad')
    b=next(r for r in rows if r['case_name']=='ALL_CONDITIONS' and r['method']==m and r['metric']=='state_payload_bytes')
    ax.errorbar(float(b['mean'])/1e3,float(e['mean']),yerr=[[float(e['mean'])-float(e['ci_low'])],[float(e['ci_high'])-float(e['mean'])]],fmt='o',ms=4,color=COL[m],elinewidth=.6,capsize=1)
    ax.annotate(LAB[m],(float(b['mean'])/1e3,float(e['mean'])),xytext=(3,3),textcoords='offset points',fontsize=6)
ax.set_xlabel('Mean payload per run (kB)');ax.set_ylabel('Pair RMS, mean of 14 conditions (deg)');ax.set_xlim(40,155)
fig.tight_layout(pad=.3);fig.savefig(DEST/'fig_v2_tradeoff.pdf');plt.close(fig)
# --- trace
a=num(OUT/'figdata_trace_eo_star.csv');b=num(OUT/'figdata_trace_clac.csv')
fig,ax=plt.subplots(2,1,figsize=(3.4,3.5),sharex=True,gridspec_kw=dict(height_ratios=[3,1.1]))
ax[0].axvspan(25,60,color='#eeeeee',lw=0);ax[0].plot(a['t'],a['err4_deg'],color=COL['eo_star'],label='EO star, actual')
ax[0].plot(b['t'],b['err4_deg'],color=COL['clac'],label='CLAC, actual')
bd=np.where(np.isfinite(b['bound4_deg']),b['bound4_deg'],np.nan);ax[0].plot(b['t'],bd,color='k',lw=.7,ls='--',label='CLAC certified bound')
ax[0].set_yscale('log');ax[0].set_ylim(1e-2,5e1);ax[0].set_ylabel('SC4 error (deg)');ax[0].legend(frameon=False,fontsize=6,loc='lower right')
ax[1].axvspan(25,60,color='#eeeeee',lw=0);ax[1].step(b['t'],b['parent4'],color=COL['clac'],where='post');ax[1].set_yticks([1,2,3]);ax[1].set_ylabel('SC4 parent');ax[1].set_xlabel('Time (s)')
fig.tight_layout(pad=.3);fig.savefig(DEST/'fig_v2_trace.pdf');plt.close(fig)
print('figures written to',DEST)
