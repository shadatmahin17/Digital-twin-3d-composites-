"""
============================================================
Literature-Calibrated Lifecycle Digital Twin for
3D Woven/Braided Composites
============================================================

This version:
- uses literature-based parameter ranges
- always saves figures
- shows figures when the environment supports GUI
- exports CSV results
- includes reliability analysis

Author: Shadat Hossen Mahin
"""

import os
import csv
import numpy as np
import matplotlib.pyplot as plt

plt.ion()

# ============================================================
# SETTINGS
# ============================================================
SEED = 42
np.random.seed(SEED)

OUTPUT_DIR = "digital_twin_outputs_numpy"
os.makedirs(OUTPUT_DIR, exist_ok=True)

CAI_LIMIT = 450.0
FATIGUE_LIMIT = 350.0

ARCH_BOUNDS = {
    "fiber_volume_fraction": (0.48, 0.60),
    "binder_density": (0.10, 0.20),
    "waviness": (0.02, 0.08),
    "braid_angle_deg": (25.0, 40.0),
    "thickness_mm": (3.0, 6.0),
}

PROC_BOUNDS = {
    "compaction_pressure_MPa": (0.2, 1.5),
    "resin_flow_rate": (0.5, 2.0),
    "cure_temp_deviation_C": (-10.0, 15.0),
}

# ============================================================
# HELPERS
# ============================================================
def normalize(x, bounds):
    return (x - bounds[0]) / (bounds[1] - bounds[0] + 1e-12)

def clip01(x):
    return np.clip(x, 0.0, 1.0)

def mean_std_text(x):
    return f"{np.mean(x):.3f} ± {np.std(x):.3f}"

# ============================================================
# SAMPLING
# ============================================================
def sample_architecture(n):
    fv = np.random.uniform(*ARCH_BOUNDS["fiber_volume_fraction"], n)
    bd = np.random.uniform(*ARCH_BOUNDS["binder_density"], n)
    wav = np.random.uniform(*ARCH_BOUNDS["waviness"], n)
    angle = np.random.uniform(*ARCH_BOUNDS["braid_angle_deg"], n)
    thk = np.random.uniform(*ARCH_BOUNDS["thickness_mm"], n)
    return np.column_stack([fv, bd, wav, angle, thk])

def sample_process(n):
    cp = np.random.uniform(*PROC_BOUNDS["compaction_pressure_MPa"], n)
    fr = np.random.uniform(*PROC_BOUNDS["resin_flow_rate"], n)
    td = np.random.uniform(*PROC_BOUNDS["cure_temp_deviation_C"], n)
    return np.column_stack([cp, fr, td])

# ============================================================
# FEATURE MAP
# ============================================================
def feature_map(arch, proc):
    fv, bd, wav, angle, thk = arch.T
    cp, fr, td = proc.T
    angle_r = np.deg2rad(angle)

    return np.column_stack([
        np.ones(len(fv)),
        fv, bd, wav, angle / 40.0, thk / 6.0,
        cp / 1.5, fr / 2.0, td / 15.0,
        fv * bd, fv * cp, wav * cp, wav * fr, bd * fr,
        np.sin(angle_r), np.cos(angle_r), thk * wav, cp * fr, td * wav, bd * cp * fr
    ])

# ============================================================
# DEFECT MODEL
# ============================================================
def predict_defects(arch, proc):
    bd = arch[:, 1]
    wav = arch[:, 2]
    angle = arch[:, 3]
    thk = arch[:, 4]
    cp, fr, td = proc.T

    bd_n = normalize(bd, ARCH_BOUNDS["binder_density"])
    wav_n = normalize(wav, ARCH_BOUNDS["waviness"])
    angle_n = normalize(angle, ARCH_BOUNDS["braid_angle_deg"])
    thk_n = normalize(thk, ARCH_BOUNDS["thickness_mm"])
    cp_n = normalize(cp, PROC_BOUNDS["compaction_pressure_MPa"])
    fr_n = normalize(fr, PROC_BOUNDS["resin_flow_rate"])
    td_n = normalize(td, PROC_BOUNDS["cure_temp_deviation_C"])

    n = len(bd)

    void_fraction = (
        0.010
        + 0.010 * wav_n
        + 0.008 * fr_n
        + 0.004 * thk_n
        + 0.006 * np.maximum(td_n, 0.0)
        - 0.008 * cp_n
        + 0.006 * bd_n * fr_n
        + 0.002 * np.random.randn(n)
    )
    void_fraction = np.clip(void_fraction, 0.010, 0.040)

    resin_rich_index = (
        0.05
        + 0.08 * bd_n
        + 0.05 * thk_n
        + 0.05 * fr_n
        - 0.04 * cp_n
        + 0.02 * angle_n
        + 0.010 * np.random.randn(n)
    )
    resin_rich_index = np.clip(resin_rich_index, 0.05, 0.20)

    waviness_amplification = (
        0.02
        + 0.10 * wav_n
        - 0.03 * cp_n
        + 0.02 * bd_n
        + 0.02 * fr_n
        + 0.01 * np.random.randn(n)
    )
    waviness_amplification = np.clip(waviness_amplification, 0.0, 0.25)

    defect_severity = clip01(
        4.0 * void_fraction + 1.2 * resin_rich_index + 1.6 * waviness_amplification
    )

    return {
        "void_fraction": void_fraction,
        "resin_rich_index": resin_rich_index,
        "waviness_amplification": waviness_amplification,
        "defect_severity": defect_severity,
    }

