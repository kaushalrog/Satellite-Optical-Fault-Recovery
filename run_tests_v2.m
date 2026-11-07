function run_tests_v2()
% Revision test suite: optics, certificate soundness, evaluation cases, legacy regression.
root=fileparts(mfilename('fullpath'));addpath(fullfile(root,'src'),fullfile(root,'tests'),fullfile(root,'validation'));
test_optics();test_certificate();test_v2_cases();test_legacy_regression();
fprintf('ALL_V2_TESTS_PASS\n');
end
