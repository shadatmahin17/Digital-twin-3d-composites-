% ============================================================
% Literature-Calibrated Lifecycle Digital Twin for
% 3D Woven/Braided Composites
%
% This version:
% - uses literature-based parameter ranges
% - always saves figures
% - displays figures when MATLAB GUI is available
% - exports CSV results
% - includes reliability analysis
%
% Author: Shadat Hossen Mahin
% ============================================================

clear; clc; close all;

set(0, 'DefaultFigureVisible', 'on');

% ============================================================
% SETTINGS
% ============================================================
SEED = 42;
rng(SEED);

OUTPUT_DIR = 'digital_twin_outputs_matlab';
if ~exist(OUTPUT_DIR, 'dir')
    mkdir(OUTPUT_DIR);
end

n_samples = 3000;
impact_energy_J = 30.0;
cycles = 5e5;

% ============================================================
% RUN DIGITAL TWIN
% ============================================================
results = run_digital_twin(n_samples, impact_energy_J, cycles);

% Synthetic measured CAI for literature-style calibration demo
measured_cai = synthetic_measured_cai(results.cai_strength, 20.0, 380.0, 520.0);
[beta, calibrated_cai, calibration_rmse] = calibrate_strength_model(results.arch, results.proc, measured_cai); %#ok<ASGLU>

% Sensitivity ranking
input_names = {
    'fiber_volume_fraction', 'binder_density', 'waviness', ...
    'braid_angle_deg', 'thickness_mm', 'compaction_pressure_MPa', ...
    'resin_flow_rate', 'cure_temp_deviation_C'
};
full_inputs = [results.arch, results.proc];
sensitivity = correlation_sensitivity(full_inputs, results.cai_strength, input_names);

% Reliability
reliability = reliability_analysis(results.cai_strength, results.fatigue_strength);

% Print summary
print_summary(results, calibration_rmse, sensitivity, reliability);

% Export CSV
csv_path_1 = export_results_csv(results, OUTPUT_DIR, 'simulation_results.csv');
csv_path_2 = export_summary_csv(results, calibration_rmse, sensitivity, reliability, OUTPUT_DIR, 'summary_metrics.csv');

% Figures
fig1 = save_scatter_void_vs_cai(results, OUTPUT_DIR);
fig2 = save_scatter_defect_vs_fatigue(results, OUTPUT_DIR);
fig3 = save_histogram_cai(results, OUTPUT_DIR);
fig4 = save_sensitivity_bar(sensitivity, OUTPUT_DIR);
fig5 = save_calibration_plot(measured_cai, calibrated_cai, OUTPUT_DIR);
fig6 = save_reliability_histogram(results, OUTPUT_DIR);

fprintf('\nSaved outputs\n');
fprintf('-------------------------------------------------------------\n');
fprintf('%s\n', csv_path_1);
fprintf('%s\n', csv_path_2);
fprintf('%s\n', fig1);
fprintf('%s\n', fig2);
fprintf('%s\n', fig3);
fprintf('%s\n', fig4);
fprintf('%s\n', fig5);
fprintf('%s\n', fig6);

drawnow;
fprintf('\nAll figures generated and displayed.\n');

% Uncomment this if you want MATLAB to wait before closing figures
% waitforbuttonpress;

% ============================================================
% HELPER FUNCTIONS
% ============================================================
function x_norm = normalize_val(x, bounds)
    xmin = bounds(1);
    xmax = bounds(2);
    x_norm = (x - xmin) ./ (xmax - xmin + 1e-12);
end

function x_clip = clip01(x)
    x_clip = max(0.0, min(x, 1.0));
end

function txt = mean_std_text(x)
    txt = sprintf('%.3f ± %.3f', mean(x), std(x));
end

function bounds = get_arch_bounds()
    bounds.fiber_volume_fraction = [0.48, 0.60];
    bounds.binder_density = [0.10, 0.20];
    bounds.waviness = [0.02, 0.08];
    bounds.braid_angle_deg = [25.0, 40.0];
    bounds.thickness_mm = [3.0, 6.0];
end

