# `mapping.json`

`mapping.json` is the translation table used by `cmor4cmip7` to connect the native NorESM output variables to the CMIP7 variable names and metadata conventions.

The file resides in the recipe directory, specicied in the `variables.nml` and typically under `recipes/template/mapping.json`, and is read by the CMOR workflow before generating output files.

## Purpose

Each entry in the file identifies a target CMIP7 variable, such as:

```json
 "ocean.tos.tavg-u-hxy-sea.day.glb": {
     "original_name": "sst"
 },
```

and tells the program which model field or fields should be used as the source for that variable. This lets the code map model-specific names like `TREFHT`, `pbot`, or `mldb04` onto the standard CMIP7 data request names and branded-variable format.

## Structure

The JSON file has a `Header` section and a `variable_entry` section. The `Header` contains metadata describing the mapping file itself, while `variable_entry` contains one entry per CMIP7 target variable.

Example:

```json
{
  "Header": {
    "description": "mapping of NorESM3 model output to CMIP7 data request v1.2.2.3"
  },
  "variable_entry": {
    "atmos.tas.tavg-h2m-hxy-u.mon.glb": {
      "original_name": "TREFHT"
    },
    "ocean.zos.tavg-u-hxy-sea.mon.glb": {
      "original_name": "zos"
    },
    "ocnBgchem.chl.tavg-op20bar-hxy-sea.day.glb": {
        "original_name": "phyc_200",
        "sources": {
            "phyc_200": 0.024399999999999998
        },
        "history": "chl = phy_200*122*12/60/1000",
        "comment": "Conversion from [mol P/m3] to [kg Chl/m3] using [60 gC/gChl]"
    }
  }
}
```

## Common keys

Each variable entry may contain the following fields:

- `original_name`: the native model variable name, or a comma-separated list of native variables.
- `sources`: a dictionary used when a CMIP7 variable is derived from multiple model fields, e.g. a weighted sum or combination.
- `preprocs`: special preprocessing steps before reading the source data.
- `postprocs`: special processing before writing the CMIP7 output file.
- `history`: a short formulae descriping of how the target variable is derived.
- `comment`: a short text description of how the target variable is derived.

Example:

```json
"ocean.hfx.tavg-u-hxy-sea.mon.glb": {
  "original_name": "uhflx, dp",
  "sources": {
    "uhflx": 1.0,
    "dp": 1.0
  },
  "postprocs": {
    "dp.avg": true
  },
  "history": "hfx = vertical average by dp, sum(uhflx*dp)/sum(dp)"
}
```

This means the CMIP7 variable `ocean.hfx.tavg-u-hxy-sea.mon.glb` is constructed from the native fields `uhflx` and `dp`, followed by a post-processing step to compute the depth-weighted average.

In short, `mapping.json` is the recipe that tells `cmor4cmip7` how to turn native model output into CMIP7-compliant output fields.

:::{attention}
**Why it matters:** 
The mapping file is the main bridge between the NorESM3 data model and the CMIP7 data request. Without it, the workflow would not know which native fields correspond to the requested CMIP7 variables, nor how to apply any necessary preprocessing or derivation.
:::

