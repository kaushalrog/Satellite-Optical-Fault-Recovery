function test_v2_cases()
root=fileparts(fileparts(mfilename('fullpath')));addpath(fullfile(root,'src'));
% Isolated actuator case: no optical fault of any kind, only SC2 actuator effectiveness changes
c=isc_v2_method('actuator_isolated','eo_chain',201);f=isc_faults(40,c);
assert(all(f.bias(:)==0) && all(f.gain==1) && ~any(f.block),'isolated actuator case must not touch optics');
assert(any(f.eta(:,2)<1) && all(f.eta(:,[1 3 4])==1,'all'),'only SC2 actuator may degrade');
% Multi-link: three different bias vectors on the three chain links, none elsewhere
c=isc_v2_method('pointing_multilink','eo_chain',201);f=isc_faults(40,c);
v=[f.bias(:,1) f.bias(:,7) f.bias(:,11)];assert(rank(v)==2 && size(unique(round(v',9),'rows'),1)==3);
assert(isequal(f.bias(:,1),f.bias(:,2)) && all(all(f.bias(:,[3 4 5 6 9 10])==0)));
% All-link: all six links biased
c=isc_v2_method('pointing_all_links','eo_chain',201);f=isc_faults(40,c);
assert(all(vecnorm(f.bias(:,1:2:11))>0.5*c.divergence));
% Random link: balanced over six links on held-out seeds and identical across methods
E=zeros(1,20);for k=1:20,E(k)=isc_v2_method('random_link_outage','clac',200+k).faultEdges;end
assert(all(histcounts(E,0.5:1:6.5)>=3),'held-out link assignment must cover all six links');
assert(isequal(isc_v2_method('random_link_outage','clac',205).faultEdges,isc_v2_method('random_link_outage','eo_star',205).faultEdges));
% Every case and method runs; no queue overflow; unit quaternions
cases={'healthy','pointing_single','pointing_multilink','pointing_all_links','actuator_isolated','attenuation_severe','combined','beam_mismatch','network_transfer','jitter_high','slow_acquisition','random_link_pointing','random_link_outage','two_link_outage'};
methods={'ideal','periodic','eo_chain','eo_star','zoh_star','dynamic_star','self_star','clac_fixed','clac'};
for a=1:numel(cases)
    for b=1:numel(methods)
        r=isc_run(isc_v2_method(cases{a},methods{b},301));m=r.trackingMetrics;
        assert(m.queue_overflows==0 && m.quaternion_norm_error<1e-12,'%s/%s',cases{a},methods{b});
        assert(all(isfinite([m.fault_pair_rms_rad m.state_payload_bytes])));
    end
end
% Legacy optics remain selectable and untouched
assert(strcmp(isc_holdout_config('principal_pointing','optical_event',101).optics,'legacy'));
fprintf('V2_CASE_TESTS_PASS: %d cases x %d methods\n',numel(cases),numel(methods));
end
