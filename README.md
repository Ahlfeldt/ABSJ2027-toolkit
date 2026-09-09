# Toolkit for The Skyscraper Revolution

Gabriel M. Ahlfeldt, Nathaniel Baum-Snow, and Rémi Jedwab

Development version, September 2026

**General instructions**

This toolkit accompanies *The Skyscraper Revolution*. It provides compact MATLAB and Python implementations of the paper's city model for teaching, exploration, and counterfactual analysis. Users specify parameters and empirical moments, quantify a baseline city, and evaluate changes in productivity, amenities, construction costs, height constraints, and urban growth boundaries. The Python version mirrors the MATLAB structure and equations, with separate function files and two simple Spyder-compatible master scripts.

The toolkit shows height / floor area ratio (FAR), floor space rent, and land rent gradients together with land-use boundaries. It also reports population, wages, GDP (model output), total urban area, floor space, commuting disamenity, the density disamenity index, utility, and other aggregate outcomes. Counterfactual tables show both scenarios and percentage changes.

Start with the **[illustrated showcase](SHOWCASE/README.md)** to see example experiments, figures, and downloadable tables. The **[codebook](documentation/CODEBOOK.pdf)** explains the equilibrium conditions, inversion, and numerical algorithms, including pseudocode for the optional empirical calibration.

**Citation requirement**

Use of this toolkit is subject to citing Ahlfeldt, Baum-Snow, and Jedwab, *The Skyscraper Revolution: Global Economic Development and Land Savings*. *The Review of Economic Studies*, forthcoming.

**How this toolkit differs from related toolkits**

This toolkit complements two earlier urban-model toolkits while addressing a different set of questions:

