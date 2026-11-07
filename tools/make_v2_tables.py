"""LaTeX tables for the paper, generated from results/v2 CSVs (no hand-typed numbers)."""
from pathlib import Path
import csv,sys
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'results/v2'
dest=Path(sys.argv[1]);dest.mkdir(parents=True,exist_ok=True)
rows=list(csv.DictReader(open(OUT/'means_ci.csv')));con=list(csv.DictReader(open(OUT/'paired_contrasts_ci.csv')))
names={'healthy':'Healthy','pointing_single':'Pointing, one link','pointing_multilink':'Pointing, three links','pointing_all_links':'Pointing, six links','actuator_isolated':'Actuator only','attenuation_severe':'Severe attenuation','combined':'Combined','beam_mismatch':'Beam mismatch','network_transfer':'Network transfer','jitter_high':'35~$\\mu$rad jitter','slow_acquisition':'15~s pull-in','random_link_pointing':'Pointing, random link','random_link_outage':'Outage, random link','two_link_outage':'Outage, two links','ALL_CONDITIONS':'Mean of 14 conditions'}
cases=list(names)
def get(c,m,f='fault_pair_rms_rad'):return next(r for r in rows if r['case_name']==c and r['method']==m and r['metric']==f)
M=['ideal','periodic','eo_chain','eo_star','zoh_star','dynamic_star','self_star','clac_fixed','clac']
H=['Ideal','Per.','EO ch.','EO st.','ETC','DET','ST','CL-F','CLAC']
t=['\\begin{tabular}{@{}l'+'r'*9+'@{\\,}l@{}}','\\toprule','Condition & '+' & '.join(H)+' & \\multicolumn{1}{c}{CLAC 95\\% CI}\\\\','\\midrule']
for c in cases:
    if c=='ALL_CONDITIONS':t.append('\\midrule')
    vals=[float(get(c,m)['mean']) for m in M];best=min(vals[2:])
    cells=[]
    for k,v in enumerate(vals):
        s=f'{v:.3f}';cells.append(f'\\textbf{{{s}}}' if k>=2 and abs(v-best)<1e-12 else s)
    g=get(c,'clac');t.append(f'{names[c]} & '+' & '.join(cells)+f' & [{float(g["ci_low"]):.3f}, {float(g["ci_high"]):.3f}]\\\\')
t+=['\\bottomrule','\\end{tabular}']
(dest/'tab_pair.tex').write_text('\n'.join(t)+'\n')
def cc(c,b,f,s):return next(r for r in con if r['case_name']==c and r['comparison']==f'clac_minus_{b}' and r['metric']==f and r['scale']==s)
B=['eo_star','dynamic_star','self_star','clac_fixed']
t=['\\begin{tabular}{@{}lrrrr@{}}','\\toprule','Condition & vs EO star & vs DET & vs ST & vs CLAC-fixed\\\\','\\midrule']
for c in cases:
    if c=='ALL_CONDITIONS':t.append('\\midrule')
    cells=[]
    for b in B:
        r=cc(c,b,'fault_pair_rms_rad','percent');cells.append(f'{float(r["mean"]):.1f} [{float(r["ci_low"]):.1f}, {float(r["ci_high"]):.1f}]')
    t.append(f'{names[c]} & '+' & '.join(cells)+'\\\\')
t+=['\\bottomrule','\\end{tabular}']
(dest/'tab_contrast.tex').write_text('\n'.join(t)+'\n')
t=['\\begin{tabular}{@{}lrrr@{}}','\\toprule','Method & Payload (kB) & Attempts & Pair RMS (deg)\\\\','\\midrule']
lab={'ideal':'Ideal communication','periodic':'Periodic','eo_chain':'EO, chain','eo_star':'EO, star','zoh_star':'Static ETC (ZOH)','dynamic_star':'Dynamic ETC','self_star':'Self-triggered','clac_fixed':'CLAC, no re-selection','clac':'CLAC'}
for m in M:
    p=float(get('ALL_CONDITIONS',m,'state_payload_bytes')['mean'])/1e3;a=float(get('ALL_CONDITIONS',m,'attempted_packets')['mean']);e=get('ALL_CONDITIONS',m)
    t.append(f'{lab[m]} & {p:.1f} & {a:.0f} & {float(e["mean"]):.3f} [{float(e["ci_low"]):.3f}, {float(e["ci_high"]):.3f}]\\\\')
t+=['\\bottomrule','\\end{tabular}']
(dest/'tab_cost.tex').write_text('\n'.join(t)+'\n')
print('tables written')