# ============================================================
# STRUCTURAL MODELS
# ============================================================
def predict_undamaged_strength(arch):
    fv, bd, wav, angle, thk = arch.T

    binder_effect = 1.0 - 0.40 * ((bd - 0.15) ** 2 / (0.05 ** 2))
    binder_effect = np.clip(binder_effect, 0.82, 1.05)

    angle_penalty = 0.10 * ((angle - 30.0) / 10.0) ** 2
    angle_penalty = np.clip(angle_penalty, 0.0, 0.20)

    strength = 780.0
    strength = strength + 420.0 * (fv - 0.48) / 0.12
    strength = strength - 900.0 * wav
    strength = strength * binder_effect
    strength = strength * (1.0 - angle_penalty)
    strength = strength - 70.0 * ((thk - 4.5) / 1.5) ** 2

    return np.clip(strength, 600.0, 1200.0)

def predict_cai_strength(arch, proc, defects, impact_energy_J):
    s0 = predict_undamaged_strength(arch)

    vf = defects["void_fraction"]
    rr = defects["resin_rich_index"]
    wa = defects["waviness_amplification"]
    ds = defects["defect_severity"]

    bd = arch[:, 1]
    angle = arch[:, 3]
    n = len(bd)

    impact_severity = impact_energy_J / 40.0

    architecture_toughness = 0.16 + 0.45 * bd - 0.08 * ((angle - 30.0) / 15.0) ** 2
    architecture_toughness = np.clip(architecture_toughness, 0.08, 0.28)

    damage_index = (
        0.22 * impact_severity
        + 1.50 * vf
        + 0.45 * rr
        + 0.70 * wa
        + 0.65 * ds
        - 0.50 * architecture_toughness
        + 0.025 * np.random.randn(n)
    )
    damage_index = np.clip(damage_index, 0.08, 0.60)

    cai_strength = s0 * (1.0 - damage_index)
    cai_strength = np.clip(cai_strength, 380.0, 520.0)

    return cai_strength, damage_index

def predict_fatigue_knockdown(arch, defects, cycles, stress_ratio=0.1):
    bd = arch[:, 1]
    wav = arch[:, 2]
    vf = defects["void_fraction"]
    rr = defects["resin_rich_index"]
    ds = defects["defect_severity"]
    n = len(bd)

    logN = np.log10(cycles)

    knockdown = (
        0.88
        - 0.030 * (logN - 5.0)
        - 0.90 * vf
        - 0.10 * rr
        - 0.45 * wav
        - 0.18 * ds
        + 0.06 * bd
        + 0.03 * stress_ratio
        + 0.01 * np.random.randn(n)
    )
    knockdown = np.clip(knockdown, 0.35, 0.90)

    fatigue_strength = predict_undamaged_strength(arch) * knockdown
    fatigue_strength = np.clip(fatigue_strength, 350.0, 650.0)
    return fatigue_strength, knockdown

# ============================================================
# METRICS
# ============================================================
def certification_metrics(cai_strength, fatigue_strength):
    cai_pass = cai_strength >= CAI_LIMIT
    fatigue_pass = fatigue_strength >= FATIGUE_LIMIT
    return {
        "cai_pass_rate": np.mean(cai_pass),
        "fatigue_pass_rate": np.mean(fatigue_pass),
        "joint_pass_rate": np.mean(cai_pass & fatigue_pass),
    }

