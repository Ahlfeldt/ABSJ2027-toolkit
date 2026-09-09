"""Create the aggregate table and three spatial-profile figures."""
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from report_city import report_city
from report_units import report_units


def results(baseline, counterfactual=None, make_graphs=True):
    units = report_units(baseline); base = report_city(baseline, units)
    fields = ["N","urban_share","GDP","wage_bill","y","total_urban_area","AREA","density","x0","x1","F_C","F_R","F","p_R","p_C","CC","commuting_income_loss","DD","HA","U_bar","V","LV","floor_space_per_resident","housing_expenditure","height_gap_pct"]
    labels = ["Urban population","Urbanization rate","GDP","Wage bill","Average annual wage" if units["annual"] else "Wage","Total urban area","Developable urban area","Population density","CBD boundary","Urban fringe","Commercial floor space","Residential floor space","Total floor space","Average residential rent","Average commercial rent","Commuting disamenity index","Commuting disamenity: income loss per resident","Density amenity index","Height amenity index","Urban utility","Regional expected welfare","Aggregate regional land rent","Residential floor space per resident","Housing expenditure per resident","Height gap (relative to T)"]
    u = ["people","fraction",units["flow"],units["flow"],units["flow"]+" / worker",units["area"],units["area"],units["density"],units["distance"],units["distance"],units["floor_area"],units["floor_area"],units["floor_area"],units["rent"],units["rent"],"index",units["flow"]+" / resident","index","index","utility units","utility units",units["flow"],units["floor_per_resident"],units["flow"]+" / resident","%"]
    frame = pd.DataFrame({"Metric": labels, "Unit": u, "Baseline": [base["scalist"][f] for f in fields]})
    if counterfactual is not None:
        cf = report_city(counterfactual, units); values = np.array([cf["scalist"][f] for f in fields], float); baseline_values = frame["Baseline"].to_numpy(float)
        frame["Counterfactual"] = values
        change = np.full(values.shape, np.nan); valid=np.isfinite(baseline_values) & (baseline_values != 0)
        change[valid] = 100*(values[valid]/baseline_values[valid]-1); frame["Change_pct"] = change
    print(frame.to_string(index=False))
    figures = _figures(baseline, counterfactual, units) if make_graphs else []
    if figures:
        # Explicit display is needed when Spyder runs this as a script. With
        # Spyder's Inline backend, the figures are sent to the Plots pane;
        # nonblocking display also keeps external-window backends responsive.
        plt.show(block=False)
    return frame, figures


def _figures(base, cf, units):
    cities = [base] + ([] if cf is None else [cf])
    labels = ["Baseline"] + ([] if cf is None else ["Counterfactual"])
    # Match MATLAB's Okabe-Ito mapping: commercial vermillion, residential blue.
    colors = ("#D55E00", "#0072B2")
    light_colors = ("#E8BBA6", "#A6CDE2", "#D9D9D9")
    outer = max(city["scalist"]["x1"] for city in cities)
    nearby = [city["params"]["x1_max"] for city in cities
              if np.isfinite(city["params"]["x1_max"]) and city["params"]["x1_max"] <= 1.5*outer]
    if nearby: outer = max([outer]+nearby)
    xmax = min(np.max(base["fund"]["D"]), max(2., 1.15*outer))
    specs = [("Building height", "Effective floors", "S_x_C", "S_x_R"),
             ("Floor-space rent", units["rent"], "p_bar_x_C", "p_bar_x_R"),
             ("Land rent", units["rent"], "r_x_C", "r_x_R")]
    figs=[]
    for heading, ylabel, commercial, residential in specs:
        fig = plt.figure(figsize=(10.5, 6.5))
        grid = fig.add_gridspec(4, 1, hspace=.12)
        ax = fig.add_subplot(grid[:3, 0]); land = fig.add_subplot(grid[3, 0], sharex=ax)
        for j, city in enumerate(cities):
            shown = report_city(city, units); d = city["fund"]["D"]
            style = "-" if j == 0 else "--"
            ax.plot(d, shown["varlist"][commercial], style, color=colors[0], linewidth=1.8,
                    label=f"Commercial - {labels[j]}")
            ax.plot(d, shown["varlist"][residential], style, color=colors[1], linewidth=1.8,
                    label=f"Residential - {labels[j]}")
            if commercial == "r_x_C":
                ax.plot([0, xmax], [shown["params"]["r_a"]]*2, style, color="#666666", linewidth=1.2,
                        label=f"Agricultural - {labels[j]}")
        ax.set_title(heading, fontsize=17, fontweight="normal")
        ax.set_ylabel(ylabel); ax.set_xlim(0, xmax); ax.set_ylim(bottom=0)
        ax.grid(True, linestyle=":", color="#595959", alpha=.35)
        ax.spines[["top", "right"]].set_visible(False); ax.legend(loc="upper right", frameon=False, fontsize=9)
        ax.tick_params(labelbottom=False)

        # MATLAB-style land-use bars: commercial, residential, then agriculture.
        for j, city in enumerate(cities):
            row = len(cities)-j
            edges = [0., city["scalist"]["x0"], city["scalist"]["x1"], xmax]
            for zone, color in enumerate(light_colors):
                width = max(0., min(edges[zone+1], xmax)-min(edges[zone], xmax))
                if width > 0:
                    land.barh(row, width, left=edges[zone], height=.44, color=color, edgecolor="none")
            land.text(city["scalist"]["x0"], row+.28, f"CBD {city['scalist']['x0']:.2f}",
                      fontsize=8, ha="center", va="bottom")
            land.text(city["scalist"]["x1"], row+.28, f"Fringe {city['scalist']['x1']:.2f}",
                      fontsize=8, ha="center", va="bottom")
            boundary = city["params"]["x1_max"]
            if np.isfinite(boundary) and boundary <= xmax:
                land.vlines(boundary, row-.28, row+.25, colors="black", linestyles=":", linewidth=1.8)
        land.set_yticks(range(1, len(cities)+1), labels=list(reversed(labels)))
        land.set_xlim(0, xmax); land.set_ylim(.5, len(cities)+.6)
        land.set_xlabel(f"Distance from city center ({units['distance']})")
        land.grid(True, linestyle=":", color="#595959", alpha=.35)
        land.spines[["top", "right"]].set_visible(False); land.set_axisbelow(False)
        fig.subplots_adjust(left=.11, right=.97, top=.93, bottom=.10)
        figs.append(fig)
    return figs
