% AUDIT (read-only): numerical test of Lemma 1 (E,F) against exact worst-case-class motion.
% Does not modify src/. Uses isc_clac('bound') exactly as implemented.
root=fileparts(fileparts(mfilename('fullpath')));addpath(fullfile(root,'src'));
rng(20261107);out=fullfile(root,'audit_v2','results');
% ---------- A. algebra: implemented E vs exact Gronwall solution vs unparenthesised reading
refs={struct('omegaMax',2.45e-3,'alphaMax',2.6e-4),struct('omegaMax',0.05,'alphaMax',0.01)};
fprintf('A. algebra (E_impl vs exact integral vs unparenthesised reading)\n');
for k=1:2
    w=refs{k}.omegaMax;al=refs{k}.alphaMax;worstImpl=inf;worstUnp=inf;
    for H=[0 1e-4 1e-3 1e-2 .1 1];for W=[0 1e-4 1e-3 1e-2];for a=[0 .05 .5 1 3 10 30 100 300]
        c=W+w*H;
        ex=exp(w*a)*H+c*(exp(w*a)-1)/w+al*(exp(w*a)-1-w*a)/w^2;       % exact solution of theta'=W+al s+w(theta+H)
        Eimp=exp(w*a)*(H*(1+w*a)+W*a+al*a^2/2);
        Eunp=exp(w*a)*H*(1+w*a)+W*a+al*a^2/2;                         % reading without outer parentheses
        worstImpl=min(worstImpl,Eimp-ex);worstUnp=min(worstUnp,Eunp-ex);
    end;end;end
    fprintf('  ref %d (wbar=%g): min(E_impl-exact)=%.3e (>=0 means valid); min(E_unparenthesised-exact)=%.3e\n',k,w,worstImpl,worstUnp);
end
% ---------- B/C. Monte-Carlo against true motion: real reference and class-extremal references
dt=0.01;T=160;t=(0:dt:T)';N=numel(t);
function [qr,wr]=makeRef(kind,t,phase,wbar,abar)
    N=numel(t);dt=t(2)-t(1);qr=zeros(4,N);wr=zeros(3,N);
    if strcmp(kind,'real')
        for k=1:N,[qr(:,k),wr(:,k)]=isc_reference(t(k),phase);end
    else
        q=[1;0;0;0];w=zeros(3,1);dirv=randn(3,1);dirv=dirv/norm(dirv);
        for k=1:N
            if mod(k-1,round(1/dt))==0,dirv=randn(3,1);dirv=dirv/norm(dirv);end
            qr(:,k)=q;wr(:,k)=w;
            w=w+dt*abar*dirv;if norm(w)>wbar,w=w*wbar/norm(w);end
            q=isc_math('mul',q,isc_math('exp',w*dt));q=q/norm(q);
        end
    end
end
function y=rotv(axis_),y=axis_/norm(axis_);end
res=[];
cases={{'real',2.45e-3,2.6e-4},{'class',0.05,0.01},{'class',2.45e-3,2.6e-4}};
for ci=1:numel(cases)
    kind=cases{ci}{1};wbar=cases{ci}{2};abar=cases{ci}{3};ref=struct('omegaMax',wbar,'alphaMax',abar);
    nRef=6;maxRatioE=0;maxRatioF=0;viol=0;n=0;maxWnorm=0;
    for rr=1:nRef
        ph=2*pi*rand-pi;[qr,wr]=makeRef(kind,t,ph,wbar,abar);
        maxWnorm=max(maxWnorm,max(vecnorm(wr)));
        for trial=1:400
            ij=randperm(4,2);oj=isc_math('exp',.3*randn(3,1));oi=isc_math('exp',.3*randn(3,1));rho=isc_math('mul',isc_math('conj',oj),oi);
            k0=randi(round(N/2));tau=t(k0);a=rand*min(60,T-tau-1);if rand<.3,a=rand*2;end
            H0=10^(-4+3*rand);W0=wbar*10^(-2+2.2*rand);h=rand*5;if rand<.3,h=max(0,min(3,(wbar-W0)/abar));end
            qs=isc_math('mul',qr(:,k0),oj);wd=isc_math('rot',oj)'*wr(:,k0);
            qj=isc_math('mul',qs,isc_math('exp',H0*rotv(randn(3,1))));
            wj=isc_math('rot',qj)'*isc_math('rot',qs)*wd+W0*rotv(randn(3,1));
            kk=k0+round(a/dt);ti=qr(:,kk);ai=(kk-k0)*dt;
            qhat=isc_math('mul',isc_math('mul',qj,isc_math('exp',wj*min(ai,h))),rho);
            wt=zeros(3,1);if ai<h,wt=isc_math('rot',rho)'*wj;end
            qi=isc_math('mul',ti,oi);wdi=isc_math('rot',oi)'*wr(:,kk);
            theta=norm(isc_math('log',isc_math('mul',isc_math('conj',qi),qhat)));
            rate=norm(wt-isc_math('rot',qhat)'*isc_math('rot',qi)*wdi);
            b=isc_clac('bound',H0,W0,ai,h,ref);
            maxRatioE=max(maxRatioE,theta/b.Eatt);maxRatioF=max(maxRatioF,rate/b.Erate);
            viol=viol+(theta>b.Eatt*(1+1e-9)+1e-12)+(rate>b.Erate*(1+1e-9)+1e-12);n=n+1;
        end
    end
    fprintf('B/C %-5s wbar=%-7g abar=%-7g measured max|w|=%.3g : %d trials, violations %d, max theta/E=%.3f, max rate/F=%.3f\n',kind,wbar,abar,maxWnorm,n,viol,maxRatioE,maxRatioF);
    res=[res;ci n viol maxRatioE maxRatioF]; %#ok<AGROW>
end
writematrix(res,fullfile(out,'math_check_mc.csv'));
