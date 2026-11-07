function audit_trajectories(caseIdx,srcOverride,tag)
% AUDIT (read-only on src): re-run CLAC and CLAC-fixed on the frozen held-out seeds and check BOTH the
% attitude and the rate certificate with code independent of isc_tracking_metrics.
%   srcOverride: optional folder prepended to the path (used for what-if proposals); '' for frozen code.
root=fileparts(fileparts(mfilename('fullpath')));
if nargin>=2 && ~isempty(srcOverride),addpath(srcOverride);end
addpath(fullfile(root,'src'));if nargin>=2 && ~isempty(srcOverride),addpath(srcOverride);end   % override wins
if nargin<3,tag='frozen';end
cases={'healthy','pointing_single','pointing_multilink','pointing_all_links','actuator_isolated',...
    'attenuation_severe','combined','beam_mismatch','network_transfer','jitter_high','slow_acquisition',...
    'random_link_pointing','random_link_outage','two_link_outage'};
methods={'clac_fixed','clac'};rows={};
for a=caseIdx
 for b=1:2
  for seed=201:220
    c=isc_v2_method(cases{a},methods{b},seed);r=isc_run(c);K=numel(r.t);
    violA=0;violW=0;n=0;minMA=inf;minMW=inf;
    for k=1:K
        [qr,wr]=isc_reference(r.t(k),c.referencePhase);
        for i=2:4
            H=r.certH(k,i);W=r.certW(k,i);if ~isfinite(H),continue;end
            q=isc_math('exp',squeeze(r.att(k,:,i))');w=squeeze(r.rate(k,:,i))';
            qs=isc_math('mul',qr,c.offsets(:,i));ws=isc_math('rot',c.offsets(:,i))'*wr;
            chi=norm(isc_math('log',isc_math('mul',isc_math('conj',qs),q)));
            eps_=norm(w-isc_math('rot',q)'*isc_math('rot',qs)*ws);
            n=n+1;minMA=min(minMA,H-chi);minMW=min(minMW,W-eps_);
            violA=violA+(chi>H);violW=violW+(eps_>W);
        end
    end
    m=r.trackingMetrics;
    rows(end+1,:)={cases{a},methods{b},seed,n,violA,violW,minMA,minMW,m.fault_pair_rms_rad,m.attempted_packets,m.cert_violation_fraction,m.parent_switches}; %#ok<AGROW>
    fprintf('AUD %s %s %d samples=%d violA=%d violW=%d\n',cases{a},methods{b},seed,n,violA,violW);
  end
 end
end
T=cell2table(rows,'VariableNames',{'case_name','method','seed','samples','att_violations','rate_violations','min_att_margin_rad','min_rate_margin_radps','fault_pair_rms_rad','attempted_packets','cert_violation_fraction','parent_switches'});
writetable(T,fullfile(root,'audit_v2','results',sprintf('traj_%s_%s.csv',tag,strjoin(string(caseIdx),'_'))));
end