function bounds = get_proc_bounds()
    bounds.compaction_pressure_MPa = [0.2, 1.5];
    bounds.resin_flow_rate = [0.5, 2.0];
    bounds.cure_temp_deviation_C = [-10.0, 15.0];
end

function limit = CAI_LIMIT()
    limit = 450.0;
end

function limit = FATIGUE_LIMIT()
    limit = 350.0;
end

% ============================================================
% SAMPLING
% ============================================================
function arch = sample_architecture(n)
    b = get_arch_bounds();
    fv = b.fiber_volume_fraction(1) + diff(b.fiber_volume_fraction) * rand(n,1);
    bd = b.binder_density(1) + diff(b.binder_density) * rand(n,1);
    wav = b.waviness(1) + diff(b.waviness) * rand(n,1);
    angle = b.braid_angle_deg(1) + diff(b.braid_angle_deg) * rand(n,1);
    thk = b.thickness_mm(1) + diff(b.thickness_mm) * rand(n,1);
    arch = [fv, bd, wav, angle, thk];
end

function proc = sample_process(n)
    b = get_proc_bounds();
    cp = b.compaction_pressure_MPa(1) + diff(b.compaction_pressure_MPa) * rand(n,1);
    fr = b.resin_flow_rate(1) + diff(b.resin_flow_rate) * rand(n,1);
    td = b.cure_temp_deviation_C(1) + diff(b.cure_temp_deviation_C) * rand(n,1);
    proc = [cp, fr, td];
end

% ============================================================
% FEATURE MAP
% ============================================================
function X = feature_map(arch, proc)
    fv = arch(:,1); bd = arch(:,2); wav = arch(:,3); angle = arch(:,4); thk = arch(:,5);
    cp = proc(:,1); fr = proc(:,2); td = proc(:,3);
    angle_r = deg2rad(angle);
    n = size(arch,1);

    X = [ones(n,1), ...
         fv, bd, wav, angle/40.0, thk/6.0, ...
         cp/1.5, fr/2.0, td/15.0, ...
         fv.*bd, fv.*cp, wav.*cp, wav.*fr, bd.*fr, ...
         sin(angle_r), cos(angle_r), thk.*wav, cp.*fr, td.*wav, bd.*cp.*fr];
end

% ============================================================
% DEFECT MODEL
% ============================================================
function defects = predict_defects(arch, proc)
    bd = arch(:,2); wav = arch(:,3); angle = arch(:,4); thk = arch(:,5);
    cp = proc(:,1); fr = proc(:,2); td = proc(:,3);

    a = get_arch_bounds();
    p = get_proc_bounds();

    bd_n = normalize_val(bd, a.binder_density);
    wav_n = normalize_val(wav, a.waviness);
    angle_n = normalize_val(angle, a.braid_angle_deg);
    thk_n = normalize_val(thk, a.thickness_mm);
    cp_n = normalize_val(cp, p.compaction_pressure_MPa);
    fr_n = normalize_val(fr, p.resin_flow_rate);
    td_n = normalize_val(td, p.cure_temp_deviation_C);

    n = size(arch,1);

    void_fraction = 0.010 ...
        + 0.010 .* wav_n ...
        + 0.008 .* fr_n ...
        + 0.004 .* thk_n ...
        + 0.006 .* max(td_n, 0.0) ...
        - 0.008 .* cp_n ...
        + 0.006 .* bd_n .* fr_n ...
        + 0.002 .* randn(n,1);
    void_fraction = max(0.010, min(void_fraction, 0.040));

    resin_rich_index = 0.05 ...
        + 0.08 .* bd_n ...
        + 0.05 .* thk_n ...
        + 0.05 .* fr_n ...
        - 0.04 .* cp_n ...
        + 0.02 .* angle_n ...
        + 0.010 .* randn(n,1);
    resin_rich_index = max(0.05, min(resin_rich_index, 0.20));

    waviness_amplification = 0.02 ...
        + 0.10 .* wav_n ...
        - 0.03 .* cp_n ...
        + 0.02 .* bd_n ...
        + 0.02 .* fr_n ...
        + 0.01 .* randn(n,1);
    waviness_amplification = max(0.0, min(waviness_amplification, 0.25));

    defect_severity = clip01(4.0 .* void_fraction + 1.2 .* resin_rich_index + 1.6 .* waviness_amplification);

    defects.void_fraction = void_fraction;
    defects.resin_rich_index = resin_rich_index;
    defects.waviness_amplification = waviness_amplification;
    defects.defect_severity = defect_severity;
