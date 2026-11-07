function c=isc_v2_method(caseName,method,seed)
% Revised-evaluation configuration for a named method. Free parameters were set on
% development seeds 11/23/47 by tuning/tune_v2.m under payload-budget matching
% (results/v2/tuning_*.csv). Values below are those frozen choices.
%   ideal         ideal communication, periodic, chain (reference only)
%   periodic      optical links, periodic exchange with pilot recovery, chain
%   eo_chain      authors' previous event + prediction scheme, chain
%   eo_star       same, static tree with every follower fed by the leader
%   zoh_star      static event trigger, zero-order hold (Tabuada-style), star
%   dynamic_star  dynamic event trigger with internal variable (Girard-style), star
%   self_star     self-triggered next-transmission time (model-based), star
%   clac_fixed    proposed certificates, no parent re-selection, chain
%   clac          proposed certified link-aware coordination
if nargin<3,seed=11;end
switch method
    case 'ideal',   c=isc_v2_config(caseName,'ideal_periodic',seed,'chain');
    case 'periodic',c=isc_v2_config(caseName,'optical_periodic',seed,'chain');
    case 'eo_chain',c=isc_v2_config(caseName,'optical_event',seed,'chain');
    case 'eo_star', c=isc_v2_config(caseName,'optical_event',seed,'star');
    case 'zoh_star',c=isc_v2_config(caseName,'optical_event_zoh',seed,'star');c.zohAngle=6e-4;
    case 'dynamic_star',c=isc_v2_config(caseName,'optical_event_dynamic',seed,'star');c.dynBase=1.5e-5;
    case 'self_star',c=isc_v2_config(caseName,'optical_self_triggered',seed,'star');c.selfAccel=2e-3;
    case 'clac_fixed',c=isc_v2_config(caseName,'optical_clac_fixed',seed,'chain');
    case 'clac',    c=isc_v2_config(caseName,'optical_clac',seed,'chain');c.clacSwitchRatio=0.8;
    otherwise,error('Unknown method');
end
c.methodName=method;
end
