function test_boundary()
% Regression test for the horizon-boundary defect: at age == horizon the target rate is zero, so the rate bound must be wbar.
root=fileparts(fileparts(mfilename('fullpath')));addpath(fullfile(root,'src'));
ref=isc_clac('reference');
for h=[0 0.5 3]
    b=isc_clac('bound',1e-3,5e-4,h,h,ref);assert(abs(b.Erate-ref.omegaMax)<1e-15,'rate bound at age==horizon must equal wbar');
    bl=isc_clac('bound',1e-3,5e-4,h-1e-9,h,ref);bu=isc_clac('bound',1e-3,5e-4,h+1e-9,h,ref);
    assert(abs(bl.Eatt-bu.Eatt)<1e-6,'attitude bound must be continuous at the horizon');
end
for sd=[409 417]
    r=isc_run(isc_v3_method('network_transfer','gat_fixed',sd));x=r.trackingMetrics;
    assert(x.cert_violation_fraction==0 && x.cert_rate_violation_fraction==0,'rate certificate violated after the fix (seed %d)',sd);
end
fprintf('BOUNDARY_TEST_PASS\n');
end
