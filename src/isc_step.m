function [s,z]=isc_step(s,t,k,c)
% One causal discrete step. All random draws are fixed per step across modes.
powerNoise=randn(1,c.M); dropDraw=rand(1,c.M); delayDraw=rand(1,c.M);
phys=isfield(c,'optics') && strcmp(c.optics,'physical');
% Extra draws exist only in the physical model, so legacy streams are untouched.
if phys,jitterDraw=randn(2,c.M);encoderDraw=randn(2,c.M);end
f=isc_faults(t,c); power=zeros(1,c.M); x=zeros(2,c.M);
gimbalBefore=s.gimbal; observedPower=zeros(1,c.M);
tracking=isfield(c,'task') && strcmp(c.task,'leader_tracking');
manager=zeros(1,c.M);severity=zeros(1,c.M);feasible=-ones(1,c.M);
bestPower=nan(1,c.M);predictionHorizon=c.staleLimit*ones(1,4);
plantAlpha=c.divergence;
if isfield(c,'plantDivergenceScale'),plantAlpha=plantAlpha*c.plantDivergenceScale;end
dirs=[1 0 -1 0;0 1 0 -1];
phase=mod(floor(t/c.probeDwell),4)+1;
nominal=struct('samples',c.fitSamples,'divergence',c.divergence,...
    'maxCorrection',c.maxCorrection,'threshold',c.sensitivity/c.P0,'fitErrMax',c.fitErrMax);
for a=1:c.M
    target=isc_target(s.q(:,c.sender(a)),c,a);
    x(:,a)=s.gimbal(:,a)-target;
    distance=norm(c.positions(:,c.sender(a))-c.positions(:,c.receiver(a)));
    p0=c.P0*(1000/distance)^2;
    jit=[0;0];if phys,jit=c.trackingJitter_rad*jitterDraw(:,a);end
    physical=f.gain(a)*exp(-2*sum((x(:,a)+f.bias(:,a)+jit).^2)/plantAlpha^2)*~f.block(a);
    power(a)=p0*physical;
    observed=max(0,physical*(1+c.powerNoise*powerNoise(a)));
    observedPower(a)=observed*p0;
    probe=[0;0];
    if c.recovery
        d=struct('hindex',s.hindex(a),'hx',s.hx(:,:,a),'hp',s.hp(:,a)',...
            'hcount',s.hcount(a),'correction',s.correction(:,a),'offset',s.offset(:,a),...
            'gain',s.gain(a),'valid',s.valid(a),'mismatch',s.mismatch(a),'label',s.label(a));
        xMeasured=x(:,a);if phys,xMeasured=xMeasured+c.encoderNoise_rad*encoderDraw(:,a);end
        o=struct('x',xMeasured,'power',observed,'decision',mod(k-1,c.decisionSteps)==0);
        nominal.threshold=c.sensitivity/p0;
        [d,s.correction(:,a)]=isc_diagnose(o,d,nominal);
        s.hindex(a)=d.hindex;s.hx(:,:,a)=d.hx;s.hp(:,a)=d.hp';s.hcount(a)=d.hcount;
        s.offset(:,a)=d.offset;s.gain(a)=d.gain;s.valid(a)=d.valid;
        s.mismatch(a)=d.mismatch;s.label(a)=d.label;
        probe=c.probeAmplitude*dirs(:,phase);
    end
    if tracking
        limits=struct('divergence',c.divergence,'maxCorrection',c.maxCorrection,'threshold',c.sensitivity);
        assessment=isc_link_management(observedPower(a),s.offset(:,a),s.gain(a),s.valid(a),p0,limits);
        manager(a)=assessment.state;severity(a)=assessment.severity;
        feasible(a)=assessment.feasible;bestPower(a)=assessment.bestPower;
    end
    command=min(max(target+s.correction(:,a)+probe,-c.gimbalLimit),c.gimbalLimit);
    if phys
        % Two cascaded exponential lags (unconditionally stable at any dt)
        % followed by the terminal rate limit.
        s.gimbalV(:,a)=s.gimbalV(:,a)+(1-exp(-c.dt/c.gimbalTau1))*(command-s.gimbalV(:,a));
        step=(1-exp(-c.dt/c.gimbalTau2))*(s.gimbalV(:,a)-s.gimbal(:,a));
        s.gimbal(:,a)=s.gimbal(:,a)+min(max(step,-c.gimbalRate*c.dt),c.gimbalRate*c.dt);
    else
        velocity=min(max((command-s.gimbal(:,a))/c.gimbalTau,-c.gimbalRate),c.gimbalRate);
        s.gimbal(:,a)=s.gimbal(:,a)+c.dt*velocity;
    end
