function trials=run_v2_evaluation(seeds,caseIdx,outName)
% Physical-optics evaluation: 14 conditions x 9 methods x seeds. Writes one CSV per call.
%   run_v2_evaluation(201:220,1:14,'heldout')      held-out (requires results/v2/lock.json)
%   run_v2_evaluation([901 902],1:14,'validation') validation (no lock needed)
root=fileparts(mfilename('fullpath'));addpath(fullfile(root,'src'));
out=fullfile(root,'results','v2');if ~exist(out,'dir'),mkdir(out);end
if strcmp(outName,'heldout'),assert(isfile(fullfile(out,'lock.json')),'Freeze the protocol before the held-out run');end
cases={'healthy','pointing_single','pointing_multilink','pointing_all_links','actuator_isolated',...
    'attenuation_severe','combined','beam_mismatch','network_transfer','jitter_high','slow_acquisition',...
    'random_link_pointing','random_link_outage','two_link_outage'};
methods={'ideal','periodic','eo_chain','eo_star','zoh_star','dynamic_star','self_star','clac_fixed','clac'};
parts={};tag=strjoin(string(caseIdx),'_');
for a=caseIdx
    for b=1:numel(methods)
        for seed=seeds
            c=isc_v2_method(cases{a},methods{b},seed);r=isc_run(c);m=r.trackingMetrics;
            row=struct2table(m);row.case_name=string(cases{a});row.method=string(methods{b});
            row.fault_start_s=c.faultStart;row.fault_end_s=c.faultEnd;
            row.fault_edges=string(mat2str(getfieldor(c,'faultEdges',[])));
            parts{end+1,1}=row; %#ok<AGROW>
            fprintf('V2 %s %s %s seed=%d pair=%.5g bytes=%d\n',outName,cases{a},methods{b},seed,m.fault_pair_rms_rad,m.state_payload_bytes);
        end
    end
end
trials=vertcat(parts{:});
writetable(trials,fullfile(out,sprintf('trials_%s_%s.csv',outName,tag)));
fprintf('V2_BATCH_PASS %d trials\n',height(trials));
end
function v=getfieldor(s,f,d),if isfield(s,f),v=s.(f);else,v=d;end,end
