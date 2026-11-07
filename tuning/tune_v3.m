function T=tune_v3(method)
% Development-seed sweep of the tolerance (and overhead periods) for GAT. Seeds 11/23/47 only.
root=fileparts(fileparts(mfilename('fullpath')));addpath(fullfile(root,'src'));
cases={'pointing_single','combined','random_link_pointing','random_link_outage','actuator_isolated'};
tols=[0.1 0.25 0.5 1 2 4]*1e-3;
if strcmp(method,'gat'),ov=[3 1;6 2];else,ov=[3 1];end
rows={};
for o=1:size(ov,1),for tol=tols
    P=[];B=[];G=[];
    for cs=1:numel(cases),for sd=[11 23 47]
        c=isc_v3_method(cases{cs},method,sd);c.gatTol=tol;c.clacStandbyPeriod=ov(o,1);c.clacReportPeriod=ov(o,2);
        r=isc_run(c);m=r.trackingMetrics;E=r.certE(:,2:4);ok=isfinite(E);
        P(end+1)=m.fault_pair_rms_rad*180/pi;B(end+1)=m.state_payload_bytes;G(end+1)=mean(E(ok)<=tol*(1+1e-9)); %#ok<AGROW>
    end,end
    rows(end+1,:)={string(method),tol,ov(o,1),ov(o,2),mean(P),mean(B),mean(G)}; %#ok<AGROW>
    fprintf('TUNE %s tol=%.0e standby=%g report=%g pair=%.4f bytes=%.0f guaranteeFrac=%.3f\n',method,tol,ov(o,1),ov(o,2),mean(P),mean(B),mean(G));
end,end
T=cell2table(rows,'VariableNames',{'method','tol_rad','standby_s','report_s','pair_rms_deg','payload_bytes','guarantee_fraction'});
writetable(T,fullfile(root,'results','v3',['tuning_' method '.csv']));
end
