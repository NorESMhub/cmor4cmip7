# `system.nml`

The `system` namelist defines the local filesystem locations and processing control switches used by the CMOR workflow. These settings determine where model outputs are read from, where CMIP7 products are written, which grid and table resources are used, and whether the directory tree or file scan must be regenerated.

```fortran
&sys
 ibasedir      = '/nird/datalake/NS9560K/noresm3/cases'
 obasedir      = '/scratch/yanchun/cmorout',
 griddata      = '/nird/datalake/NS16000B/CMOR/cmor4cmip7/griddata',
 tabledir      = '/nird/datalake/NS16000B/CMOR/cmor4cmip7/cmor/cmip7-cmor-tables/tables',
 createsubdirs = .false.,
 forcefilescan = .true.,
 verbose       = .false.,
/
```

## Field descriptions

| keyword | CMIP7-aligned description |
| --- | --- |
| `ibasedir` | Root directory containing the raw model output files to be processed. |
| `obasedir` | Destination directory where CMORized output files are written. |
| `griddata` | Directory containing model grid and mask data required for regridding and metadata assignment. |
| `tabledir` | Path to the CMIP7 CMOR tables and controlled vocabularies used to validate metadata and DRS fields. |
| `createsubdirs` | Logical flag indicating whether CMOR should create the CMIP7 directory tree following the CMIP7 Data Reference Syntax (DRS). |
| `forcefilescan` | Logical flag forcing a full scan of the model output files and regeneration of the file list, even when cached metadata already exists. |
| `verbose` | Logical flag controlling the amount of diagnostic output written to the terminal and log stream during processing. |

:::{note}
These values are local configurations for the `cmor4cmip7` rather than CMIP7 global attributes, but they directly influence the consistency and correctness of the generated CMIP7 archive. In particular, `tabledir`, and `griddata` determine whether the workflow is using the correct CMIP7-controlled vocabularies, and grid metadata for the target output.
:::
