function test_certificate()
root=fileparts(fileparts(mfilename('fullpath')));addpath(fullfile(root,'src'));
ref=isc_clac('reference');
% 1) reference-class constants must dominate the command generator for any phase
worstW=0;worstA=0;t=0:0.01:200;
for ph=linspace(-pi,pi,25)
    W=zeros(numel(t),3);
    for k=1:numel(t),[~,w]=isc_reference(t(k),ph);W(k,:)=w';end
    worstW=max(worstW,max(vecnorm(W,2,2)));
    worstA=max(worstA,max(vecnorm(diff(W)/0.01,2,2)));
end
fprintf('reference constants: |w|max=%.4g (bound %.4g), |a|max=%.4g (bound %.4g)\n',worstW,ref.omegaMax,worstA,ref.alphaMax);
assert(worstW<=ref.omegaMax && worstA<=ref.alphaMax,'reference-class constants violated');
% 2) bound is monotone in age and in the incoming bounds
c=struct('clacHorizonMin',0,'clacHorizonMax',3);
a=0:0.1:6;E=zeros(size(a));for k=1:numel(a),E(k)=isc_clac('bound',1e-3,5e-4,a(k),isc_clac('horizon',5e-4,ref,c),ref).Eatt;end
assert(all(diff(E)>=-1e-15),'bound must be non-decreasing with age');
assert(isc_clac('bound',2e-3,5e-4,1,1,ref).Eatt>=isc_clac('bound',1e-3,5e-4,1,1,ref).Eatt);
% 3) certificate soundness in closed loop: actual error never exceeds the carried bound
cases={'healthy','pointing_all_links','attenuation_severe','combined','random_link_outage','two_link_outage','network_transfer','jitter_high'};
worst=0;n=0;
for k=1:numel(cases)
    for seed=[11 901]
        c=isc_v2_method(cases{k},'clac',seed);r=isc_run(c);m=r.trackingMetrics;
        assert(m.cert_violation_fraction==0,'certificate violated: %s seed %d (%.4g)',cases{k},seed,m.cert_violation_fraction);
        worst=max(worst,m.cert_tightness_median);n=n+1;
    end
end
fprintf('CERTIFICATE_TESTS_PASS: 0 violations in %d closed-loop runs (median actual/bound up to %.2f)\n',n,worst);
end