end

% ============================================================
% STRUCTURAL MODELS
% ============================================================
function strength = predict_undamaged_strength(arch)
    fv = arch(:,1); bd = arch(:,2); wav = arch(:,3); angle = arch(:,4); thk = arch(:,5);

    binder_effect = 1.0 - 0.40 .* ((bd - 0.15).^2 ./ (0.05^2));
    binder_effect = max(0.82, min(binder_effect, 1.05));

    angle_penalty = 0.10 .* ((angle - 30.0) ./ 10.0).^2;
    angle_penalty = max(0.0, min(angle_penalty, 0.20));

    strength = 780.0;
    strength = strength + 420.0 .* (fv - 0.48) ./ 0.12;
    strength = strength - 900.0 .* wav;
    strength = strength .* binder_effect;
    strength = strength .* (1.0 - angle_penalty);
    strength = strength - 70.0 .* ((thk - 4.5) ./ 1.5).^2;

    strength = max(600.0, min(strength, 1200.0));
end

function [cai_strength, damage_index] = predict_cai_strength(arch, proc, defects, impact_energy_J)
    s0 = predict_undamaged_strength(arch);

    vf = defects.void_fraction;
    rr = defects.resin_rich_index;
    wa = defects.waviness_amplification;
    ds = defects.defect_severity;

    bd = arch(:,2);
    angle = arch(:,4);
    n = size(arch,1);

    impact_severity = impact_energy_J / 40.0;

    architecture_toughness = 0.16 + 0.45 .* bd - 0.08 .* ((angle - 30.0) ./ 15.0).^2;
    architecture_toughness = max(0.08, min(architecture_toughness, 0.28));

    damage_index = 0.22 .* impact_severity ...
        + 1.50 .* vf ...
        + 0.45 .* rr ...
        + 0.70 .* wa ...
        + 0.65 .* ds ...
        - 0.50 .* architecture_toughness ...
        + 0.025 .* randn(n,1);

    damage_index = max(0.08, min(damage_index, 0.60));

    cai_strength = s0 .* (1.0 - damage_index);
    cai_strength = max(380.0, min(cai_strength, 520.0));
end

function [fatigue_strength, knockdown] = predict_fatigue_knockdown(arch, defects, cycles, stress_ratio)
    if nargin < 4, stress_ratio = 0.1; end

    bd = arch(:,2); wav = arch(:,3);
    vf = defects.void_fraction;
    rr = defects.resin_rich_index;
    ds = defects.defect_severity;
    n = size(arch,1);

    logN = log10(cycles);

    knockdown = 0.88 ...
        - 0.030 .* (logN - 5.0) ...
        - 0.90 .* vf ...
        - 0.10 .* rr ...
        - 0.45 .* wav ...
        - 0.18 .* ds ...
        + 0.06 .* bd ...
        + 0.03 .* stress_ratio ...
        + 0.01 .* randn(n,1);

    knockdown = max(0.35, min(knockdown, 0.90));
    fatigue_strength = predict_undamaged_strength(arch) .* knockdown;
    fatigue_strength = max(350.0, min(fatigue_strength, 650.0));
end

% ============================================================
% METRICS
% ============================================================
function cert = certification_metrics(cai_strength, fatigue_strength)
    cai_pass = cai_strength >= CAI_LIMIT();
    fatigue_pass = fatigue_strength >= FATIGUE_LIMIT();

    cert.cai_pass_rate = mean(cai_pass);
    cert.fatigue_pass_rate = mean(fatigue_pass);
    cert.joint_pass_rate = mean(cai_pass & fatigue_pass);
end

