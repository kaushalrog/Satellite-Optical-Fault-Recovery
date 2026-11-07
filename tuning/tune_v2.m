function T=tune_v2(method)
% Development-seed tuning of every method's free parameter (seeds 11/23/47 ONLY).
% Rule (stated in docs/V2_METHODS.md): each baseline gets the most accurate setting
% whose mean payload does not exceed the payload of the proposed method (budget matching).
%   method: 'zoh' | 'dynamic' | 'self' | 'eo_chain' | 'eo_star' | 'clac'
root=fileparts(fileparts(mfilename('fullpath')));addpath(fullfile(root,'src'));
devSeeds=[11 23 47];
cases={'pointing_single','combined','random_link_pointing','random_link_outage','actuator_isolated'};
switch method
    case 'zoh',   mode='optical_event_zoh';tree='star';name='zohAngle';grid=1.5e-4*[1 1.5 2 3 4 6 8 12 16];
    case 'dynamic',mode='optical_event_dynamic';tree='star';name='dynBase';grid=1.5e-4*[.05 .1 .2 .35 .5 .75 1 1.5 2];
    case 'self',  mode='optical_self_triggered';tree='star';name='selfAccel';grid=2e-4*[2 4 6 8 10 12 16 24];
    case 'eo_chain',mode='optical_event';tree='chain';name='eventScale';grid=[.5 .75 1 1.5 2 3 4 6];
    case 'eo_star', mode='optical_event';tree='star';name='eventScale';grid=[.5 .75 1 1.5 2 3 4 6];
    case 'clac',  mode='optical_clac';tree='chain';name='clacSwitchRatio';grid=[.4 .6 .8 .9];
    otherwise,error('unknown method');
end
rows={};
for g=grid
    P=[];B=[];
    for cs=1:numel(cases)
        for sd=devSeeds
            c=isc_v2_config(cases{cs},mode,sd,tree);
            if strcmp(name,'eventScale'),c.eventAngle=1.5e-4*g;c.eventRate=1e-4*g;else,c.(name)=g;end
            r=isc_run(c);m=r.trackingMetrics;
            P(end+1)=m.fault_pair_rms_rad*180/pi;B(end+1)=m.state_payload_bytes; %#ok<AGROW>
        end
    end
    rows(end+1,:)={string(method),g,mean(P),mean(B)}; %#ok<AGROW>
    fprintf('TUNE %s %s=%.4g  pairRMS=%.4f deg  bytes=%.0f\n',method,name,g,mean(P),mean(B));
end
T=cell2table(rows,'VariableNames',{'method','value','pair_rms_deg','payload_bytes'});
writetable(T,fullfile(root,'results','v2',['tuning_' method '.csv']));
end