def reliability_analysis(cai_strength, fatigue_strength):
    cai_fail = cai_strength < CAI_LIMIT
    fatigue_fail = fatigue_strength < FATIGUE_LIMIT
    joint_fail = cai_fail | fatigue_fail
    return {
        "prob_fail_cai": np.mean(cai_fail),
        "prob_fail_fatigue": np.mean(fatigue_fail),
        "prob_fail_joint": np.mean(joint_fail),
        "reliability_cai": 1.0 - np.mean(cai_fail),
        "reliability_fatigue": 1.0 - np.mean(fatigue_fail),
        "reliability_joint": 1.0 - np.mean(joint_fail),
    }

# ============================================================
# CALIBRATION
# ============================================================
def fit_ridge_regression(X, y, lam=1e-3):
    return np.linalg.solve(X.T @ X + lam * np.eye(X.shape[1]), X.T @ y)

def predict_ridge(X, beta):
    return X @ beta

def synthetic_measured_cai(cai_pred, noise_std=20.0, ymin=380.0, ymax=520.0):
    y = cai_pred + noise_std * np.random.randn(len(cai_pred))
    return np.clip(y, ymin, ymax)

def calibrate_strength_model(arch, proc, measured_cai):
    X = feature_map(arch, proc)
    beta = fit_ridge_regression(X, measured_cai, 1e-2)
    pred = predict_ridge(X, beta)
    pred = np.clip(pred, 380.0, 520.0)
    rmse = np.sqrt(np.mean((pred - measured_cai) ** 2))
    return beta, pred, rmse

# ============================================================
# SENSITIVITY
# ============================================================
def correlation_sensitivity(inputs, y, names):
    ranking = []
    for i, name in enumerate(names):
        corr = np.corrcoef(inputs[:, i], y)[0, 1]
        if np.isnan(corr):
            corr = 0.0
        ranking.append((name, abs(corr), corr))
    ranking.sort(key=lambda t: t[1], reverse=True)
    return ranking

# ============================================================
# MAIN DIGITAL TWIN
# ============================================================
def run_digital_twin(n_samples=3000, impact_energy_J=30.0, cycles=5e5):
    arch = sample_architecture(n_samples)
    proc = sample_process(n_samples)

    defects = predict_defects(arch, proc)
    undamaged_strength = predict_undamaged_strength(arch)
    cai_strength, damage_index = predict_cai_strength(arch, proc, defects, impact_energy_J)
    fatigue_strength, fatigue_knockdown = predict_fatigue_knockdown(arch, defects, cycles)

    cert = certification_metrics(cai_strength, fatigue_strength)

    return {
        "arch": arch,
        "proc": proc,
        "defects": defects,
        "undamaged_strength": undamaged_strength,
        "cai_strength": cai_strength,
        "damage_index": damage_index,
        "fatigue_strength": fatigue_strength,
        "fatigue_knockdown": fatigue_knockdown,
        "certification": cert,
    }

