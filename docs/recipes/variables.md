# `variables.nml`

The `variables` namelist defines the list of CMIP7 variables to be processed. In CMIP7, each entry is a branded variable name stored in the `compound_names` list, following the CMIP7 convention for variable identifiers and brand suffixes.

A typical entry has the form:

```text
<realm>.<variable_id>.<temporal_label>-<vertical_label>-<horizontal_label>-<area_label>.<frequency>.<region>
```

This is the CMIP7 version of the "compound name" used to identify a variable and its sampling/processing context, and it is the metadata basis for the final CMIP7 output naming and DRS.

```fortran
!
! --- --- --- --- --- ---
! list of variables to be cmorized;
! use Fortran comment to activate/deactivate any of themgc
!   'ocean.agessc.tavg-ol-hxy-sea.mon.glb'              ! add note here
! --- --- --- --- --- ---
!
&variables
mapfile         = '../recipes/template/mapping.json',
compound_names  = 
!
    'ocean.agessc.tavg-ol-hxy-sea.mon.glb'
    'ocean.areacello.ti-u-hxy-u.fx.glb'
!...
    'ocean.zos.tavg-u-hxy-sea.day.glb'
    'ocean.zos.tavg-u-hxy-sea.mon.glb'
    'ocean.zossq.tavg-u-hxy-sea.mon.glb'
    'ocean.zostoga.tavg-u-hm-sea.mon.glb'
!
    'ocnBgchem.calc.tavg-ols-hxy-sea.mon.glb'
    'ocnBgchem.chl.tavg-ols-hxy-sea.day.glb'
    'ocnBgchem.chl.tavg-ols-hxy-sea.mon.glb'
!...
    'ocnBgchem.zooc.tavg-ols-hxy-sea.mon.glb'
    'ocnBgchem.zooc.tavg-ol-hxy-sea.mon.glb'
/
```

`mapfile` specify path to the variable mapping file that links model-specific output fields to the CMIP7 data request and target metadata definitions. The path may be absolute or relative to the directory the program is started from.

The list of compound names denotes the datasets to be CMORized:

| Example compound name | Meaning |
| --- | --- |
| `ocean.agessc.tavg-ol-hxy-sea.mon.glb` | Ocean age scalar with monthly means, using the `ol` vertical label, `hxy` horizontal sampling, `sea` masking, and global region. |
| `ocean.areacello.ti-u-hxy-u.fx.glb` | Fixed-field ocean cell area, with the `fx` frequency and global domain. |
| `ocean.zos.tavg-u-hxy-sea.day.glb` | Sea surface height (dynamic sea level) as daily means over the global ocean. |
| `ocean.zos.tavg-u-hxy-sea.mon.glb` | Same field but monthly mean output, following the CMIP7 branded-variable naming scheme. |
| `ocean.zostoga.tavg-u-hm-sea.mon.glb` | Global ocean steric sea-level anomaly or equivalent monthly mean diagnostic. |
| `ocnBgchem.chl.tavg-ols-hxy-sea.mon.glb` | Ocean biogeochemistry chlorophyll concentration, monthly mean, global ocean domain. |
| `ocnBgchem.zooc.tavg-ols-hxy-sea.mon.glb` | Zooplankton concentration, monthly mean over the global ocean. |

:::{tip}
The entries can be commented out with `!` to disable individual variables without removing them from the file, which makes it easy to re-run only selected CMIP7 diagnostics.
:::

## Parsing and validation

The program splits every entry into five dot-separated fields and the branded
suffix into four dash-separated fields:

```text
<realm>.<branded_base>.<temporal>-<vertical>-<horizontal>-<area>.<frequency>.<region>
```

- the **horizontal** label (third dash field, e.g. `hxy`, `hm`, `ht`, `hyb`) is
extracted and used, together with the Arakawa grid point from `mapping.json`,
to choose the CMIP7 `grid_label` of the output;
- entries with a missing dot, or a suffix without the four dash-separated
fields, stop the program with an error that names the offending entry instead
of silently shifting the fields;
- the region field must match a `mapping.json` entry exactly — requesting
`...mon.glb` does not pick up a mapping written for `...mon.30S-90S`.
