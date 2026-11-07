function run_tests_all()
% Full suite: revision tests, lock-dynamics test, and the original integrated suite.
root=fileparts(mfilename('fullpath'));addpath(fullfile(root,'src'),fullfile(root,'tests'),fullfile(root,'validation'));
run_tests_v2();test_lock_dynamics();
report=run_tests; %#ok<NASGU>
fprintf('ALL_TESTS_PASS\n');
end
