function out=isc_clac(op,varargin)
% Certified, link-aware coordination (CLAC). See docs/V2_METHODS.md and the
% paper, Section "Certified Coordination", for the lemma and theorem.
%
% Every spacecraft i keeps an online-computable bound (H_i, W_i) on how far its
% ACTUAL attitude / angular velocity are from the TRUE desired attitude
% q_ref (x) o_i and rate. The bound is built only from
%   - its own exact local tracking error, and
%   - the bound (H_j, W_j) stamped into the last delivered packet of its parent j,
%     grown by the information age with the reference-class constants.
% Nothing in this file reads fault labels, link truth or the leader's command
% at a follower. The reference-class constants (rate and acceleration bound of
% the command generator) are design constants known to every spacecraft.
%
%   out=isc_clac('bound',Hs,Ws,age,horizon,ref)  -> struct with Eatt, Erate
%   out=isc_clac('horizon',Ws,ref,c)             -> certified extrapolation horizon [s]
%   out=isc_clac('update',s,t,c)                 -> state with parent, bounds, horizons
switch op
case 'bound'
    [Hs,Ws,a,hor,ref]=deal(varargin{1:5});
    wbar=ref.omegaMax;al=ref.alphaMax;
    % Gronwall bound on the geodesic distance between the rate-extrapolated target and the
    % true desired attitude (Lemma 1 in the paper): d' <= W + al*s + wbar*(d(s)+d(0)).
    % PROPOSAL P1: exact solution of theta' = W + al*s + wbar*(theta + H), theta(0)=H.
    ex=@(x) exp(wbar*x)*Hs+(Ws+wbar*Hs)*expm1(wbar*x)/wbar+al*(expm1(wbar*x)-wbar*x)/wbar^2;
    if a<=hor
        Eatt=ex(a);Erate=Ws+al*a+wbar*(Eatt+Hs);
    else
        Eatt=ex(hor)+wbar*(a-hor);Erate=wbar;
    end
    out.Eatt=Eatt;out.Erate=Erate;
case 'horizon'
    [Ws,ref,c]=deal(varargin{1:3});
    if ~isfinite(Ws),out=c.clacHorizonMin;return;end
    % Extrapolate while the worst-case rate error of extrapolation (Ws + al*a) is below the
    % worst-case rate of simply holding the target (omegaMax): this minimises the certified bound.
    h=(ref.omegaMax-Ws)/ref.alphaMax;
    out=min(max(h,c.clacHorizonMin),c.clacHorizonMax);
case 'update'
    [s,t,c]=deal(varargin{1:3});ref=c.clacRef;
    parent=s.parent;horizon=s.horizon;
    for i=2:4
        U=inf(1,4);
        for j=1:4                                       % any other spacecraft may serve; soundness needs no acyclicity
            if j==i || s.stamp(j,i)<0,continue;end
            if s.cachedParentId(j,i)==i,continue;end    % never adopt a node that reports us as its parent
            a=t-s.stamp(j,i);
            hj=isc_clac('horizon',s.cachedBoundW(j,i),ref,c);
            b=isc_clac('bound',s.cachedBoundH(j,i),s.cachedBoundW(j,i),a,hj,ref);
            U(j)=b.Eatt;
        end
        if c.clacReselect
            cur=parent(i);curU=Inf;if cur>0 && isfinite(U(cur)),curU=U(cur);end
            [bestU,bj]=min(U);
            canSwitch=isfinite(bestU) && bj~=cur && (isinf(curU) || (bestU<c.clacSwitchRatio*curU && t-s.lastSwitch(i)>=c.clacDwell));
            if canSwitch
                parent(i)=bj;s.lastSwitch(i)=t;s.switches(i)=s.switches(i)+1;
            end
        end
        p=parent(i);if p>0,horizon(i)=isc_clac('horizon',s.cachedBoundW(p,i),ref,c);end
    end
    n=struct('predict',true,'predictionHorizon',horizon,'offsets',{c.offsets},'holdQ',{s.holdQ},...
        'parent',parent,'referencePhase',c.referencePhase);
    Hn=inf(1,4);Wn=inf(1,4);
    for i=1:4
        [qd,wd,~]=isc_tracking_target(i,s.cachedQ,s.cachedW,s.stamp,t,n);
        R=isc_math('rot',s.q(:,i));Rd=isc_math('rot',qd);
        eAtt=norm(isc_math('log',isc_math('mul',isc_math('conj',qd),s.q(:,i))));
        eRate=norm(s.w(:,i)-R'*Rd*wd);
        if i==1
            Hn(i)=eAtt;Wn(i)=eRate;                              % leader target is the exact command
        else
            p=parent(i);
            if s.stamp(p,i)>=0
                a=t-s.stamp(p,i);
                b=isc_clac('bound',s.cachedBoundH(p,i),s.cachedBoundW(p,i),a,horizon(i),ref);
                Hn(i)=b.Eatt+eAtt;Wn(i)=b.Erate+eRate;
            end
        end
    end
    s.parent=parent;s.horizon=horizon;s.Hnode=Hn;s.Wnode=Wn;out=s;
case 'reference'
    % Conservative constants of the command generator (see isc_reference), with
    % margins for the rotation-vector nonlinearity. Verified numerically in tests.
    out.omegaMax=2.45e-3;out.alphaMax=2.6e-4;
otherwise,error('Unknown operation');
end
end
