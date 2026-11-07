% Trace data for the GAT figure (does not change any result). Seed 403: faulty link = SC1-SC4.
root=fileparts(fileparts(mfilename('fullpath')));addpath(fullfile(root,'src'));out=fullfile(root,'results','v3');
for m={'eo_star','gat'}
    c=isc_v3_method('random_link_outage',m{1},403);r=isc_run(c);
    X=[r.t r.tracking.commandError(:,4)*180/pi r.lock(:,5)];names={'t','err4_deg','lock_l3'};
    if isfield(r,'certE'),X=[X r.certE(:,4)*180/pi r.parentSel(:,4)];names=[names {'ecomm4_deg','parent4'}];end
    writetable(array2table(X,'VariableNames',names),fullfile(out,['figdata_trace_' m{1} '.csv']));
    fprintf('%s edges=%s tol=%g\n',m{1},mat2str(c.faultEdges),c.gatTol);
end
