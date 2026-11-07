function c=isc_physical_config(c,varargin)
% Switch a configuration to the physical optical model and set its parameters.
% Every parameter is tagged: [NASA] taken from published TBIRD results,
% [DESIGN] a stated design choice, [ASSUMED] an assumption without a source.
%
% Sources (NASA/MIT Lincoln Laboratory, public release, NASA NTRS):
%   S23  C. M. Schieler et al., "On-orbit demonstration of 200-Gbps laser
%        communication downlink from the TBIRD CubeSat," SPIE 2023.
%        NTRS 20230000434.
%   I23  C. M. Schieler et al., "Recent on-orbit results and ARQ performance
%        analysis for the TBIRD 200-Gbps mission," ICSOS 2023. NTRS 20230014010.
opt=struct('trackingJitter_rad',10e-6,'acquireTime',3,'fitErrMax',0.20);   % fitErrMax frozen on development seeds 11/23/47 (plateau 0.15-0.30)
for k=1:2:numel(varargin),opt.(varargin{k})=varargin{k+1};end
c.optics='physical';
c.txPower_W=5e-3;          % [DESIGN] compact crosslink transmitter
c.txLoss_dB=1;             % [ASSUMED] transmit optics loss
c.beamFWHM_rad=380e-6;     % [NASA] downlink beam FWHM measured on orbit (S23)
c.rxDiameter_m=0.01;       % [DESIGN] receive aperture
c.rxLoss_dB=5.2;           % [ASSUMED] receive optics and detector coupling
c=isc_optics('apply',c);   % derives alpha, nominal power at 1 km, FEC threshold
c.trackingJitter_rad=opt.trackingJitter_rad;  % [NASA] body pointing < 10 urad RMS (I23); stress 35 urad = upper tracking RMS (S23)
c.encoderNoise_rad=5e-6;   % [ASSUMED] terminal encoder noise
c.gimbalTau1=0.03;c.gimbalTau2=0.03;          % [ASSUMED] two-stage lag, total 0.06 s as in the legacy model
c.lockLossPower=c.sensitivity;                % tracking loop drops below the receiver threshold
c.acquirePower=1.5*c.sensitivity;             % [ASSUMED] 1.8 dB acquisition hysteresis
c.lockLossTime=0.5;        % [ASSUMED] hold time before lock is declared lost
c.acquireTime=opt.acquireTime;                % [ASSUMED] nominal 3 s; TBIRD ground pull-in 10-30 s (S23) used as stress
c.fitErrMax=opt.fitErrMax;
end
