# Lifecycle Digital Twin Framework for 3D Woven and Braided Composites

A simulation-based framework linking textile architecture, manufacturing defects, and structural performance of advanced composite materials.

---

## Overview

This repository contains the simulation code used in the research study:

**Shadat Hossen Mahin (2026)**
*Lifecycle Digital Twin Framework for 3D Woven and Braided Composites: Linking Textile Architecture, Manufacturing Defects, and Structural Performance.*

The framework models how **textile architecture and manufacturing variability influence defect formation and structural performance** in aerospace composite materials.

The simulation integrates:

* Textile architecture modelling
* Manufacturing process modelling
* Defect prediction
* Structural performance prediction
* Monte Carlo uncertainty propagation
* Sensitivity analysis
* Reliability analysis

The repository allows researchers to reproduce the simulation workflow and regenerate the figures and datasets used in the study.

---

## Digital Twin Workflow

The framework consists of four main modules:

### 1. Textile Architecture Model

Parameters describing composite architecture:

* Fiber volume fraction
* Binder yarn density
* Fiber waviness
* Braid angle
* Laminate thickness

These parameters represent structural variability in 3D woven composites.

---

### 2. Manufacturing Process Model

Process parameters representing manufacturing conditions:

* Compaction pressure
* Resin flow rate
* Cure temperature deviation

These variables influence the formation of defects during composite manufacturing.

---

### 3. Defect Prediction Model

The framework predicts several types of defects:

* Void fraction
* Resin-rich regions
* Fiber waviness amplification
* Overall defect severity index

These defects significantly influence structural performance.

---

### 4. Structural Performance Model

Structural properties predicted by the model include:

* Undamaged compressive strength
* Compression-After-Impact (CAI) strength
* Fatigue strength

These predictions allow evaluation of composite performance and reliability.

---

## Monte Carlo Simulation

Uncertainty in architecture and manufacturing parameters is propagated using **Monte Carlo simulation**.

The simulation typically runs **3000 samples** to estimate statistical distributions of predicted properties.

---

## Repository Structure

```
Composite-project
│
├── digital_twin_simulation.py
├── README.md
├── requirements.txt
├── LICENSE
│
├── figures/
│
├── data/
│
├── tables/
│
├── validation/
│
└── example_results/
```

---

## Requirements

The simulation requires **Python 3.9 or newer**.

Install required packages using:

```
pip install -r requirements.txt
```

Main dependencies:

* numpy
* scipy
* matplotlib
* tabulate

---

## Running the Simulation

Run the simulation using:

```
python digital_twin_simulation.py
```

The script will automatically:

1. Generate architecture parameters
2. Generate manufacturing parameters
3. Predict manufacturing defects
4. Predict structural performance
5. Perform sensitivity analysis
6. Perform reliability analysis
7. Generate figures and tables

---

## Output

The simulation produces several outputs.

### Figures

* Void fraction vs CAI strength
* Defect severity vs fatigue knockdown
* CAI strength distribution
* Sensitivity ranking of parameters
* Reliability distribution

### Data Files

CSV and JSON files containing:

* simulation results
* summary statistics
* sensitivity analysis results
* validation metrics

### Tables

Publication-ready tables for journal manuscripts.

---

## Reproducibility

The code in this repository enables reproduction of the simulation workflow described in the associated research study.

All figures and datasets can be regenerated using the provided scripts and default parameters.

---

## Citation

If you use this code in your research, please cite:

Mahin, S. H. (2026).
*Lifecycle Digital Twin Framework for 3D Woven and Braided Composites: Linking Textile Architecture, Manufacturing Defects, and Structural Performance.*

GitHub repository:
https://github.com/shadatmahin17/Composite-project

---

## License

This project is released under the MIT License.

---

## Author

**Shadat Hossen Mahin**
Department of Textile Engineering
Research Area: Aerospace Composite Structures
2026
# Lifecycle Digital Twin Framework for 3D Woven and Braided Composites

A simulation-based framework linking textile architecture, manufacturing defects, and structural performance of advanced composite materials.

---

## Overview

This repository contains the simulation code used in the research study:

**Shadat Hossen Mahin (2026)**
*Lifecycle Digital Twin Framework for 3D Woven and Braided Composites: Linking Textile Architecture, Manufacturing Defects, and Structural Performance.*

The framework models how **textile architecture and manufacturing variability influence defect formation and structural performance** in aerospace composite materials.

The simulation integrates:

* Textile architecture modelling
* Manufacturing process modelling
* Defect prediction
* Structural performance prediction
* Monte Carlo uncertainty propagation
* Sensitivity analysis
* Reliability analysis

The repository allows researchers to reproduce the simulation workflow and regenerate the figures and datasets used in the study.

---

## Digital Twin Workflow

The framework consists of four main modules:

### 1. Textile Architecture Model

Parameters describing composite architecture:

* Fiber volume fraction
* Binder yarn density
* Fiber waviness
* Braid angle
* Laminate thickness

These parameters represent structural variability in 3D woven composites.

---

### 2. Manufacturing Process Model

Process parameters representing manufacturing conditions:

* Compaction pressure
* Resin flow rate
* Cure temperature deviation

These variables influence the formation of defects during composite manufacturing.

---

### 3. Defect Prediction Model

The framework predicts several types of defects:

* Void fraction
* Resin-rich regions
* Fiber waviness amplification
* Overall defect severity index

These defects significantly influence structural performance.

---

### 4. Structural Performance Model

Structural properties predicted by the model include:

* Undamaged compressive strength
* Compression-After-Impact (CAI) strength
* Fatigue strength

These predictions allow evaluation of composite performance and reliability.

---

