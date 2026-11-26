# `mapping.json`

`mapping.json` is the translation table used by `cmor4cmip7` to connect the native NorESM output variables to the CMIP7 variable names and metadata conventions.

The file resides in the recipe directory, specicied in the `variables.nml` and typically under `recipes/template/mapping.json`, and is read by the CMOR workflow before generating output files.

## Purpose

Each entry in the file identifies a target CMIP7 variable, such as:

```json
 "ocean.tos.tavg-u-hxy-sea.day.glb": {
     "original_name": "sst",
     "arakawa_grid_point": "p"
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
- `arakawa_grid_point`: the staggering of the native variable, `p`, `u` or `v` (see below).
- `sources`: a dictionary used when a CMIP7 variable is derived from multiple model fields, e.g. a weighted sum or combination.
- `preprocs`: special preprocessing steps before reading the source data.
- `postprocs`: special processing before writing the CMIP7 output file.
- `history`: a short formulae descriping of how the target variable is derived.
- `comment`: a free-text note. Unlike `history`, it is **not** read by the program; it is only documentation for the file's readers.

Example:

```json
"ocean.hfx.tavg-u-hxy-sea.mon.glb": {
  "original_name": "uhflx, dp",
  "arakawa_grid_point": "u",
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

## Arakawa grid point

`arakawa_grid_point` records on which staggered grid of the Arakawa C-grid the
native variable lives:

| value | meaning | typical examples |
| --- | --- | --- |
| `p` | cell centre / tracer point (most ocean fields) | `temp`, `salt`, `volgs`, `parea` |
| `u` | zonal (east-west) velocity point | `u`, `udx`, `uhflx` |
| `v` | meridional (north-south) velocity point | `v`, `vdx`, `vhflx` |

The value selects the horizontal axis definition and the CMIP7 `grid_label` of
the output: `g202` for 2-D and 3-D p fields, `g010` for global means, `g014` for line
transports, `g262` for basin/meridional diagnostics, and `g241`/`g240` for u/v
fields. It also avoids guessing from the name: a variable such as `volgs`
starts with `v` but is a p-point field.

When the key is missing, the program falls back to the `coordinates` attribute
of the first source variable in the model file (`"ulon ulat"` → `u`,
`"vlon vlat"` → `v`, otherwise `p`) and, only if that is absent as well, to the
first letter of the variable name.

:::{attention}
**Why it matters:** 
The mapping file is the main bridge between the NorESM3 data model and the CMIP7 data request. Without it, the workflow would not know which native fields correspond to the requested CMIP7 variables, nor how to apply any necessary preprocessing or derivation.
:::