end
lossProb=c.randomDrop*ones(1,c.M);
if phys
    % Tracking/lock state machine per terminal (hysteresis plus acquisition
    % dwell), driven by the observed (noisy) pilot power.
    lock=s.lock;
    for a=1:c.M
        pw=observedPower(a);
        if s.lock(a)
            if pw<c.lockLossPower,s.lossTimer(a)=s.lossTimer(a)+c.dt;else,s.lossTimer(a)=0;end
            if s.lossTimer(a)>=c.lockLossTime-1e-9,s.lock(a)=0;s.acqTimer(a)=0;end
        else
            if pw>=c.acquirePower,s.acqTimer(a)=s.acqTimer(a)+c.dt;else,s.acqTimer(a)=0;end
            if s.acqTimer(a)>=c.acquireTime-1e-9,s.lock(a)=1;s.lossTimer(a)=0;end
        end
    end
    lock=s.lock;
    for e=1:6,lock(2*e-1:2*e)=all(s.lock(2*e-1:2*e));end   % both ends must track
    up=lock & power>=c.sensitivity;                       % reported availability
    sendGate=logical(lock);
    lossProb=isc_optics('per',power,c.receiverModel);     % FEC packet error from BER
    if isfield(c,'extraDrop'),lossProb=1-(1-lossProb)*(1-c.extraDrop);end   % additional network loss floor
else
    up=power>=c.sensitivity;
    % A bidirectional optical session needs both terminal ends acquired.
    for e=1:6,up(2*e-1:2*e)=all(up(2*e-1:2*e));end
    sendGate=up;
