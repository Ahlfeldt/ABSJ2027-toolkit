# Toolkit for The Skyscraper Revolution

Gabriel M. Ahlfeldt, Nathaniel Baum-Snow, and Rémi Jedwab

Development version, September 2026

**General instructions**

This toolkit accompanies *The Skyscraper Revolution*. It provides a compact MATLAB implementation of the paper's city model for teaching, exploration, and counterfactual analysis. Users specify parameters and empirical moments, quantify a baseline city, and evaluate changes in productivity, amenities, construction costs, height constraints, and urban growth boundaries. The toolkit stays close to the paper's MATLAB functions, with separate, commented function files and simple master scripts.

The toolkit shows height / floor area ratio (FAR), floor space rent, and land rent gradients together with land-use boundaries. It also reports population, wages, GDP (model output), total urban area, floor space, commuting disamenity, the density disamenity index, utility, and other aggregate outcomes. Counterfactual tables show both scenarios and percentage changes.

Start with the **[illustrated showcase](SHOWCASE/README.md)** to see example experiments, figures, and downloadable tables. The **[codebook](documentation/CODEBOOK.pdf)** explains the equilibrium conditions, inversion, and numerical algorithms, including pseudocode for the optional empirical calibration.

When using this toolkit in your work, please cite Ahlfeldt, Baum-Snow, and Jedwab, *The Skyscraper Revolution*.

**Requirements and getting started**

Download or clone this repository, open one of the master scripts below in MATLAB, and run the entire script. No replication directory or external data are required. The toolkit has been tested with MATLAB R2024a Update 2 and requires the Statistics and Machine Learning Toolbox for inherited `nansum` calls. Optimization uses MATLAB's `fminsearch`.

| Script | Description |
|:--|:--|
| [MASTER_PAPER.m](MATLAB/scripts/MASTER_PAPER.m) | Uses the paper's structural parameters. Matches urban population and the urbanization rate, with optional height-gap inversion. The example compares an unrestricted city with joint vertical and horizontal constraints. |
| [MASTER_EMPIRICAL.m](MATLAB/scripts/MASTER_EMPIRICAL.m) | Starts from the paper's parameters and adds empirical targets: annual wage 75,000 USD, residential rent 240 USD/m²/year, geographic urban area equivalent to an 18 km radius, and central CBD FAR 10. |
| [MASTER.m](MATLAB/scripts/MASTER.m) | Compatibility entry point that runs the paper example. Edit `MASTER_PAPER.m` to change its inputs. |

Each main script has three input sections: baseline parameters, empirical targets, and optional counterfactual changes. For example:

```matlab
changes = struct();
changes.pct.a_bar_C = 10;  % Raise commercial productivity by 10 percent.
changes.set.S_bar_C = 10; % Set a commercial height / FAR limit of 10.
changes.set.x1_max = 20;  % Set an urban growth boundary at 20 km.
```

For baseline-only results, leave `changes = struct()` and comment out all subsequent `changes.set` and `changes.pct` assignments. The empirical inversion can take several minutes; progress messages identify the current operation and target fit.

**Empirical inversion**

Both examples target urban population and the urbanization rate, defined as the urban share of city plus hinterland population. The empirical example adds the following optional moments:

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
| [Python](Python/README.md) | Reserved for a future Python implementation, with separate `functions` and `scripts` folders. |

Running a master script creates `MATLAB/outputs/Paper` or `MATLAB/outputs/Empirical`. Each contains `Figures` (PNG and vector PDF), `Tables` (CSV, XLSX, and LaTeX), and `results.mat`. The latest full run is also mirrored directly under `MATLAB/outputs`. Generated run outputs are ignored by Git; the curated showcase examples are included in the repository.

**Documentation and further development**

- [Codebook PDF](documentation/CODEBOOK.pdf) and [LaTeX source](documentation/CODEBOOK.tex).
- [Codebook build instructions](documentation/BUILD_CODEBOOK.md).
- [Source map](documentation/SOURCE_MAP.md) and [validation notes](documentation/VALIDATION.md).

The working release is the MATLAB single-city toolkit. A Python implementation, web frontend, and an accessible dataset and explorer covering the paper's nearly 13,000 cities are planned. The city dataset is not yet included; once released here, web interfaces will be able to read its machine-readable files from GitHub.
