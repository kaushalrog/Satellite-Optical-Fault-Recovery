function test_gat()
% (1) the tolerance guarantee holds when nothing is lost; (2) v2 held-out results still reproduce exactly;
% (3) both certificates hold in new conditions.
root=fileparts(fileparts(mfilename('fullpath')));addpath(fullfile(root,'src'));
g=struct('gat_fixed',[],'gat',[]);
for m={'gat_fixed','gat'},for sd=401:404
    c=isc_v3_method('healthy',m{1},sd);r=isc_run(c);x=r.trackingMetrics;
    g.(m{1})(end+1)=x.gat_guarantee_locked_prefault;
    assert(x.cert_violation_fraction==0 && x.cert_rate_violation_fraction==0);
end,end
% With a locked link, a fixed tree and no loss the tolerance holds (>=99%); parent switches add a short transient (>=95%)
assert(mean(g.gat_fixed)>=0.99,'tolerance guarantee (fixed tree): %.4f',mean(g.gat_fixed));
assert(mean(g.gat)>=0.95,'tolerance guarantee (re-selection): %.4f',mean(g.gat));
T=[];for f=dir(fullfile(root,'results','v2','trials_heldout_*.csv'))',x=readtable(fullfile(f.folder,f.name),'TextType','string');x.fault_edges=string(x.fault_edges);T=[T;x];end %#ok<AGROW>
chk={'random_link_outage','clac',203;'jitter_high','eo_star',207;'combined','self_star',211;'network_transfer','dynamic_star',215;'healthy','periodic',219;'two_link_outage','clac_fixed',201};
w=0;for k=1:size(chk,1)
    r=isc_run(isc_v2_method(chk{k,1},chk{k,2},chk{k,3}));m=r.trackingMetrics;
    row=T(strcmp(T.case_name,chk{k,1})&strcmp(T.method,chk{k,2})&T.seed==chk{k,3},:);
    w=max([w abs(m.fault_pair_rms_rad-row.fault_pair_rms_rad)/row.fault_pair_rms_rad abs(m.attempted_packets-row.attempted_packets)]);
end
assert(w<1e-12,'v2 results no longer reproduce (%.3g)',w);
for cs={'ramp_link_pointing','intermittent_link_outage','outage_plus_actuator'}
    for m={'clac','gat'}
        r=isc_run(isc_v3_method(cs{1},m{1},401));x=r.trackingMetrics;
        assert(x.cert_violation_fraction==0 && x.cert_rate_violation_fraction==0,'%s %s',cs{1},m{1});
    end
end
fprintf('GAT_TESTS_PASS: tolerance holds on %.1f%% (fixed) / %.1f%% (re-selection) of locked fault-free samples, v2 reproduces (worst %.2g), certificates hold in new cases\n',100*mean(g.gat_fixed),100*mean(g.gat),w);
end
