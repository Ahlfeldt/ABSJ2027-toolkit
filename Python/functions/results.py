"""Create the aggregate table and three spatial-profile figures."""
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from report_city import report_city
from report_units import report_units


def results(baseline, counterfactual=None, make_graphs=True):
    units = report_units(baseline); base = report_city(baseline, units)
    fields = ["N","urban_share","GDP","wage_bill","y","total_urban_area","AREA","density","x0","x1","F_C","F_R","F","p_R","p_C","CC","commuting_income_loss","commuting_loss_pct","DD","HA","U_bar","V","LV","floor_space_per_resident","housing_expenditure","height_gap_pct"]
    labels = ["Urban population","Urbanization rate","GDP","Wage bill","Average annual wage" if units["annual"] else "Wage","Total urban area","Developable urban area","Population density","CBD boundary","Urban fringe","Commercial floor space","Residential floor space","Total floor space","Average residential rent","Average commercial rent","Commuting disamenity index","Commuting disamenity: income loss per resident","Commuting disamenity: share of wage","Density amenity index","Height amenity index","Urban utility","Regional expected welfare","Aggregate regional land rent","Residential floor space per resident","Housing expenditure per resident","Height gap (relative to T)"]
    u = ["people","fraction",units["flow"],units["flow"],units["flow"]+" / worker",units["area"],units["area"],units["density"],units["distance"],units["distance"],units["floor_area"],units["floor_area"],units["floor_area"],units["rent"],units["rent"],"index",units["flow"]+" / resident","% of wage","index","index","utility units","utility units",units["flow"],units["floor_per_resident"],units["flow"]+" / resident","%"]
    frame = pd.DataFrame({"Metric": labels, "Unit": u, "Baseline": [base["scalist"][f] for f in fields]})
    if counterfactual is not None:
        cf = report_city(counterfactual, units); values = np.array([cf["scalist"][f] for f in fields], float); baseline_values = frame["Baseline"].to_numpy(float)
        frame["Counterfactual"] = values
        change = np.full(values.shape, np.nan); valid=np.isfinite(baseline_values) & (baseline_values != 0)
        change[valid] = 100*(values[valid]/baseline_values[valid]-1); frame["Change_pct"] = change
    print(frame.to_string(index=False))
    figures = _figures(baseline, counterfactual, units) if make_graphs else []
    return frame, figures


def _figures(base, cf, units):
    d = base["fund"]["D"]; center = d >= 0; colors = ("#0072B2", "#D55E00")
    specs = [("Building height / FAR", "S_x_C", "S_x_R"), ("Floor-space rent", "p_bar_x_C", "p_bar_x_R"), ("Land rent", "r_x_C", "r_x_R")]
    figs=[]
    for ylabel, commercial, residential in specs:
        fig, ax = plt.subplots(figsize=(8,5)); figures=[base]+([] if cf is None else [cf])
        for j, city in enumerate(figures):
            shown = report_city(city, units); style="-" if j==0 else "--"; suffix="Baseline" if j==0 else "Counterfactual"
            ax.plot(d[center], shown["varlist"][commercial][center], style, color=colors[0], label=f"Commercial — {suffix}")
            ax.plot(d[center], shown["varlist"][residential][center], style, color=colors[1], label=f"Residential — {suffix}")
        ax.set_xlabel(f"Distance from city centre ({units['distance']})"); ax.set_ylabel(ylabel)
        ax.grid(True, linestyle=":", color="0.75"); ax.legend(frameon=False); fig.tight_layout(); figs.append(fig)
    return figs
