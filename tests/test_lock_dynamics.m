function test_lock_dynamics()
% Lock hysteresis and acquisition dwell of the physical optical layer.
root=fileparts(fileparts(mfilename('fullpath')));addpath(fullfile(root,'src'));
c=isc_v2_method('attenuation_severe','eo_star',11);r=isc_run(c);
t=r.t;lk=r.lock(:,1);                       % link 1-2, endpoint 1 (pair-gated lock)
assert(all(lk(t<c.faultStart)==1),'link must be locked before the fault');
tl=t(find(lk==0&t>=c.faultStart,1));
assert(tl>=c.faultStart+c.lockLossTime-2*c.dt && tl<=c.faultStart+c.lockLossTime+1,'lock loss must follow the 0.5 s hold time');
tr=t(find(lk==1&t>=c.faultEnd,1));
assert(tr>=c.faultEnd+c.acquireTime-2*c.dt,'re-acquisition must wait for the acquisition dwell (%.2f s)',tr-c.faultEnd);
assert(tr<=c.faultEnd+c.acquireTime+5,'re-acquisition unexpectedly slow');
% slow acquisition stress: dwell 15 s
c2=isc_v2_method('slow_acquisition','eo_star',11);assert(c2.acquireTime==15);
% encoder/jitter draws exist only in physical mode: legacy stream untouched
assert(strcmp(isc_holdout_config('principal_pointing','optical_event',101).optics,'legacy'));
fprintf('LOCK_DYNAMICS_PASS: loss after %.2f s, re-lock %.2f s after fault end\n',tl-c.faultStart,tr-c.faultEnd);
end