| Toolkit | Main focus | City openness and spatial structure |
|:--|:--|:--|
| **ABSJ2027 (this toolkit)** | The joint effects of vertical construction, height constraints, and horizontal urban growth boundaries. It models commercial and residential land use, endogenous building height / FAR, and lets users invert the model to population, urbanization, wages, residential floor-space outcomes, total urban area, and CBD FAR. | A stylized radial city that is **imperfectly open**: migration links urban population to urban utility relative to the hinterland, so both population and welfare can adjust after a change. |
| [AB2022 toolkit](https://github.com/Ahlfeldt/AB2022-toolkit) | A compact Stata implementation of the stylized skyscraper model in Ahlfeldt and Barr (2022), with accessible height, floor-space-rent, and land-rent gradients. | A stylized monocentric city focused on the economics of building height. |
| [ARSW2015 toolkit](https://github.com/Ahlfeldt/ARSW2015-toolkit) | A detailed MATLAB toolkit for the quantitative Berlin model in Ahlfeldt, Redding, Sturm, and Wolf (2015), including observed micro-geography, commuting links, local productivity and amenities, agglomeration forces, and spatial counterfactuals. | A many-location empirical city model with closed-city and open-city counterfactuals. |

ABSJ2027 therefore sits between the compact illustrative model in AB2022 and the high-dimensional empirical model in ARSW2015. It retains a transparent one-dimensional city structure while adding imperfect openness, two land uses, endogenous city boundaries, vertical and horizontal constraints, and optional moment-based calibration.

**Requirements and getting started**

Download or clone this repository, open one of the master scripts below in MATLAB, and run the entire script. No replication directory or external data are required. The toolkit has been tested with MATLAB R2024a Update 2 and requires the Statistics and Machine Learning Toolbox for inherited `nansum` calls. Optimization uses MATLAB's `fminsearch`.

For Python, open either `.py` master in Spyder and choose **Run file**. Both masters use Spyder `# %%` cells and locate the toolkit independently of the current working directory. The Python version uses NumPy, SciPy, pandas, Matplotlib, and openpyxl; see [Python/requirements.txt](Python/requirements.txt).

| Script | Description |
|:--|:--|
| [MASTER_PAPER.m](MATLAB/scripts/MASTER_PAPER.m) | Uses the paper's structural parameters. Matches urban population and the urbanization rate, with optional height-gap inversion. The example compares an unrestricted city with joint vertical and horizontal constraints. |
| [MASTER_EMPIRICAL.m](MATLAB/scripts/MASTER_EMPIRICAL.m) | Starts from the paper's parameters and adds empirical targets: annual wage 75,000 USD, residential rent 240 USD/m²/year, geographic urban area equivalent to an 18 km radius, and central CBD FAR 10. |
| [MASTER_PAPER.py](Python/scripts/MASTER_PAPER.py) | Python/Spyder version of the paper-parameterization example. |
| [MASTER_EMPIRICAL.py](Python/scripts/MASTER_EMPIRICAL.py) | Python/Spyder version of the empirically quantified example. |

> **Runtime note:** The empirical master scripts can take noticeably longer than
> the paper-parameterization scripts. The empirical city is obtained through a
> higher-dimensional numerical inversion: each candidate set of construction
> costs, agricultural rent, and spatial decay parameters requires another full
> equilibrium solution. Runtime therefore depends on the selected targets, grid
> resolution, starting values, and computer.

MASTER_PAPER.m does not calibrate a physical spatial scale. Its distance, land area, floor space, density, and rent denominators are therefore reported in model units. MASTER_EMPIRICAL.m uses the total-urban-area target to identify kilometres and square kilometres; this also permits floor-space quantities and rents to be expressed per square metre. Its wage target separately identifies annual currency units.

Each main script has three input sections: baseline parameters, empirical targets, and optional counterfactual changes. For example:

```matlab
changes = struct();
changes.pct.a_bar_C = 10;  % Raise commercial productivity by 10 percent.
changes.set.S_bar_C = 10; % Set a commercial height / FAR limit of 10.
changes.set.x1_max = 20;  % Set an urban growth boundary at 20 km.
```

For baseline-only results, leave `changes = struct()` and comment out all subsequent `changes.set` and `changes.pct` assignments. The empirical inversion can take several minutes; progress messages identify the current operation and target fit.

**Empirical inversion**

Both examples target urban population and the urbanization rate, defined as the urban share of city plus hinterland population. The empirical example adds the following optional moments. Physical housing quantities and rents require a total-urban-area target to identify the spatial scale:

| Target | Adjustment |
|:--|:--|
| Annual wage | Sets the currency conversion for monetary outcomes in both scenarios. |
| Residential floor space per resident **or** average residential floor space rent | Scales both residential and commercial construction-cost primitives by a common multiplier. Rent targeting also requires an annual wage target. |
| Total geographic urban area | Adjusts agricultural land rent. Geographic area includes non-developable land; developable area is reported separately. |
| Central CBD FAR | Scales both spatial decay parameters, `tau_R` and `tau_C`, by a common multiplier, preserving their ratio. |

The optional primitives are fitted jointly, with population and urbanization inverted within each evaluation. These extra moments and urban growth boundaries extend the experiments used in the paper.

Height-gap calibration should be used only under the paper parameterization because the threshold `T` is specific to that parameterization. Enter the gap as a share: `0.5` means 50%. Any finite manually specified height / FAR limit supersedes the gap target. Under empirical calibration, leave `targets.height_gap = []`; the resulting height gap is still reported as a descriptive outcome.

**Folders and outputs**

| Folder | Contents |
|:--|:--|
| [MATLAB/scripts](MATLAB/scripts) | User-facing paper and empirical examples. |
| [MATLAB/functions](MATLAB/functions) | City creation, inversion, equilibrium solution, counterfactuals, graphs, tables, and validation functions. |
| [SHOWCASE](SHOWCASE/README.md) | Illustrated walkthrough and saved example figures and tables. |
| [documentation](documentation) | PDF and editable LaTeX codebook, build instructions, source map, and validation notes. |
| [data](data/README.md) | Reserved for the future machine-readable city simulation results. |
| [Python/scripts](Python/scripts) | Spyder-compatible paper and empirical master scripts. |
| [Python/functions](Python/functions) | Python counterparts to the MATLAB model, inversion, reporting, and export functions. |

Running a master script creates `MATLAB/outputs/Paper` or `MATLAB/outputs/Empirical`. Each contains `Figures` (PNG and vector PDF), `Tables` (CSV, XLSX, and LaTeX), and `results.mat`. The latest full run is also mirrored directly under `MATLAB/outputs`. Generated run outputs are ignored by Git; the curated showcase examples are included in the repository.

The Python masters create the same output layout under `Python/outputs`, with complete results saved as `results.pkl`. Generated Python outputs are also ignored by Git.

**Documentation and further development**

- [Codebook PDF](documentation/CODEBOOK.pdf) and [LaTeX source](documentation/CODEBOOK.tex).
- [Codebook build instructions](documentation/BUILD_CODEBOOK.md).
- [Source map](documentation/SOURCE_MAP.md) and [validation notes](documentation/VALIDATION.md).

The working release includes MATLAB and Python single-city toolkits. A web frontend and an accessible dataset and explorer covering the paper's nearly 13,000 cities are planned. The city dataset is not yet included; once released here, web interfaces will be able to read its machine-readable files from GitHub.
