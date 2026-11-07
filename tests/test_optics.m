function test_optics()
root=fileparts(fileparts(mfilename('fullpath')));addpath(fullfile(root,'src'),fullfile(root,'validation'));
validate_link_budget();
r=isc_optics('receiver',struct());
P=logspace(-8,-3,60);ber=isc_optics('ber',P,r);per=isc_optics('per',P,r);
assert(all(diff(ber)<=1e-15),'BER must be non-increasing in power');
assert(all(diff(per)<=1e-12),'PER must be non-increasing in power');
assert(per(1)>0.999 && per(end)<1e-12,'PER must go from 1 to 0');
assert(all(per<=1 & per>=0));
th=isc_optics('threshold',r);assert(abs(isc_optics('per',th,r)-r.perThreshold)<1e-6,'derived threshold must give PER=0.1');
r2=r;r2.codeCorrectable=-1;assert(isc_optics('threshold',r2)>th,'FEC must lower the required power');
% closed-form check of the Gaussian-beam gain: G = 16 ln2 / FWHM^2
b=isc_optics('budget',struct('txPower_W',1,'txLoss_dB',0,'fwhm_rad',1e-3,'pointingError_rad',0,'range_m',1,'atmLoss_dB',0));
assert(abs(b.txGain_dBi-10*log10(16*log(2)/1e-6))<1e-9);
% On-boresight and half-power pointing: loss must be 0 dB and 3.01 dB at FWHM/2
b2=isc_optics('budget',struct('txPower_W',1,'txLoss_dB',0,'fwhm_rad',1e-3,'pointingError_rad',5e-4,'range_m',1,'atmLoss_dB',0));
assert(abs(b2.pointLoss_dB+3.0103)<1e-3,'half-width pointing offset must lose 3 dB');
fprintf('OPTICS_TESTS_PASS\n');
end
