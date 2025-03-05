# DME-production-optimization
This repository contains a GAMS model which aims to optimize a process for producing dimethyl ether (DME) through the dehydration of methanol. The goal is to maximize the economic potential by optimizing design variables such as residence time and distillation recoveries within the constraints of process costs and purity targets.

The model applies:
- Reaction kinetics based on experimentally derived data.
- Mass balances across a reactor and two distillation columns.
- Economic potential calculation considering material costs and unit costs.
- A parametric sweep over residence time to identify the optimal operating point.

---
 
## Theoretical Background

### Dimethyl Ether Production Process

Dimethyl ether (DME) is a valuable chemical with wide applications as a fuel, refrigerant, and feedstock for further chemical synthesis. It is commonly produced via the **dehydration of methanol** according to the reaction:

```2 CH_3OH -> CH_3OCH_3 + H_2O```

This reversible reaction is typically performed in the **vapor phase** over a catalyst at elevated temperatures (around 600 K) and is limited by chemical equilibrium and operational constraints. Key challenges in DME production include maximizing conversion and product purity while minimizing operating and capital costs.

### Process Design and Optimization

A typical DME production process consists of:

- **Feed preparation**: Supplying methanol with high purity.
- **Reactor section**: Converting methanol to DME and water at optimal residence time and temperature.
- **Separation system**: Employing distillation columns to purify DME and recycle unreacted methanol.
- **Recycle loop**: Returning unreacted methanol to the reactor to improve overall efficiency.
- **Utilities and heat integration**: Managing heat duties to minimize energy consumption.
![12_Flowsheet](https://github.com/user-attachments/assets/919a3b73-0223-4ae7-948d-91f1a0f13a53)
### Economic Potential

The goal of the optimization is to maximize the **economic potential (EP)** of the process, defined as:

```EP = Product Value - Raw Material Costs - Operating Costs```

Design variables such as **residence time**, **distillation recoveries**, and **temperatures** directly influence both the conversion and the cost structure of the process.
This model provides a systematic way to evaluate trade-offs and determine the most profitable design parameters.

---

## Code Description

The GAMS model implements a complete process simulation and optimization, including:

### Model Structure

- **Components and Streams**: Defined using sets to represent methanol, water, DME, and all process streams (feed, reactor effluent, distillation products).
- **Reaction Kinetics**: A logarithmic relation between residence time and methanol conversion is applied to model reactor performance.
- **Mass Balances**: Enforced across the reactor and two sequential distillation columns with semi-sharp separations.
- **Economic Calculations**:
  - Raw material and product values based on flow rates and unit prices.
  - Operating costs from reactor and distillation unit cost correlations.
  - Economic potential as the objective function to be maximized.

### Optimization Strategy

- **Residence Time (t)**: Scanned across a defined range (0.6 to 2.5 seconds).
- **Distillation Recoveries (r₁, r₂)**: Treated as decision variables, optimized within feasible bounds (0.9 to 0.998).
- **Fixed Parameters**: Distillation temperatures are fixed to maximize relative volatilities and minimize costs.

### Output

The model writes key results into an output file, including:
- Optimal residence time (2.5)
- Conversion (0.902)
- Optimal distillation recoveries (0.972 and 0.929)
- Maximum economic potential from product (DME) stream
  
  <img width="700" alt="14_streamtable" src="https://github.com/user-attachments/assets/6faca45b-7269-4270-9c21-80a69d367b98" />

---

## How to Use the Code

### 1️⃣ Prerequisites
- **GAMS installation** (https://www.gams.com/download/).

### 2️⃣ Running the Model
1. Open `CENG0013_ProjectGAMS_GVLD8.gms` in GAMS.
2. Execute the file (`Run` button or `F9`).
3. The model automatically loops over residence times, optimizing recoveries for each case.
4. Results are saved in:
   - **GAMS listing file (`.lst`)**: For detailed solution output.
   - **Project.txt**: Tabulated data for further analysis (e.g., plotting in Excel or Python).

### 3️⃣ Analyzing Results
- Plot **Economic Potential vs. Residence Time** to identify the optimal operating point.
- Review optimal recoveries and assess the trade-offs between recovery, conversion, and cost.
- Use the data to inform further process design steps or validation with process simulators (e.g., Aspen Plus).
