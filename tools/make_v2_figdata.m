% Data for the paper's trace and receiver-model figures (does not change any evaluation result).
root=fileparts(fileparts(mfilename('fullpath')));addpath(fullfile(root,'src'));
out=fullfile(root,'results','v2');
% receiver curves
r=isc_optics('receiver',struct());P=logspace(-8,-5.5,200)';
T=table(P*1e6,isc_optics('ber',P,r),isc_optics('per',P,r),'VariableNames',{'power_uW','ber','packet_error'});
writetable(T,fullfile(out,'figdata_receiver.csv'));
c=isc_physical_config(isc_tracking_config('optical_event','healthy',11,'off'));
writetable(table(c.sensitivity*1e6,c.P0*1e6,10*log10(c.P0/c.sensitivity),c.divergence*1e6,'VariableNames',{'threshold_uW','nominal_uW','margin_dB','alpha_urad'}),fullfile(out,'figdata_nominal.csv'));
% traces: seed 203 -> faulty link 3 (SC1-SC4), outage
for m={'eo_star','clac'}
    c=isc_v2_method('random_link_outage',m{1},203);r=isc_run(c);
    K=numel(r.t);X=[r.t];names={'t'};
    for i=1:4,X=[X r.tracking.commandError(:,i)*180/pi];names{end+1}=sprintf('err%d_deg',i);end %#ok<AGROW>
    if isfield(r,'certH'),for i=2:4,X=[X r.certH(:,i)*180/pi];names{end+1}=sprintf('bound%d_deg',i);end;X=[X r.parentSel(:,2:4)];names=[names {'parent2','parent3','parent4'}];end %#ok<AGROW>
    X=[X r.lock(:,5:6)];names=[names {'lock_l3a','lock_l3b'}];
    writetable(array2table(X,'VariableNames',names),fullfile(out,['figdata_trace_' m{1} '.csv']));
    fprintf('trace %s faultEdges=%s window %g-%g\n',m{1},mat2str(c.faultEdges),c.faultStart,c.faultEnd);
end