function rel = reliability_analysis(cai_strength, fatigue_strength)
    cai_fail = cai_strength < CAI_LIMIT();
    fatigue_fail = fatigue_strength < FATIGUE_LIMIT();
    joint_fail = cai_fail | fatigue_fail;

    rel.prob_fail_cai = mean(cai_fail);
    rel.prob_fail_fatigue = mean(fatigue_fail);
    rel.prob_fail_joint = mean(joint_fail);
    rel.reliability_cai = 1.0 - rel.prob_fail_cai;
    rel.reliability_fatigue = 1.0 - rel.prob_fail_fatigue;
    rel.reliability_joint = 1.0 - rel.prob_fail_joint;
end

% ============================================================
% CALIBRATION
% ============================================================
function beta = fit_ridge_regression(X, y, lam)
    if nargin < 3, lam = 1e-3; end
    beta = (X' * X + lam * eye(size(X,2))) \ (X' * y);
end

function pred = predict_ridge(X, beta)
    pred = X * beta;
end

function meas = synthetic_measured_cai(cai_pred, noise_std, ymin, ymax)
    meas = cai_pred + noise_std * randn(length(cai_pred),1);
    meas = max(ymin, min(meas, ymax));
end

function [beta, pred, rmse] = calibrate_strength_model(arch, proc, measured_cai)
    X = feature_map(arch, proc);
    beta = fit_ridge_regression(X, measured_cai, 1e-2);
    pred = predict_ridge(X, beta);
    pred = max(380.0, min(pred, 520.0));
    rmse = sqrt(mean((pred - measured_cai).^2));
end

% ============================================================
% SENSITIVITY
% ============================================================
function ranking = correlation_sensitivity(inputs, y, names)
    num_vars = size(inputs,2);
    sens_data = zeros(num_vars,2);

    for i = 1:num_vars
        r = corrcoef(inputs(:,i), y);
        c = r(1,2);
        if isnan(c), c = 0.0; end
        sens_data(i,1) = abs(c);
        sens_data(i,2) = c;
    end

    [~, idx] = sort(sens_data(:,1), 'descend');
    ranking = cell(num_vars,3);
    for i = 1:num_vars
        j = idx(i);
        ranking{i,1} = names{j};
        ranking{i,2} = sens_data(j,1);
        ranking{i,3} = sens_data(j,2);
    end
end

% ============================================================
% MAIN DIGITAL TWIN
% ============================================================
function results = run_digital_twin(n_samples, impact_energy_J, cycles)
    arch = sample_architecture(n_samples);
    proc = sample_process(n_samples);

    defects = predict_defects(arch, proc);
    undamaged_strength = predict_undamaged_strength(arch);
    [cai_strength, damage_index] = predict_cai_strength(arch, proc, defects, impact_energy_J);
    [fatigue_strength, fatigue_knockdown] = predict_fatigue_knockdown(arch, defects, cycles);

    cert = certification_metrics(cai_strength, fatigue_strength);

    results.arch = arch;
    results.proc = proc;
    results.defects = defects;
    results.undamaged_strength = undamaged_strength;
    results.cai_strength = cai_strength;
    results.damage_index = damage_index;
    results.fatigue_strength = fatigue_strength;
    results.fatigue_knockdown = fatigue_knockdown;
    results.certification = cert;
end

% ============================================================
% EXPORTS
% ============================================================
function path = export_results_csv(results, out_dir, filename)
    path = fullfile(out_dir, filename);

    T = table(results.arch(:,1), results.arch(:,2), results.arch(:,3), results.arch(:,4), results.arch(:,5), ...
              results.proc(:,1), results.proc(:,2), results.proc(:,3), ...
              results.defects.void_fraction, results.defects.resin_rich_index, ...
              results.defects.waviness_amplification, results.defects.defect_severity, ...
              results.undamaged_strength, results.damage_index, results.cai_strength, ...
              results.fatigue_strength, results.fatigue_knockdown, ...
              'VariableNames', {'fiber_volume_fraction', 'binder_density', 'waviness', ...
              'braid_angle_deg', 'thickness_mm', 'compaction_pressure_MPa', ...
              'resin_flow_rate', 'cure_temp_deviation_C', 'void_fraction', ...
              'resin_rich_index', 'waviness_amplification', 'defect_severity', ...
              'undamaged_strength_MPa', 'damage_index', 'CAI_strength_MPa', ...
              'fatigue_strength_MPa', 'fatigue_knockdown'});
    writetable(T, path);