## Monte Carlo Simulation

Uncertainty in architecture and manufacturing parameters is propagated using **Monte Carlo simulation**.

The simulation typically runs **3000 samples** to estimate statistical distributions of predicted properties.

---

## Repository Structure

```
Composite-project
│
├── digital_twin_simulation.py
├── README.md
├── requirements.txt
├── LICENSE
│
├── figures/
│
├── data/
│
├── tables/
│
├── validation/
│
└── example_results/
```

---

## Requirements

The simulation requires **Python 3.9 or newer**.

Install required packages using:

```
pip install -r requirements.txt
```

Main dependencies:

* numpy
* scipy
* matplotlib
* tabulate

---

## Running the Simulation

Run the simulation using:

```
python digital_twin_simulation.py
```

The script will automatically:

1. Generate architecture parameters
2. Generate manufacturing parameters
3. Predict manufacturing defects
4. Predict structural performance
5. Perform sensitivity analysis
6. Perform reliability analysis
7. Generate figures and tables

---

## Output

The simulation produces several outputs.

### Figures

* Void fraction vs CAI strength
* Defect severity vs fatigue knockdown
* CAI strength distribution
* Sensitivity ranking of parameters
* Reliability distribution

### Data Files

CSV and JSON files containing:

* simulation results
* summary statistics
* sensitivity analysis results
* validation metrics

### Tables

Publication-ready tables for journal manuscripts.

---

## Reproducibility

The code in this repository enables reproduction of the simulation workflow described in the associated research study.

All figures and datasets can be regenerated using the provided scripts and default parameters.

---

## Citation

If you use this code in your research, please cite:

Mahin, S. H. (2026).
*Lifecycle Digital Twin Framework for 3D Woven and Braided Composites: Linking Textile Architecture, Manufacturing Defects, and Structural Performance.*

GitHub repository:
https://github.com/shadatmahin17/Composite-project

---

## License

This project is released under the MIT License.

---

## Author

**Shadat Hossen Mahin**
Department of Textile Engineering
Research Area: Aerospace Composite Structures
2026
# Lifecycle Digital Twin Framework for 3D Woven and Braided Composites

Simulation framework linking textile architecture, manufacturing defects, and structural performance of advanced composite materials.

---

## Overview

This repository contains the simulation code used in the research study:

**Mahin, S. H. (2026)**
*Lifecycle Digital Twin Framework for 3D Woven and Braided Composites: Linking Textile Architecture, Manufacturing Defects, and Structural Performance.*

The framework models the interaction between:

* Textile architecture parameters
* Manufacturing process variability
* Defect formation mechanisms
* Structural performance of composite materials

The simulation uses **Monte Carlo uncertainty propagation** and **reduced-order empirical models informed by literature** to estimate the reliability and performance of 3D woven composite structures.

The repository allows researchers to reproduce the simulation workflow and regenerate all figures and datasets used in the study.

---

## Digital Twin Workflow

The framework integrates multiple modelling modules:

1. **Textile Architecture Model**

   * Fiber volume fraction
   * Binder yarn density
   * Fiber waviness
   * Braid angle
   * Laminate thickness

2. **Manufacturing Process Model**

   * Compaction pressure
   * Resin flow rate
   * Cure temperature deviation

3. **Defect Prediction Model**

   * Void fraction
   * Resin-rich regions
   * Fiber waviness amplification
   * Overall defect severity index

4. **Structural Performance Model**

   * Undamaged compressive strength
   * Compression-After-Impact (CAI) strength
   * Fatigue strength prediction

5. **Analysis Modules**

   * Monte Carlo uncertainty propagation
   * Sensitivity analysis
   * Reliability analysis
   * Validation against literature benchmarks

---

## Repository Structure

```
digital-twin-3d-composites
│
├── digital_twin_simulation.py
├── README.md
├── requirements.txt
├── LICENSE
│
├── digital_twin_journal_results/
│   ├── figures/
│   ├── data/
│   ├── tables/
│   └── validation/
│
└── example_outputs/
```

---

## Requirements

Python 3.9 or newer is recommended.

Required libraries:

* numpy
* scipy
* matplotlib

Install dependencies using:

```bash
pip install numpy scipy matplotlib
```

---

## Running the Simulation

To run the full digital twin simulation:

```bash
python digital_twin_simulation.py
```

The simulation will:

1. Generate architecture and manufacturing parameters
2. Predict manufacturing defects
3. Estimate structural performance
4. Perform sensitivity analysis
5. Perform reliability analysis
6. Validate predictions against literature benchmarks

---

## Output

After running the simulation, the following outputs are generated automatically:

### Figures

* Void fraction vs CAI strength
* Defect severity vs fatigue knockdown
* CAI strength distribution
* Sensitivity ranking of parameters
* Reliability distribution

### Data Files

CSV and JSON files containing:

* simulation results
* summary statistics
* sensitivity analysis results
* validation metrics

### LaTeX Tables

Publication-ready tables are exported for use in journal manuscripts.

---

## Reproducibility

The code in this repository reproduces the simulation workflow presented in the associated research study.

All figures and datasets presented in the manuscript can be regenerated using the provided scripts and default simulation parameters.

---

## Citation

If you use this code in your research, please cite:

Mahin, S. H. (2026).
*Lifecycle Digital Twin Framework for 3D Woven and Braided Composites: Linking Textile Architecture, Manufacturing Defects, and Structural Performance.*

GitHub repository:
https://github.com/shadatmahin17/Composite

---

## License

This project is released under the MIT License.

---

## Author

**Shadat Hossen Mahin**
Department of Textile Engineering
Research Area: Aerospace Composite Structures
2026

---
