function trials=run_v3_evaluation(seeds,caseIdx,outName,outDir)
% 17 conditions x 10 methods x seeds. Held-out seeds 401-420 (never used before). Needs results/v3/lock.json.
root=fileparts(mfilename('fullpath'));addpath(fullfile(root,'src'));
if nargin<4,outDir='v3';end
out=fullfile(root,'results',outDir);if ~exist(out,'dir'),mkdir(out);end
if strcmp(outName,'heldout'),assert(isfile(fullfile(out,'lock.json')),'Freeze the protocol before the held-out run');end
cases={'healthy','pointing_single','pointing_multilink','pointing_all_links','actuator_isolated',...
    'attenuation_severe','combined','beam_mismatch','network_transfer','jitter_high','slow_acquisition',...
    'random_link_pointing','random_link_outage','two_link_outage','ramp_link_pointing','intermittent_link_outage','outage_plus_actuator'};
methods={'ideal','periodic','eo_chain','eo_star','zoh_star','dynamic_star','self_star','clac','gat_fixed','gat'};
parts={};tag=strjoin(string(caseIdx),'_');
for a=caseIdx,for b=1:numel(methods),for seed=seeds
    c=isc_v3_method(cases{a},methods{b},seed);r=isc_run(c);m=r.trackingMetrics;
    row=struct2table(m);row.case_name=string(cases{a});row.method=string(methods{b});
    row.fault_start_s=c.faultStart;row.fault_end_s=c.faultEnd;row.fault_edges=string(mat2str(getfieldor(c,'faultEdges',[])));
    parts{end+1,1}=row; %#ok<AGROW>
    fprintf('V3 %s %s %s seed=%d pair=%.5g bytes=%d\n',outName,cases{a},methods{b},seed,m.fault_pair_rms_rad,m.state_payload_bytes);
end,end,end
trials=vertcat(parts{:});writetable(trials,fullfile(out,sprintf('trials_%s_%s.csv',outName,tag)));
fprintf('V3_BATCH_PASS %d trials\n',height(trials));
end
function v=getfieldor(s,f,d),if isfield(s,f),v=s.(f);else,v=d;end,end