end

function path = export_summary_csv(results, calibration_rmse, sensitivity, reliability, out_dir, filename)
    path = fullfile(out_dir, filename);
    fid = fopen(path, 'w');

    fprintf(fid, 'Metric,Value\n');
    fprintf(fid, 'Mean undamaged strength (MPa),%f\n', mean(results.undamaged_strength));
    fprintf(fid, 'Mean CAI strength (MPa),%f\n', mean(results.cai_strength));
    fprintf(fid, 'Mean fatigue strength (MPa),%f\n', mean(results.fatigue_strength));
    fprintf(fid, 'Mean void fraction,%f\n', mean(results.defects.void_fraction));
    fprintf(fid, 'CAI pass rate,%f\n', results.certification.cai_pass_rate);
    fprintf(fid, 'Fatigue pass rate,%f\n', results.certification.fatigue_pass_rate);
    fprintf(fid, 'Joint pass rate,%f\n', results.certification.joint_pass_rate);
    fprintf(fid, 'CAI failure probability,%f\n', reliability.prob_fail_cai);
    fprintf(fid, 'Fatigue failure probability,%f\n', reliability.prob_fail_fatigue);
    fprintf(fid, 'Joint failure probability,%f\n', reliability.prob_fail_joint);
    fprintf(fid, 'Calibration RMSE (MPa),%f\n', calibration_rmse);

    fprintf(fid, '\nSensitivity ranking,Abs(correlation) / Signed correlation\n');
    for i = 1:size(sensitivity,1)
        fprintf(fid, '%s,%.4f / %.4f\n', sensitivity{i,1}, sensitivity{i,2}, sensitivity{i,3});
    end

    fclose(fid);
end

% ============================================================
% FIGURES
% ============================================================
function path = save_scatter_void_vs_cai(results, out_dir)
    f = figure('Visible','on','Position',[100 100 700 500]);
    scatter(results.defects.void_fraction, results.cai_strength, 20, 'filled', 'MarkerFaceAlpha', 0.5);
    xlabel('Void Fraction','FontWeight','bold');
    ylabel('CAI Strength (MPa)','FontWeight','bold');
    title('CAI Strength vs Void Fraction');
    grid on;
    set(gca,'FontSize',12,'LineWidth',1);
    drawnow;
    path = fullfile(out_dir, 'figure_void_vs_cai.png');
    exportgraphics(f, path, 'Resolution', 300);
end

function path = save_scatter_defect_vs_fatigue(results, out_dir)
    f = figure('Visible','on','Position',[100 100 700 500]);
    scatter(results.defects.defect_severity, results.fatigue_knockdown, 20, 'filled', 'MarkerFaceAlpha', 0.5);
    xlabel('Defect Severity','FontWeight','bold');
    ylabel('Fatigue Knockdown Factor','FontWeight','bold');
    title('Fatigue Knockdown vs Defect Severity');
    grid on;
    set(gca,'FontSize',12,'LineWidth',1);
    drawnow;
    path = fullfile(out_dir, 'figure_defect_vs_fatigue.png');
    exportgraphics(f, path, 'Resolution', 300);
end

function path = save_histogram_cai(results, out_dir)
    f = figure('Visible','on','Position',[100 100 700 500]);
    histogram(results.cai_strength, 30);
    hold on;
    xline(CAI_LIMIT(), '--r', 'CAI Limit', 'LineWidth', 1.5);
    xlabel('CAI Strength (MPa)','FontWeight','bold');
    ylabel('Frequency','FontWeight','bold');
    title('Distribution of CAI Strength');
    grid on;
    set(gca,'FontSize',12,'LineWidth',1);
    hold off;
    drawnow;
    path = fullfile(out_dir, 'figure_cai_histogram.png');
    exportgraphics(f, path, 'Resolution', 300);
end

