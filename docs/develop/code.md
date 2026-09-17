# Code

This repository is organized around a small Fortran driver program and a set of recipe files that describe the model, experiment, output paths, and variables to be CMORized. The overall workflow is:

1. read the Fortran namelist recipe files
2. load the required grid and metadata files and model raw data
3. map model variables to CMIP7 definitions
4. write CMIP7-compatible NetCDF output files through the CMOR interface

## Layout

```text
cmor4cmip7
├── GSW-Fortran/                # Gibbs-SeaWater oceanographic toolbox (submodule)
├── README.md                   # Overview and quick tutorial
├── bin/                        # Built executables and helper scripts
│   ├── filelist_*              # file-list of experiments
│   ├── attributes_*            # CMIP7 global attribute json files
│   ├── cmor4cmip7              # Main executable
│   └── test.sh                 # Basic test wrapper
├── build/                      # Site-specific build configuration
│   ├── Makefile.nird_gnu       # GNU build settings
│   ├── Makefile.nird_gnu_mpi   # GNU + MPI settings
│   ├── Makefile.nird_intel     # Intel build settings
│   ├── Makefile.nird_intel_mpi # Intel + MPI settings
│   └── build.sh                # Build wrapper script
├── cmor/                       # CMOR library and CMIP7 tables (submodules)
│   └── cmip7-cmor-tables/
│       ├── tables/
│       └── tables-cvs/
├── docs/                       # User and developer documentation (this documentation)
├── griddata/                   # Required model grid and auxiliary data files
│   ├── README
│   ├── SHA256SUM
│   ├── grid_tnx1v4.nc          # Native ocean grid
│   ├── inicon_tnx1v4.nc        # Ocean initial conditions
│   └── ocean_regions_tnx1v4.nc # Ocean region masks
├── json-fortran/               # JSON I/O library used by the workflow (submodule)
├── recipes/                    # Experiment-specific recipes and templates
│   ├── NorESM3-LM/
│   │   └── piControl/
│   │       ├── checkcmorout.sh
│   │       ├── cmor.sh
│   │       ├── template/
│   │       └── v20260306/
│   ├── NorESM3-MM/
│   │   └── piControl/
│   └── template/
│       ├── experiment.nml      # Experiment metadata and configurations for CMORized output
│       ├── mapping.json        # model-to-CMIP7 variable mapping
│       ├── model.nml           # Model and grid metadata
│       ├── system.nml          # I/O and runtime configuration
│       └── variables.nml       # CMIP7 variable list to process
├── source/                     # Main Fortran program and support routines
│   ├── cmor4cmip7.F90          # Main program entry point
│   ├── m_jsons.F90             # JSON reading/writing helpers
│   ├── m_modelsatm.F90         # Atmospheric component
│   ├── m_modelsice.F90         # Sea-ice component
│   ├── m_modelslnd.F90         # Land component
│   ├── m_modelsocn.F90         # Ocean component
│   ├── m_namelists.F90         # Namelist parsing and recipe handling
│   └── m_utilities.F90         # Generic utilities and helper routines
└── test/                       # Validation and test utilities
```

## Files and directories

### `build/`
This folder contains the site-specific build logic. It selects the compiler, loads required modules, and compiles the executable with the correct dependency stack.

### `recipes/`
This is the user-facing configuration area. Each experiment has a recipe directory containing the Fortran namelists and mapping files that define what should be converted and how.

- `system.nml`: path and runtime settings
- `model.nml`: model and ocean grid metadata
- `experiment.nml`: experiment identity, time coverage, and variant metadata
- `variables.nml`: list of compound variable names to be processed
- `mapping.json`: mapping between native output fields and CMIP7 variable definitions

:::{note}
The `mapping.json` file is currently hard-coded to point to one under the `receipe/template/mapping.json`.
:::

### `source/`
This is the core program code. The main program reads recipe files, loops over components (atmosphere, land, sea ice, ocean), and calls the CMOR library to write NetCDF output.

:::{note}
Only the ocean/ocnBGC components are currently activated, while the atmosphere/land/seaice can be adapted for NorESM2 and NorCPM2 versions.
:::

- `cmor.F90`: main entry point of the program
- `m_namelists.F90`: parses namelist inputs
- `m_modelsocn.F90`, `m_modelsatm.F90`, `m_modelslnd.F90`, `m_modelsice.F90`: component-specific procedures
- `m_jsons.F90`: utilities to read/write json files
- `m_utilities.F90`: generic helper routines, file handling and data processing

### `cmor/` and submodules
These submodules provide the CMOR library and the CMIP7 controlled vocabularies (CVs) and tables used to validate metadata and output structure.

### `griddata/`
This directory contains the grid and mask files required to describe the model's native geometry and to map or remap to the CMIP7 grid definitions.

In short, the repository combines a Fortran processing program, CMOR metadata tables, recipe configuration files, and auxiliary data to turn native model output into CMIP7-ready products.

