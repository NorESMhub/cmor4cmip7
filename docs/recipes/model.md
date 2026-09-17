# `model.nml`

The `model` namelist defines the source and configuration metadata needed for CMIP7-style processing. It identifies the model and institution, records the ocean grid and nominal resolution, and points to the auxiliary files that define the model's native grid, regional masks, initialization conditions, and transport diagnostics.

```fortran
&model
 source_id     = 'NorESM3-LM',
 institute_id  = 'NCC',
 contact       = 'Please send any requests or bug reports to noresm-ncc@met.no.',
 ocngrid       = 'tripolar grid with 1deg nominal resolution',
 ocngrid_label = 'g143',
 ocngrid_resolution = '100 km',
 tagoyr        = 'blom.hy',
 tagoyrbgc     = 'blom.hbgcy',
 tagomon       = 'blom.hm',
 tagomonbgc    = 'blom.hbgcm',
 tagoday       = 'blom.hd',
 tagodaybgc    = 'blom.hbgcd',
 ocngridfile   = 'grid_tnx1v4.nc',
 ocnregnfile   = 'ocean_regions_tnx1v4.nc',
 ocninitfile   = 'inicon_tnx1v4.nc',
 ocnmertfile   = 'mertraoceans_tnx1v4.dat',
 secindexfile  = 'secindex_tnx1v4.dat'
/
```

## Field descriptions

| keyword | CMIP7-aligned description |
| --- | --- |
| `source_id` | Short label identifying the model or model configuration, as registered in the CMIP7 source ID controlled vocabulary. For example, `NorESM3-LM` or `NorESM3-MM`. |
| `institute_id` | Institution acronym for the group responsible for the model, as recorded in CMIP7 metadata. |
| `contact` | Contact information for questions, bug reports, or requests related to the model output or data provenance. |
| `ocngrid` | Human-readable description of the ocean grid geometry and resolution used by the model. |
| `ocngrid_label` | CMIP7 grid identifier associated with the ocean grid, such as `g143`, following the registered grid label convention. |
| `ocngrid_resolution` | Approximate nominal horizontal resolution of the ocean grid, such as `100 km`. |
| `tagoyr` | File name tag or pattern used for yearly ocean model output files. |
| `tagoyrbgc` | File name tag or pattern used for yearly ocean biogeochemistry output files. |
| `tagomon` | File name tag or pattern used for monthly ocean model output files. |
| `tagomonbgc` | File name tag or pattern used for monthly ocean biogeochemistry output files. |
| `tagoday` | File name tag or pattern used for daily ocean model output files. |
| `tagodaybgc` | File name tag or pattern used for daily ocean biogeochemistry output files. |
| `ocngridfile` | NetCDF file describing the ocean and sea-ice grid geometry used for model diagnostics and remapping. |
| `ocnregnfile` | NetCDF file defining ocean regions used in regional diagnostics or masks. |
| `ocninitfile` | Initial-condition file used to initialize ocean temperature and salinity. |
| `ocnmertfile` | File defining the meridional transport or section-based ocean transport calculations used by the model. |
| `secindexfile` | File containing section indices or transport mask definitions used to diagnose fluxes across ocean sections or straits. |

:::{note}
This namelist is not itself a CMIP7 global-attribute table, but it supplies the model-specific metadata that is needed to generate CMIP7-compliant output. The values here must be consistent with the registered `source_id`, the grid label, and the model-configuration information used when creating the final file metadata and directory structure.
:::