# ============================================================
# EXPORTS
# ============================================================
def export_results_csv(results, filename="simulation_results.csv"):
    path = os.path.join(OUTPUT_DIR, filename)
    with open(path, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow([
            "fiber_volume_fraction", "binder_density", "waviness",
            "braid_angle_deg", "thickness_mm", "compaction_pressure_MPa",
            "resin_flow_rate", "cure_temp_deviation_C", "void_fraction",
            "resin_rich_index", "waviness_amplification", "defect_severity",
            "undamaged_strength_MPa", "damage_index", "CAI_strength_MPa",
            "fatigue_strength_MPa", "fatigue_knockdown"
        ])
        for i in range(len(results["arch"])):
            writer.writerow([
                results["arch"][i, 0], results["arch"][i, 1], results["arch"][i, 2],
                results["arch"][i, 3], results["arch"][i, 4],
                results["proc"][i, 0], results["proc"][i, 1], results["proc"][i, 2],
                results["defects"]["void_fraction"][i],
                results["defects"]["resin_rich_index"][i],
                results["defects"]["waviness_amplification"][i],
                results["defects"]["defect_severity"][i],
                results["undamaged_strength"][i],
                results["damage_index"][i],
                results["cai_strength"][i],
                results["fatigue_strength"][i],
                results["fatigue_knockdown"][i],
            ])
    return path

def export_summary_csv(results, calibration_rmse, sensitivity, reliability, filename="summary_metrics.csv"):
    path = os.path.join(OUTPUT_DIR, filename)
    with open(path, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["Metric", "Value"])
        writer.writerow(["Mean undamaged strength (MPa)", np.mean(results["undamaged_strength"])])
        writer.writerow(["Mean CAI strength (MPa)", np.mean(results["cai_strength"])])
        writer.writerow(["Mean fatigue strength (MPa)", np.mean(results["fatigue_strength"])])
        writer.writerow(["Mean void fraction", np.mean(results["defects"]["void_fraction"])])
        writer.writerow(["CAI pass rate", results["certification"]["cai_pass_rate"]])
        writer.writerow(["Fatigue pass rate", results["certification"]["fatigue_pass_rate"]])
        writer.writerow(["Joint pass rate", results["certification"]["joint_pass_rate"]])
        writer.writerow(["CAI failure probability", reliability["prob_fail_cai"]])
        writer.writerow(["Fatigue failure probability", reliability["prob_fail_fatigue"]])
        writer.writerow(["Joint failure probability", reliability["prob_fail_joint"]])
        writer.writerow(["Calibration RMSE (MPa)", calibration_rmse])
        writer.writerow([])
        writer.writerow(["Sensitivity ranking", "Abs(correlation) / Signed correlation"])
        for name, abs_corr, corr in sensitivity:
            writer.writerow([name, f"{abs_corr:.4f} / {corr:.4f}"])
    return path

# ============================================================
# FIGURES
# ============================================================
def save_scatter_void_vs_cai(results):
    fig = plt.figure(figsize=(7, 5))
    plt.scatter(results["defects"]["void_fraction"], results["cai_strength"], s=20, alpha=0.5)
    plt.xlabel("Void Fraction")
    plt.ylabel("CAI Strength (MPa)")
    plt.title("CAI Strength vs Void Fraction")
    plt.grid(True, alpha=0.3)
    path = os.path.join(OUTPUT_DIR, "figure_void_vs_cai.png")
    plt.tight_layout()
    fig.savefig(path, dpi=300)
    fig.canvas.draw()
    fig.canvas.flush_events()
    return path

def save_scatter_defect_vs_fatigue(results):
    fig = plt.figure(figsize=(7, 5))
    plt.scatter(results["defects"]["defect_severity"], results["fatigue_knockdown"], s=20, alpha=0.5)
    plt.xlabel("Defect Severity")
    plt.ylabel("Fatigue Knockdown Factor")
    plt.title("Fatigue Knockdown vs Defect Severity")
    plt.grid(True, alpha=0.3)
    path = os.path.join(OUTPUT_DIR, "figure_defect_vs_fatigue.png")
    plt.tight_layout()
    fig.savefig(path, dpi=300)
    fig.canvas.draw()
    fig.canvas.flush_events()
    return path

def save_histogram_cai(results):
    fig = plt.figure(figsize=(7, 5))
    plt.hist(results["cai_strength"], bins=30)
    plt.axvline(CAI_LIMIT, linestyle="--", label="CAI Limit")
    plt.xlabel("CAI Strength (MPa)")
    plt.ylabel("Frequency")
    plt.title("Distribution of CAI Strength")
    plt.legend()
    plt.grid(True, alpha=0.3)
    path = os.path.join(OUTPUT_DIR, "figure_cai_histogram.png")
    plt.tight_layout()
    fig.savefig(path, dpi=300)
    fig.canvas.draw()
    fig.canvas.flush_events()
    return path

def save_sensitivity_bar(sensitivity):
    names = [s[0] for s in sensitivity][::-1]
    values = [s[1] for s in sensitivity][::-1]
    fig = plt.figure(figsize=(8, 5))
    plt.barh(names, values)
    plt.xlabel("Absolute Correlation with CAI Strength")
    plt.ylabel("Input Variable")
    plt.title("Sensitivity Ranking")
    plt.grid(True, alpha=0.3)
    path = os.path.join(OUTPUT_DIR, "figure_sensitivity_ranking.png")
    plt.tight_layout()
    fig.savefig(path, dpi=300)
    fig.canvas.draw()
    fig.canvas.flush_events()
    return path

def save_calibration_plot(measured_cai, calibrated_cai):
    fig = plt.figure(figsize=(6, 6))
    plt.scatter(measured_cai, calibrated_cai, s=20, alpha=0.5)
    minv = min(np.min(measured_cai), np.min(calibrated_cai))
    maxv = max(np.max(measured_cai), np.max(calibrated_cai))
    plt.plot([minv, maxv], [minv, maxv], linestyle="--", label="Ideal fit")
    plt.xlabel("Measured CAI (MPa)")
    plt.ylabel("Calibrated Prediction (MPa)")
    plt.title("Calibration Check")
    plt.legend()
    plt.grid(True, alpha=0.3)
    path = os.path.join(OUTPUT_DIR, "figure_calibration_check.png")
    plt.tight_layout()
    fig.savefig(path, dpi=300)
    fig.canvas.draw()
    fig.canvas.flush_events()
    return path

def save_reliability_histogram(results):
    fig = plt.figure(figsize=(7, 5))
    plt.hist(results["cai_strength"], bins=35)
    plt.axvline(CAI_LIMIT, linestyle="--", label="Certification Limit")
    plt.xlabel("CAI Strength (MPa)")
    plt.ylabel("Frequency")
    plt.title("Reliability Distribution of CAI Strength")
    plt.legend()
    plt.grid(True, alpha=0.3)
    path = os.path.join(OUTPUT_DIR, "figure_reliability_distribution.png")
    plt.tight_layout()
    fig.savefig(path, dpi=300)
    fig.canvas.draw()
    fig.canvas.flush_events()
    return path

# ============================================================
# SUMMARY
# ============================================================
def print_summary(results, calibration_rmse, sensitivity, reliability):
    print("\n=============================================================")
    print("LITERATURE-CALIBRATED DIGITAL TWIN SUMMARY")
    print("=============================================================")
    print(f"Undamaged Strength (MPa): {mean_std_text(results['undamaged_strength'])}")
    print(f"CAI Strength (MPa):       {mean_std_text(results['cai_strength'])}")
    print(f"Fatigue Strength (MPa):   {mean_std_text(results['fatigue_strength'])}")
    print(f"Void Fraction:            {mean_std_text(results['defects']['void_fraction'])}")

    print("\nCertification-style metrics")
    print("-------------------------------------------------------------")
    print(f"CAI pass rate:      {100 * results['certification']['cai_pass_rate']:.2f}%")
    print(f"Fatigue pass rate:  {100 * results['certification']['fatigue_pass_rate']:.2f}%")
    print(f"Joint pass rate:    {100 * results['certification']['joint_pass_rate']:.2f}%")

    print("\nReliability metrics")
    print("-------------------------------------------------------------")
    print(f"CAI failure probability:      {100 * reliability['prob_fail_cai']:.2f}%")
    print(f"Fatigue failure probability:  {100 * reliability['prob_fail_fatigue']:.2f}%")
    print(f"Joint failure probability:    {100 * reliability['prob_fail_joint']:.2f}%")

    print("\nCalibration")
    print("-------------------------------------------------------------")
    print(f"Calibration RMSE: {calibration_rmse:.2f} MPa")

    print("\nSensitivity ranking to CAI strength")
    print("-------------------------------------------------------------")
    for name, abs_corr, corr in sensitivity:
        print(f"{name:28s} abs(corr)={abs_corr:.3f} corr={corr:.3f}")

# ============================================================
# MAIN
# ============================================================
if __name__ == "__main__":
    n_samples = 3000
    impact_energy_J = 30.0
    cycles = 5e5

    results = run_digital_twin(n_samples, impact_energy_J, cycles)

    measured_cai = synthetic_measured_cai(results["cai_strength"], 20.0, 380.0, 520.0)
    beta, calibrated_cai, calibration_rmse = calibrate_strength_model(results["arch"], results["proc"], measured_cai)

    input_names = [
        "fiber_volume_fraction", "binder_density", "waviness",
        "braid_angle_deg", "thickness_mm", "compaction_pressure_MPa",
        "resin_flow_rate", "cure_temp_deviation_C"
    ]
    full_inputs = np.column_stack([results["arch"], results["proc"]])
    sensitivity = correlation_sensitivity(full_inputs, results["cai_strength"], input_names)

    reliability = reliability_analysis(results["cai_strength"], results["fatigue_strength"])

    print_summary(results, calibration_rmse, sensitivity, reliability)

    csv1 = export_results_csv(results)
    csv2 = export_summary_csv(results, calibration_rmse, sensitivity, reliability)

    fig1 = save_scatter_void_vs_cai(results)
    fig2 = save_scatter_defect_vs_fatigue(results)
    fig3 = save_histogram_cai(results)
    fig4 = save_sensitivity_bar(sensitivity)
    fig5 = save_calibration_plot(measured_cai, calibrated_cai)
    fig6 = save_reliability_histogram(results)

    print("\nSaved outputs")
    print("-------------------------------------------------------------")
    for p in [csv1, csv2, fig1, fig2, fig3, fig4, fig5, fig6]:
        print(p)

    print("\nAll figures generated and saved.")
    plt.show(block=True)
