"""Define reporting conversions from the calibrated baseline."""


def report_units(baseline):
    targets = baseline.get("targets", {})
    spatial = targets.get("total_urban_area") is not None
    units = {"reference_density": baseline["scalist"]["N"]/baseline["scalist"]["AREA"],
             "factor": 1.0, "money": "model units", "flow": "model units",
             "spatial": spatial, "space_factor": 1e6 if spatial else 1.0,
             "distance": "km" if spatial else "model distance units",
             "area": "km^2" if spatial else "model area units",
             "density": "people / km^2" if spatial else "people / model area unit",
             "floor_area": "km^2 of floors" if spatial else "model floor-space units",
             "floor_per_resident": "m^2 / resident" if spatial else "model floor-space units / resident",
             "annual": False}
    units["rent"] = "model monetary units / m^2" if spatial else "model monetary units / model floor-space unit"
    if targets.get("wage") is not None:
        units["money"] = targets.get("currency", "currency units")
        units["factor"] = targets["wage"]/baseline["scalist"]["y"]
        units["flow"] = units["money"] + " / year"
        units["rent"] = units["money"] + (" / m^2 / year" if spatial else " / model floor-space unit / year")
        units["annual"] = True
    return units