function path = save_sensitivity_bar(sensitivity, out_dir)
    f = figure('Visible','on','Position',[100 100 800 500]);
    names = flipud(sensitivity(:,1));
    values = cell2mat(flipud(sensitivity(:,2)));
    barh(values);
    set(gca,'yticklabel',strrep(names,'_',' '),'FontSize',12,'LineWidth',1);
    xlabel('Absolute Correlation with CAI Strength','FontWeight','bold');
    ylabel('Input Variable','FontWeight','bold');
    title('Sensitivity Ranking');
    grid on;
    drawnow;
    path = fullfile(out_dir, 'figure_sensitivity_ranking.png');
    exportgraphics(f, path, 'Resolution', 300);
end

function path = save_calibration_plot(measured_cai, calibrated_cai, out_dir)
    f = figure('Visible','on','Position',[100 100 600 600]);
    scatter(measured_cai, calibrated_cai, 20, 'filled', 'MarkerFaceAlpha', 0.5);
    hold on;
    minv = min([measured_cai; calibrated_cai]);
    maxv = max([measured_cai; calibrated_cai]);
    plot([minv maxv], [minv maxv], '--k', 'LineWidth', 1.5);
    xlabel('Measured CAI (MPa)','FontWeight','bold');
    ylabel('Calibrated Prediction (MPa)','FontWeight','bold');
    title('Calibration Check');
    grid on;
    set(gca,'FontSize',12,'LineWidth',1);
    hold off;
    drawnow;
    path = fullfile(out_dir, 'figure_calibration_check.png');
    exportgraphics(f, path, 'Resolution', 300);
end

function path = save_reliability_histogram(results, out_dir)
    f = figure('Visible','on','Position',[100 100 700 500]);
    histogram(results.cai_strength, 35);
    hold on;
    xline(CAI_LIMIT(), '--r', 'Certification Limit', 'LineWidth', 1.5);
    xlabel('CAI Strength (MPa)','FontWeight','bold');
    ylabel('Frequency','FontWeight','bold');
    title('Reliability Distribution of CAI Strength');
    grid on;
    set(gca,'FontSize',12,'LineWidth',1);
    hold off;
    drawnow;
    path = fullfile(out_dir, 'figure_reliability_distribution.png');
    exportgraphics(f, path, 'Resolution', 300);
end

% ============================================================
% SUMMARY
% ============================================================
function print_summary(results, calibration_rmse, sensitivity, reliability)
    fprintf('\n=============================================================\n');
    fprintf('LITERATURE-CALIBRATED DIGITAL TWIN SUMMARY\n');
    fprintf('=============================================================\n');
    fprintf('Undamaged Strength (MPa): %s\n', mean_std_text(results.undamaged_strength));
    fprintf('CAI Strength (MPa):       %s\n', mean_std_text(results.cai_strength));
    fprintf('Fatigue Strength (MPa):   %s\n', mean_std_text(results.fatigue_strength));
    fprintf('Void Fraction:            %s\n', mean_std_text(results.defects.void_fraction));

    fprintf('\nCertification-style metrics\n');
    fprintf('-------------------------------------------------------------\n');
    fprintf('CAI pass rate:      %.2f%%\n', 100*results.certification.cai_pass_rate);
    fprintf('Fatigue pass rate:  %.2f%%\n', 100*results.certification.fatigue_pass_rate);
    fprintf('Joint pass rate:    %.2f%%\n', 100*results.certification.joint_pass_rate);

    fprintf('\nReliability metrics\n');
    fprintf('-------------------------------------------------------------\n');
    fprintf('CAI failure probability:      %.2f%%\n', 100*reliability.prob_fail_cai);
    fprintf('Fatigue failure probability:  %.2f%%\n', 100*reliability.prob_fail_fatigue);
    fprintf('Joint failure probability:    %.2f%%\n', 100*reliability.prob_fail_joint);

    fprintf('\nCalibration\n');
    fprintf('-------------------------------------------------------------\n');
    fprintf('Calibration RMSE: %.2f MPa\n', calibration_rmse);

    fprintf('\nSensitivity ranking to CAI strength\n');
    fprintf('-------------------------------------------------------------\n');
    for i = 1:size(sensitivity,1)
        fprintf('%-28s abs(corr)=%.3f corr=%.3f\n', sensitivity{i,1}, sensitivity{i,2}, sensitivity{i,3});
    end
end
