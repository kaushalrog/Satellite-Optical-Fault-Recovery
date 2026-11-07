function test_legacy_regression()
% The legacy optical model must still reproduce the previously reported
% held-out numbers (results/holdout/trials.csv, seeds 101-120) to at least nine significant digits (the published run was produced on another machine; last-bit floating-point differences are expected).
root=fileparts(fileparts(mfilename('fullpath')));addpath(fullfile(root,'src'));
T=readtable(fullfile(root,'results','holdout','trials.csv'));
checks={'principal_pointing','ideal_periodic','off',101;
        'principal_pointing','optical_periodic_no_recovery','off',102;
        'principal_pointing','optical_periodic','off',103;
        'principal_pointing','optical_event','off',104;
        'principal_combined','optical_event','frozen',105;
        'alternate_tree_network','optical_event','frozen',106;
        'beam_mismatch_new','optical_event','off',107};
worst=0;
for k=1:size(checks,1)
    c=isc_holdout_config(checks{k,1},checks{k,2},checks{k,4},checks{k,3});
    assert(strcmp(c.optics,'legacy'),'legacy config expected');
    r=isc_run(c);
    row=T(strcmp(T.case_name,checks{k,1}) & strcmp(T.mode,checks{k,2}) & strcmp(T.policy,checks{k,3}) & T.seed==checks{k,4},:);
    assert(height(row)==1,'reference row not found');
    for name={'fault_pair_rms_rad','fault_tracking_rms_rad','fault_control_effort_N2m2s','attempted_packets'}
        a=r.trackingMetrics.(name{1});b=row.(name{1});
        err=abs(a-b)/max(abs(b),eps);worst=max(worst,err);
        assert(err<1e-9,'legacy mismatch: %s %s seed %d %s: %.15g vs %.15g',checks{k,1},checks{k,2},checks{k,4},name{1},a,b);
    end
end
fprintf('LEGACY_REGRESSION_PASS: %d runs, worst relative difference %.2e\n',size(checks,1),worst);
end
