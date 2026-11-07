function c=isc_v2_config(caseName,mode,seed,tree)
% Configuration for the revised (physical-optics) evaluation. Every case uses
% the physical optical model; mode selects the coordination method.
%
% Cases (all with seed-isolated exogenous randomness, as in isc_holdout_config):
%   healthy              no fault
%   pointing_single      boresight bias on one link (previous principal case)
%   pointing_multilink   independent bias vectors on all three chain links
%   pointing_all_links   bias on all six physical links
%   actuator_isolated    degraded actuator on SC2 only, optical links healthy
%   attenuation_severe   deep attenuation of link 1
%   combined             pointing + attenuation + actuator
%   beam_mismatch        true beam narrower than the model (0.9)
%   network_transfer     alternate tree, longer delay, 10% extra drop floor
%   jitter_high          pointing_multilink with 35 urad tracking jitter
%   slow_acquisition     pointing_multilink with 15 s pull-in
if nargin<3,seed=11;end
if nargin<4,tree='chain';end   % 'star': static tree with every follower fed by the leader
scen='pointing';
switch caseName
    case 'healthy',scen='healthy';
    case 'pointing_single',scen='pointing';
    case {'pointing_multilink','jitter_high','slow_acquisition'},scen='pointing_multilink';
    case 'pointing_all_links',scen='pointing_all_links';
    case 'random_link_pointing',scen='edge_pointing';
    case {'random_link_outage','two_link_outage'},scen='edge_outage';
    case 'actuator_isolated',scen='body_actuator';
    case 'attenuation_severe',scen='attenuation';
    case {'combined','beam_mismatch','network_transfer'},scen='combined';
    otherwise,error('Unknown v2 case');
end
if strcmp(caseName,'beam_mismatch'),scen='pointing';end
if strcmp(caseName,'network_transfer'),scen='pointing';end
c=isc_tracking_config(mode,scen,seed,'off');c.caseName=caseName;c.treeName=tree;
opt={};
if strcmp(caseName,'jitter_high'),opt={'trackingJitter_rad',35e-6};end
if strcmp(caseName,'slow_acquisition'),opt={'acquireTime',15};end
c=isc_physical_config(c,opt{:});
switch caseName
    case 'combined'
        c.pointingFaultScale=1.2;c.attenuationGain=.55;c.actuatorEffectiveness=[.25;.4;.3];
        c.faultStart=28;c.faultEnd=52;
    case 'attenuation_severe'
        c.attenuationGain=.08;c.faultStart=22;c.faultEnd=55;
    case 'beam_mismatch'
        c.plantDivergenceScale=.9;c.pointingFaultScale=.9;c.faultStart=20;c.faultEnd=58;
    case 'network_transfer'
        c.parent=[0 1 1 2];c.pointingFaultScale=1.1;c.delay=.2;c.jitter=.15;
        c.extraDrop=.10;
    case 'actuator_isolated'
        c.actuatorEffectiveness=[.30;.45;.35];c.faultStart=25;c.faultEnd=60;
end
% Active endpoints per method: chain, or static star, or the alternate tree of the network case
chainEnds=[1 2 7 8 11 12];
if strcmp(caseName,'network_transfer'),c.parent=[0 1 1 2];chainEnds=[1 2 3 4 9 10];end
if strcmp(tree,'star'),c.parent=[0 1 1 1];chainEnds=[1 2 3 4 5 6];end
if strcmp(mode,'optical_clac'),c.activeEndpoints=1:12;
elseif strcmp(mode,'optical_clac_fixed'),c.activeEndpoints=chainEnds(mod(chainEnds,2)==1);   % feed links only
else,c.activeEndpoints=chainEnds;end
stream=RandStream('mt19937ar','Seed',seed+100000);
base=[.012 -.008 .009 -.011;-.006 .010 -.008 .007;.008 -.005 .006 -.009];
c.initialAngles=base+.002*randn(stream,3,4);
c.initialW=1e-4*randn(stream,3,4);
c.referencePhase=2*pi*rand(stream)-pi;
c.disturbancePhase=2*pi*rand(stream,3,4);
c.disturbanceScale=.7+.6*rand(stream,3,4);
% Fault location is drawn last (so earlier cases keep their random streams) and is
% identical for every method run on the same seed.
if ismember(scen,{'edge_pointing','edge_outage'})
    nE=1;if strcmp(caseName,'two_link_outage'),nE=2;end
    c.faultEdges=randperm(stream,6,nE);
    if nE==1 && seed>=201 && seed<=299,c.faultEdges=mod(seed-201,6)+1;end   % held-out seeds: balanced over the six links
    ang=2*pi*rand(stream,1,nE);mag=.85+.25*rand(stream,1,nE);
    c.faultBias=[mag.*cos(ang);mag.*sin(ang)];c.outageGain=.08;
end
end