end
if c.ideal,up(:)=true;sendGate(:)=true;end
if tracking && c.blackout,up(:)=false;sendGate(:)=false;end
lostNow=(~c.ideal) & (dropDraw<lossProb);
% Deliver queued packets before evaluating current control. Payloads are
% immutable copies captured at transmission; no live-neighbor state access.
newDelivered=zeros(1,4); newAttempts=zeros(1,4); overflow=0;
for a=1:c.M
    count=s.queueCount(a); keep=true(1,count);
    for h=1:count
        packet=s.queue(:,h,a);
        if packet(1)<=t+1e-10
            keep(h)=false; j=c.sender(a); i=c.receiver(a);
            if sendGate(a) && packet(2)>s.stamp(j,i)
                if tracking && s.stamp(j,i)>=0
                    oldR=isc_math('rot',s.cachedQ(:,j,i));newR=isc_math('rot',packet(3:6));
                    s.rateChange(j,i)=norm(packet(7:9)-newR'*oldR*s.cachedW(:,j,i))/(packet(2)-s.stamp(j,i));
                end
                s.cachedQ(:,j,i)=packet(3:6);s.cachedW(:,j,i)=packet(7:9);
                s.stamp(j,i)=packet(2);newDelivered(j)=newDelivered(j)+1;
                s.cachedBoundH(j,i)=packet(12);s.cachedBoundW(j,i)=packet(13);s.cachedParentId(j,i)=packet(14);
            end
        end
    end
    remain=s.queue(:,find(keep),a); s.queue(:,:,a)=0;
    s.queue(:,1:size(remain,2),a)=remain;s.queueCount(a)=size(remain,2);
end
% Predictive event scheduling: compare current own state with the trajectory
% represented by its last broadcast. Maximum silence enforces retries.
if tracking && c.clac,s=isc_clac('update',s,t,c);end
if tracking
    retryGap=c.eventMax*ones(1,c.M);
    if strcmp(c.policy,'frozen')
        policyLimits=struct('eventMax',c.eventMax,'infeasibleGap',c.infeasibleGap,...
            'staleLimit',c.staleLimit,'managedHorizon',c.managedHorizon,'divergence',c.divergence);
        for a=c.activeEndpoints
            i=c.sender(a);j=c.receiver(a);
            distance=norm(c.positions(:,i)-c.positions(:,j));p0=c.P0*(1000/distance)^2;
            age=max(0,t-s.stamp(j,i));
            policy=isc_frozen_policy(manager(a),s.valid(a),observedPower(a)/p0,...
                norm(s.offset(:,a)),age,s.rateChange(j,i),policyLimits);
            retryGap(a)=policy.retryGap;
            if i>1 && j==c.parent(i),predictionHorizon(i)=policy.horizon;end
        end
    end
    [s,newAttempts]=isc_tracking_schedule(s,t,c,manager,lostNow,delayDraw,sendGate,retryGap);
else
for i=1:4
    elapsed=t-s.lastSend(i); doSend=elapsed>=c.period-1e-10;
    if c.event
        represented=isc_math('mul',s.sentQ(:,i),isc_math('exp',s.sentW(:,i)*min(elapsed,c.eventMax)));
        innovation=norm(isc_math('log',isc_math('mul',isc_math('conj',represented),s.q(:,i))));
        doSend=elapsed>=c.eventMin-1e-10 && (innovation>c.eventAngle ||...
            norm(s.w(:,i)-s.sentW(:,i))>c.eventRate || elapsed>=c.eventMax-1e-10);
    end
    if ~doSend,continue;end
    s.lastSend(i)=t;s.sentQ(:,i)=s.q(:,i);s.sentW(:,i)=s.w(:,i);
    for a=find(c.sender==i)
        newAttempts(i)=newAttempts(i)+1;
        if ~sendGate(a) || lostNow(a),continue;end
        count=s.queueCount(a)+1;
        if count>size(s.queue,2),overflow=overflow+1;continue;end
        delay=c.delay+c.jitter*delayDraw(a); if c.ideal,delay=0;end
        % At least one sample of causality; no same-step algebraic exchange.
        arrival=t+max(c.dt,ceil(delay/c.dt)*c.dt);
        s.queue(:,count,a)=[arrival;t;s.q(:,i);s.w(:,i);i;c.receiver(a);0;0;0];
        s.queueCount(a)=count;
    end
end
end
s.attempts=s.attempts+newAttempts;s.deliveries=s.deliveries+newDelivered;
% Explicit whitelist keeps scenario truth out of feedback control.
n=struct('J',c.J,'dt',c.dt,'umax',c.umax,'kp',c.kp,'kd',c.kd,...
    'coupling',c.coupling,'smc',c.smc,'surfaceGain',c.surfaceGain,...
    'boundary',c.boundary,'observerGain',c.observerGain,...
    'predict',c.predict,'staleLimit',c.staleLimit);
if tracking
    if c.managePrediction
        for i=2:4
            local=find(c.sender==i & c.receiver==c.parent(i),1);
            if ismember(manager(local),[1 2]),predictionHorizon(i)=c.managedHorizon;end
        end
    end
    n.task=c.task;n.parent=c.parent;n.offsets=c.offsets;n.holdQ=s.holdQ;
    if c.clac,n.parent=s.parent;predictionHorizon=s.horizon;end
    n.predictionHorizon=predictionHorizon;n.referencePhase=c.referencePhase;
end
[u,s.disturbance,age]=isc_controller(s.q,s.w,s.cachedQ,s.cachedW,s.stamp,...
    s.disturbance,s.previousW,s.torque,t,n);
s.previousW=s.w;s.torque=u;
att=zeros(3,4);for i=1:4,att(:,i)=isc_math('log',s.q(:,i));end
z.att=att;z.rate=s.w;z.torque=u;z.power=power;z.up=up;
z.age=age;z.label=s.label;z.correction=s.correction;
z.attempts=newAttempts;z.deliveries=newDelivered;z.overflow=overflow;
z.qnorm=sqrt(sum(s.q.^2,1));z.residual=x;
% Audit-only truth/actuator logs. No feedback function reads these outputs.
z.gimbal=gimbalBefore;z.injectedBias=f.bias;z.opticalGain=f.gain;
z.blocked=double(f.block);z.estimatedOffset=s.offset;z.fitValid=s.valid;
z.observedPower=observedPower;
z.lock=double(sendGate);z.packetErrorProb=lossProb;
if tracking
    z.manager=manager;z.severity=severity;z.feasible=feasible;
    z.bestPower=bestPower;z.predictionHorizon=predictionHorizon;
    z.certH=s.Hnode;z.certW=s.Wnode;z.certE=s.Enode;z.parentSel=s.parent;
end
% Nonlinear rigid-body plant, midpoint integration for angular velocity.
for i=1:4
    disturbance=2e-6*[sin(0.17*t+i);cos(0.13*t+2*i);sin(0.11*t-i)];
    if isfield(c,'disturbancePhase')
        disturbance=2e-6*c.disturbanceScale(:,i).*sin([.17;.13;.11]*t+c.disturbancePhase(:,i));
    end
    actual=f.eta(:,i).*u(:,i)+disturbance;
    w=s.w(:,i); a1=c.J\(actual-cross(w,c.J*w));wm=w+0.5*c.dt*a1;
    a2=c.J\(actual-cross(wm,c.J*wm));
    s.q(:,i)=isc_math('mul',s.q(:,i),isc_math('exp',wm*c.dt));
    s.q(:,i)=s.q(:,i)/norm(s.q(:,i));s.w(:,i)=w+c.dt*a2;
end
end
