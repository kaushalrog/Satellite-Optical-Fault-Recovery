function y=isc_optics(op,a,b)
% Physical optical-link model (SI units). Replaces the instantaneous
% power threshold of the legacy model when c.optics = 'physical'.
%
%   'budget'    a: parameter struct -> link-budget breakdown (dB form)
%   'ber'       a: average received power [W], b: receiver struct -> raw BER
%   'per'       a: average received power [W], b: receiver struct -> packet
%               (codeword) error probability after FEC
%   'threshold' a: receiver struct -> power at which packet error = a.perThreshold
%   'receiver'  a: config -> receiver struct
%   'apply'     a: config -> config with derived P0, divergence, sensitivity
%
% Gaussian beam, far field. FWHM is the full width at half maximum of the
% INTENSITY profile; the 1/e^2 half-angle is alpha = FWHM/sqrt(2 ln 2).
switch op
case 'budget'
    p=a; fwhm=p.fwhm_rad;
    gainTx=16*log(2)/fwhm^2;                       % peak gain of a Gaussian beam
    pointLoss=exp(-4*log(2)*(p.pointingError_rad/fwhm)^2);
    y.txPower_dBW=10*log10(p.txPower_W);
    y.txLoss_dB=-abs(p.txLoss_dB);
    y.txGain_dBi=10*log10(gainTx);
    y.pointLoss_dB=10*log10(pointLoss);
    y.rangeLoss_dBm2=-10*log10(4*pi*p.range_m^2);
    y.atmLoss_dB=-abs(p.atmLoss_dB);
    y.irradiance_dBWm2=y.txPower_dBW+y.txLoss_dB+y.txGain_dBi+y.pointLoss_dB+y.rangeLoss_dBm2+y.atmLoss_dB;
    if isfield(p,'rxArea_m2')
        y.rxArea_dBm2=10*log10(p.rxArea_m2);
        y.rxLoss_dB=-abs(p.rxLoss_dB);
        y.rxPower_dBW=y.irradiance_dBWm2+y.rxArea_dBm2+y.rxLoss_dB;
        y.rxPower_W=10^(y.rxPower_dBW/10);
    end
case 'ber'
    P=a; r=b; q=1.602176634e-19;
    I1=2*r.responsivity*P;                          % OOK, infinite extinction, peak = 2 x average
    Ib=r.responsivity*r.backgroundPower_W+r.darkCurrent_A;
    sth2=(r.noiseDensity_AsqrtHz^2)*r.noiseBandwidth_Hz;
    s0=sqrt(sth2+2*q*Ib*r.noiseBandwidth_Hz);
    s1=sqrt(sth2+2*q*(I1+Ib)*r.noiseBandwidth_Hz);
    Q=I1./(s0+s1);
    y=0.5*erfc(Q/sqrt(2));
case 'per'
    P=a; r=b; ber=isc_optics('ber',P,r);
    ps=-expm1(8*log1p(-min(ber,0.5)));              % GF(2^8) symbol error probability
    n=r.codeLength; t=r.codeCorrectable; y=zeros(size(P));
    for h=1:numel(P)
        p=min(max(ps(h),realmin),1-1e-16); i=(t+1):n;
        logTerm=gammaln(n+1)-gammaln(i+1)-gammaln(n-i+1)+i*log(p)+(n-i)*log1p(-p);
        y(h)=min(1,sum(exp(logTerm)));
    end
    if r.codeCorrectable<0                          % uncoded option: packet of codeLength bytes
        y=-expm1(8*r.codeLength*log1p(-min(ber,0.5)));
    end
case 'threshold'
    r=a; lo=log10(1e-9); hi=log10(1e-3);
    for k=1:80
        mid=(lo+hi)/2;
        if isc_optics('per',10^mid,r)>r.perThreshold,lo=mid;else,hi=mid;end
    end
    y=10^hi;
case 'receiver'
    c=a; y=struct('responsivity',0.9,'noiseDensity_AsqrtHz',5e-12,...
        'dataRate_bps',1e8,'backgroundPower_W',1e-8,'darkCurrent_A',1e-9,...
        'codeLength',88,'codeCorrectable',8,'perThreshold',0.1);
    y.noiseBandwidth_Hz=0.7*y.dataRate_bps;
    if isfield(c,'rxOverride')
        f=fieldnames(c.rxOverride);for k=1:numel(f),y.(f{k})=c.rxOverride.(f{k});end
        y.noiseBandwidth_Hz=0.7*y.dataRate_bps;
    end
case 'apply'
    c=a; r=isc_optics('receiver',c);
    d=struct('txPower_W',c.txPower_W,'txLoss_dB',c.txLoss_dB,'fwhm_rad',c.beamFWHM_rad,...
        'pointingError_rad',0,'range_m',1000,'atmLoss_dB',0,...
        'rxArea_m2',pi*(c.rxDiameter_m/2)^2,'rxLoss_dB',c.rxLoss_dB);
    bud=isc_optics('budget',d);
    c.divergence=c.beamFWHM_rad/sqrt(2*log(2));      % 1/e^2 half-angle
    c.P0=bud.rxPower_W;                              % nominal received power at 1000 m
    c.receiverModel=r;
    c.sensitivity=isc_optics('threshold',r);         % derived, not assumed
    c.budget=bud;c.randomDrop=0;
    c.maxCorrection=1.5*c.divergence;c.probeAmplitude=0.16*c.divergence;
    y=c;
otherwise,error('Unknown operation');
end
end
