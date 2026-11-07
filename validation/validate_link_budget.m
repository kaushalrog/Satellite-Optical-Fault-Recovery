function T=validate_link_budget()
% Reproduce the published NASA/MIT-LL TBIRD downlink irradiance budget line by line
% with the same link-budget code that the crosslink simulator uses (isc_optics).
% Source: C. M. Schieler et al., SPIE 2023 (NASA NTRS 20230000434), Fig. 3,
%         downlink irradiance link model at 30 deg elevation.
% This validates the link-budget arithmetic (Gaussian-beam gain, pointing loss, range
% spreading), not the crosslink geometry, which has no public NASA/ISRO data.
root=fileparts(fileparts(mfilename('fullpath')));addpath(fullfile(root,'src'));
p=struct('txPower_W',0.9,'txLoss_dB',0.3,'fwhm_rad',380e-6,'pointingError_rad',50e-6,...
    'range_m',930e3,'atmLoss_dB',0.5);
b=isc_optics('budget',p);
names={'Tx optical power (dBW)';'Tx optics loss (dB)';'Tx antenna gain (dBi)';'Tx pointing loss (dB)';...
    'Range loss (dB/m^2)';'Atmospheric loss (dB)';'Rx irradiance (dB W/m^2)'};
published=[-0.5;-0.3;79.0;-0.2;-130.4;-0.5;-52.9];
model=[b.txPower_dBW;b.txLoss_dB;b.txGain_dBi;b.pointLoss_dB;b.rangeLoss_dBm2;b.atmLoss_dB;b.irradiance_dBWm2];
T=table(string(names),published,round(model,2),round(model-published,2),'VariableNames',{'item','published','model','difference_dB'});
disp(T);
tol=0.25;
assert(abs(model(end)-published(end))<=tol,'Total irradiance differs from the published budget by more than %.2f dB',tol);
assert(all(abs(model(1:6)-published(1:6))<=0.15),'A budget line item deviates from the published table');
fprintf('LINK_BUDGET_VALIDATION_PASS: total irradiance %.2f vs %.1f dB W/m^2 (difference %.2f dB)\n',model(end),published(end),model(end)-published(end));
% Calibration constants carried into the crosslink model, with provenance
cal={'beam FWHM','380 urad','measured on orbit, SPIE 2023 Sec. 3';
     'closed-loop body pointing','<10 urad RMS','ICSOS 2023 (nominal jitter used)';
     'uplink tracking accuracy','20-35 urad RMS','SPIE 2023 Sec. 2 (stress case 35 urad)';
     'pull-in time','10-30 s','SPIE 2023 Sec. 2 (stress cases 15 s)';
     'FEC threshold structure','hard threshold in dBm','SPIE 2023: about -38 dBm at 200 Gbps; modelled here by RS(88,72) PER=0.1'};
C=cell2table(cal,'VariableNames',{'quantity','value','source'});
writetable(T,fullfile(root,'results','v2','link_budget_validation.csv'));
writetable(C,fullfile(root,'results','v2','calibration_sources.csv'));
end
