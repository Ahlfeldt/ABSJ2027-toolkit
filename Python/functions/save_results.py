"""Save tables, figures, and complete Python result objects."""
from pathlib import Path
import pickle, shutil


def save_results(folder, baseline, counterfactual, statistics, figures):
    folder=Path(folder); figdir=folder/"Figures"; tabdir=folder/"Tables"
    figdir.mkdir(parents=True, exist_ok=True); tabdir.mkdir(parents=True, exist_ok=True)
    statistics.to_csv(tabdir/"statistics.csv", index=False)
    statistics.to_excel(tabdir/"statistics.xlsx", sheet_name="Statistics", index=False)
    columns = list(statistics.columns)
    align = "ll" + "r"*(len(columns)-2)
    rows = ["\\begin{tabular}{"+align+"}", "\\toprule", " & ".join(columns)+" \\\\", "\\midrule"]
    for record in statistics.itertuples(index=False, name=None):
        cells=[]
        for value in record:
            cells.append(f"{value:.6g}" if isinstance(value, (int, float)) else str(value).replace("_", "\\_"))
        rows.append(" & ".join(cells)+" \\\\")
    rows += ["\\bottomrule", "\\end{tabular}"]
    (tabdir/"statistics.tex").write_text("\n".join(rows)+"\n", encoding="utf-8")
    with (folder/"results.pkl").open("wb") as stream: pickle.dump({"baseline":baseline,"counterfactual":counterfactual}, stream)
    for i, fig in enumerate(figures, 1):
        fig.savefig(figdir/f"figure_{i}.png", dpi=300); fig.savefig(figdir/f"figure_{i}.pdf")
    output_root=folder.parent
    if folder.name in ("Paper","Empirical"):
        (output_root/"Figures").mkdir(exist_ok=True); (output_root/"Tables").mkdir(exist_ok=True)
        for path in tabdir.iterdir(): shutil.copy2(path, output_root/"Tables"/path.name)
        shutil.copy2(folder/"results.pkl", output_root/"results.pkl")
        for path in figdir.iterdir(): shutil.copy2(path, output_root/"Figures"/path.name)
