function c=isc_v3_method(caseName,method,seed)
% Methods of the guaranteed-accuracy-triggering study. Existing methods keep their frozen v2 settings.
%   gat_fixed  tolerance-triggered sending on a static leader-fed star, no re-selection
%   gat        tolerance-triggered sending + certified parent re-selection
switch method
    case 'gat_fixed',c=isc_v2_config(caseName,'optical_gat_fixed',seed,'star');c.gatTol=1e-3;
    case 'gat',      c=isc_v2_config(caseName,'optical_gat',seed,'chain');c.clacSwitchRatio=0.8;c.gatTol=1e-3;c.clacStandbyPeriod=6;c.clacReportPeriod=2;
    otherwise,       c=isc_v2_method(caseName,method,seed);
end
c.methodName=method;
end
