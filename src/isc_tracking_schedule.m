function [s,attempts]=isc_tracking_schedule(s,t,c,manager,lostNow,delayDraw,gate,retryGap)
% Transmission scheduling for the leader-tracking task. Trigger families:
%   'static'   event trigger on the error of the rate-extrapolated broadcast (EO)
%   'zoh'      static event trigger against the held (zero-order) broadcast
%   'dynamic'  dynamic event trigger with internal variable (Girard-style)
%   'self'     self-triggered: next time computed at each transmission
%   CLAC       tree links event-triggered, standby links heartbeat, reports upstream
attempts=zeros(1,4);
for a=c.activeEndpoints
    i=c.sender(a);elapsed=t-s.lastSendEdge(a);gap=c.eventMax;
    if c.manageSchedule
        if ismember(manager(a),[1 2]),gap=c.managedGap;
        elseif manager(a)==3,gap=c.infeasibleGap;end
    end
    if strcmp(c.policy,'frozen'),gap=retryGap(a);end
    send=elapsed>=c.period-1e-10;
    if c.clac
        send=clacDecision(s,t,c,a,gate,elapsed);
    elseif strcmp(c.trigger,'self')
        send=t>=s.nextSend(a)-1e-10;
    elseif c.event
        represented=isc_math('mul',s.sentQEdge(:,a),isc_math('exp',s.sentWEdge(:,a)*min(elapsed,gap)));
        innovation=norm(isc_math('log',isc_math('mul',isc_math('conj',represented),s.q(:,i))));
        if strcmp(c.trigger,'zoh')
            innovation=norm(isc_math('log',isc_math('mul',isc_math('conj',s.sentQEdge(:,a)),s.q(:,i))));
            send=elapsed>=c.eventMin-1e-10 && (innovation>c.zohAngle || elapsed>=gap-1e-10);
        elseif strcmp(c.trigger,'dynamic')
            e2=innovation^2;                           % deviation of the extrapolated broadcast
            % internal variable (Girard 2015): eta' = -lambda*eta + sigma*phi - e^2, trigger when
            % eta + theta*(sigma*phi - e^2) < 0, with phi the squared base threshold.
            phi=c.dynBase^2;
            s.eta(a)=max(0,s.eta(a)+c.dt*(-c.dynLambda*s.eta(a)+c.dynSigma*phi-e2));
            send=elapsed>=c.eventMin-1e-10 && (s.eta(a)+c.dynTheta*(c.dynSigma*phi-e2)<0 || elapsed>=gap-1e-10);
        else
            send=elapsed>=c.eventMin-1e-10 && (innovation>c.eventAngle ||...
                norm(s.w(:,i)-s.sentWEdge(:,a))>c.eventRate || elapsed>=gap-1e-10);
        end
        % Estimated infeasibility throttles retries even if local motion is
        % changing. It never prevents local pilot diagnosis from continuing.
        if c.manageSchedule && manager(a)==3,send=elapsed>=gap-1e-10;end
        if strcmp(c.policy,'frozen') && gap>c.eventMax,send=elapsed>=gap-1e-10;end
    end
    if ~send,continue;end
    if strcmp(c.trigger,'self')
        tau=min(c.eventMax,max(c.eventMin,sqrt(2*c.eventAngle/c.selfAccel)));
        s.nextSend(a)=t+tau;
    end
    if strcmp(c.trigger,'dynamic'),s.eta(a)=0;end
    if c.gat,s.gatNext(a)=t+gatInterval(s,c,i);end   % next send fixed by the receiver's certified error reaching the tolerance
    s.lastSendEdge(a)=t;s.sentQEdge(:,a)=s.q(:,i);s.sentWEdge(:,a)=s.w(:,i);
    attempts(i)=attempts(i)+1;
    if ~gate(a) || lostNow(a),continue;end
    count=s.queueCount(a)+1;assert(count<=size(s.queue,2),'Tracking queue overflow');
    delay=c.delay+c.jitter*delayDraw(a);if c.ideal,delay=0;end
    arrival=t+max(c.dt,ceil(delay/c.dt)*c.dt);
    s.queue(:,count,a)=[arrival;t;s.q(:,i);s.w(:,i);i;c.receiver(a);s.Hnode(i);s.Wnode(i);s.parent(i)];
    s.queueCount(a)=count;
end
end

function send=clacDecision(s,t,c,a,gate,elapsed)
i=c.sender(a);j=c.receiver(a);
% Every packet carries sender state and the sender's certificate and chosen parent, so one
% endpoint serves as data feed (if j uses i as parent), report (if i uses j) or heartbeat.
if ~gate(a),send=elapsed>=c.clacRetryGap-1e-10;return;end      % own terminal not locked: throttle
if j~=1 && s.cachedParentId(j,i)==i                              % j reported i as its tree link
    if c.gat   % tolerance-guaranteed trigger: no state monitoring, the next time follows from the certificate
        send=elapsed>=c.eventMin-1e-10 && (t>=s.gatNext(a)-1e-10 || elapsed>=c.gatMaxSilence-1e-10);
        return;
    end
    represented=isc_math('mul',s.sentQEdge(:,a),isc_math('exp',s.sentWEdge(:,a)*min(elapsed,c.eventMax)));
    innovation=norm(isc_math('log',isc_math('mul',isc_math('conj',represented),s.q(:,i))));
    send=elapsed>=c.eventMin-1e-10 && (innovation>c.eventAngle ||...
        norm(s.w(:,i)-s.sentWEdge(:,a))>c.eventRate || elapsed>=c.eventMax-1e-10);
    return;
end
period=c.clacStandbyPeriod;
if c.clacReselect && s.parent(i)==j,period=c.clacReportPeriod;end
send=elapsed>=period-1e-10;
end

function d=gatInterval(s,c,i)
% Time after a transmission at which the receiver's certified target error would reach the tolerance,
% minus the delay margin. Uses only the bounds being sent and the command-class constants.
H=s.Hnode(i);W=s.Wnode(i);ref=c.clacRef;
if ~isfinite(H)||~isfinite(W),d=c.eventMin;return;end
hor=isc_clac('horizon',W,ref,c);
f=@(a) isc_clac('bound',H,W,a,hor,ref).Eatt-H-c.gatTol;   % communication-induced part of the bound
if f(0)>=0,d=c.eventMin;return;end
hi=c.gatMaxSilence+c.gatDelayMargin;
if f(hi)<0,a=hi;else
    lo=0;for k=1:30,mid=(lo+hi)/2;if f(mid)<0,lo=mid;else,hi=mid;end,end;a=lo;
end
d=min(max(a-c.gatDelayMargin,c.eventMin),c.gatMaxSilence);
end
