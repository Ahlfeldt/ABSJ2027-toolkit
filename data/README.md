# Global city simulation results

This folder contains the city-level counterfactual results from the paper's
preferred specification for all 12,873 cities:

- [`global_city_counterfactual_results.csv`](global_city_counterfactual_results.csv)
  is the machine-readable UTF-8 version intended for code and the future web tool.
- [`global_city_counterfactual_results.xlsx`](global_city_counterfactual_results.xlsx)
  contains the same observations, a reader guide, filters, and a data dictionary.

The data are in long format. Each row represents one city in one of three
experiments: removing all height limits, removing commercial height limits only,
or removing residential height limits only. There are 38,619 rows in total.

All outcome fields ending in `_change` are proportional changes relative to the
city's calibrated baseline. For example, `0.10` denotes a 10% increase and
`-0.10` a 10% decrease. The `estimated_height_gap` and both urbanization-rate
fields are also fractions between zero and one.

`fid` is the stable city identifier in the replication files. City and country
names come from `urbanrates.dta` and merge one-to-one to all 12,873 simulation
identifiers. `world_region` and `development_group` come from the simulation
input. Original population and urbanization values are reported separately from
the model targets because the replication applies sample transformations to some
small-city inputs.

The source crosswalk leaves 758 city names blank, while retaining their `fid` and
country. These observations receive an explicit label such as
`Unnamed urban centre (FID 5949)` so that every row remains selectable in a web
interface. `city_name_is_reported` distinguishes supplied names from these
fallback labels.

The three source outputs are:

- `TABS/TAB_CFT_base_full.csv`
- `TABS/Sensitivity/TAB_CFT_base_relaxCom_full.csv`
- `TABS/Sensitivity/TAB_CFT_base_relaxRes_full.csv`

Use of these data is subject to citing:

Ahlfeldt, Baum-Snow, and Jedwab, *The Skyscraper Revolution*: Global economic
development and land savings. *The Review of Economic Studies*, forthcoming.
