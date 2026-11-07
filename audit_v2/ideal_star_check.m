root=fileparts(fileparts(mfilename('fullpath')));addpath(fullfile(root,'src'));
for tree={'chain','star'}
  v=zeros(1,20);for k=1:20,c=isc_v2_config('healthy','ideal_periodic',200+k,tree{1});r=isc_run(c);v(k)=r.trackingMetrics.fault_pair_rms_rad*180/pi;end
  fprintf('IDEALCHECK healthy ideal-communication %s: mean pair RMS %.3f deg\n',tree{1},mean(v));
end
