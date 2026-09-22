# Developer's Guide

The [cmor4cmip7](https://github.com/NorESMhub/cmor4cmip7.git) repository contains the source code and configuration used to convert native NorESM3 model output into CMIP7-compliant NetCDF files with the [PCMDI CMOR library](https://github.com/pcmdi/cmor). The project is organized as a small Fortran application plus a set of runtime recipes, table definitions, and supporting libraries.

## Repository layout

- `README.md`: user-facing overview and example workflow.
- `GSW-Fortran/`: TEOS-10 GSW support library used by the workflow.
- `cmor/`: external CMOR dependency as a submodule.
- `json-fortran/`: JSON Fortran library used by the project.
- `build/`: site-specific build scripts and Makefiles such as `build.sh` and `Makefile.*`.
- `docs/`: project documentation, including the Jupyter Book site.
- `recipes/`: runtime configuration templates for a CMOR run.
  - `recipes/template/system.nml`
  - `recipes/template/model.nml`
  - `recipes/template/experiment.nml`
  - `recipes/template/variables.nml`
  - `recipes/template/mapping.json`
- `source/`: Fortran source files containing the core processing procedures.
- `griddata/`: grid and auxiliary data used during conversion.
- `tables/`: CMIP7 table definitions and related metadata files.

## Program architecture

The build step in `build/` compiles the Fortran sources from `source/` and links them against the CMOR library and supporting Fortran dependencies. The final program is an executable (named as `cmor4cmip7`) that is typically run from the `bin/` directory.

At runtime, the program reads the namelist configuration files in `recipes/template`:

- `system.nml`: filesystem layout, raw input directories, output directories, and runtime switches.
- `model.nml`: model metadata and grid configuration.
- `experiment.nml`: experiment identity, metadata, and CMIP7 experiment settings.
- `variables.nml`: list of variables to process.
- `mapping.json`: mapping of model output and CMIP7 requested dataset.

The executable then scans the native model output in the configured input directories, applies CMOR metadata conventions from the tables and CMOR library, and writes CMIP7-compliant NetCDF files into the target output directory.

In other words, the repository is split between operational configuration (`recipes/`), low-level implementation (`source/`), and external dependencies (`cmor/`, `json-fortran/`, `GSW-Fortran/`).

A typical execution path looks like this:

```text
build.sh
  -> compile executable
      -> ./cmor4cmip7 system.nml model.nml experiment.nml variables.nml
          -> read namelists
          -> read mapping.json
          -> inspect raw model files
          -> apply grid / metadata / variable logic
          -> call CMOR library
          -> write CMIP7-compliant NetCDF files
```

## Runtime workflow

1. Create or adapt a recipe directory based on `recipes/template`.
2. Update the namelists to match the model run and target experiment.
3. Compile the code using the relevant build script or Makefile.
4. Run the generated executable with the selected recipe.
5. Inspect the generated output in the configured output directory.
6. Validate the output using the external CMIP7 validation workflow.

