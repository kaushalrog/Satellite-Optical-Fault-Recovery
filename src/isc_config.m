function c=isc_config(mode,scenario,seed)
% Nominal design and experiment settings. SI units throughout.
if nargin<1, mode='optical_event'; end
if nargin<2, scenario='pointing'; end
if nargin<3, seed=11; end
c.mode=mode; c.scenario=scenario; c.seed=seed;
c.dt=0.05; c.T=90; c.N=4; c.faultStart=25; c.faultEnd=60;
c.positions=[0 1000 1000 0;0 0 1000 1000;0 0 0 0];
c.edges=nchoosek(1:4,2); c.M=12;
c.sender=zeros(1,12); c.receiver=c.sender;
for e=1:6
    c.sender(2*e-1:2*e)=c.edges(e,:);
    c.receiver(2*e-1:2*e)=fliplr(c.edges(e,:));
end
c.J=diag([0.030 0.025 0.020]); c.umax=0.002;
c.kp=0.0015; c.kd=0.010; c.coupling=0.65;
c.smc=2e-6; c.surfaceGain=0.18; c.boundary=3e-4;
c.observerGain=2.0;
c.divergence=300e-6; c.P0=1e-6; c.sensitivity=0.20e-6;
c.optics='legacy'; c.fitErrMax=0.06;
% Hidden plant perturbations for recovery stress tests. These are never
% passed to the optical estimator or attitude feedback controller.
c.plantDivergenceScale=1; c.pointingFaultScale=1;
c.gimbalTau=0.12; c.gimbalLimit=0.10; c.gimbalRate=0.035;
c.powerNoise=0.008; c.probeAmplitude=0.16*c.divergence;
c.probeDwell=0.4; c.fitWindow=2.0; c.fitSamples=round(c.fitWindow/c.dt);
c.decisionSteps=round(0.2/c.dt); c.maxCorrection=1.5*c.divergence;
c.delay=0.10; c.jitter=0.10; c.randomDrop=0.02;
c.period=0.20; c.eventMin=0.10; c.eventMax=0.80;
c.eventAngle=1.5e-4; c.eventRate=1e-4; c.staleLimit=1.5;
% Modes added for the comparison study (see docs/V2_METHODS.md):
%   optical_event_zoh      static event trigger, zero-order-hold receiver (Tabuada-style)
%   optical_event_dynamic  dynamic event trigger, zero-order hold (Girard / Xie-style)
%   optical_self_triggered self-triggered next-transmission time, with prediction
%   optical_clac           certified, link-aware coordination (proposed)
%   optical_clac_fixed     proposed method without parent re-selection (ablation)
legacyModes={'ideal_periodic','optical_periodic_no_recovery','optical_periodic','optical_event','optical_event_no_prediction'};
newModes={'optical_event_zoh','optical_event_dynamic','optical_self_triggered','optical_clac','optical_clac_fixed'};
assert(ismember(mode,[legacyModes newModes]),'Unknown mode');
c.ideal=strcmp(mode,'ideal_periodic');
c.recovery=ismember(mode,[{'optical_periodic','optical_event','optical_event_no_prediction'} newModes]);
c.event=ismember(mode,{'optical_event','optical_event_no_prediction','optical_event_zoh','optical_event_dynamic','optical_clac','optical_clac_fixed'});
c.predict=~ismember(mode,{'optical_event_no_prediction','optical_event_zoh'});
c.trigger='static';
if strcmp(mode,'optical_event_zoh'),c.trigger='zoh';end
if strcmp(mode,'optical_event_dynamic'),c.trigger='dynamic';end
if strcmp(mode,'optical_self_triggered'),c.trigger='self';end
c.clac=ismember(mode,{'optical_clac','optical_clac_fixed'});
% Parameters of the added methods (tuned on development seeds only; see isc_v2_config)
c.zohAngle=1.5e-4; c.dynBase=1.5e-4; c.dynLambda=1.0; c.dynTheta=1.0; c.dynSigma=1.0; c.selfAccel=2e-4;
c.clacRef=isc_clac('reference'); c.clacHorizonMin=0.0; c.clacHorizonMax=3.0;
c.clacSwitchRatio=0.6; c.clacDwell=2.0; c.clacStandbyPeriod=3.0; c.clacReportPeriod=1.0; c.clacRetryGap=1.6;
c.clacReselect=strcmp(mode,'optical_clac');
assert(ismember(scenario,{'healthy','pointing','body_actuator','attenuation','blockage','combined'}),'Unknown scenario');
end
