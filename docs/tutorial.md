# Tutorial

This tutorial shows a complete workflow for CMORizing a NorESM3 simulation with `cmor4cmip7` and preparing it for CMIP7-style output.

The example below assumes a `piControl` experiment for the `NorESM3-LM` model, but the workflow is the same for other experiments and model configurations.

## 1. Clone the source

```bash
cd ~/                                             # Install under home as default
tag=v20261028                                     # Chose [the latest release](https://github.com/NorESMhub/cmor4cmip7/tags)
git clone git@github.com:NorESMhub/cmor4cmip7.git # Clone the source code
cd cmor4cmip7
git checkout -b $tag tags/$tag                    # Checout the tag
git switch -c $tag                                # Make it as a branch
git submodule update --init --recursive           # Get the submodules
```

## 2. Prepare a recipe directory for the experiment

The template recipes are stored in:

```bash
cmor4cmip7/recipes/template
├── experiment.nml
├── mapping.json
├── model.nml
├── system.nml
└── variables.nml
```

Create a dedicated recipe directory for your experiment:

```bash
cd ~/cmor4cmip7/recipes
mkdir -p NorESM3-LM/piControl/template
cp -r template/*.nml NorESM3-LM/piControl/template
```

This keeps the default templates intact and gives you a clean experiment-specific recipe template.

Then you create a recipe from the case template for a certain data version. For example:
```bash
cd ~/cmor4cmip7/recipes/NorESM3-LM/piControl
mkdir v20261028
cp -r template/*.nml v20261028/
```

The following sections will instruct how to update these nameslists for this data version `NorESM3-LM/piControl/v20261028`

## 3. Edit the namelist files

The core CMOR configurations are defined in four Fortran namelist files. They are not YAML or JSON files; they follow Fortran namelist syntax and must be edited carefully.

### 3.1 `system.nml`

This file defines storage and processing paths.

Key entries:

- `ibasedir`: root directory containing the raw model output
- `obasedir`: output directory for CMORized files
- `griddata`: directory containing model grid files
- `tabledir`: directory of the CMIP7 tables and CVs
- `mapfile`: file linking model output to CMIP7 metadata

Example:

```fortran
&sys
 ibasedir      = '/nird/datalake/NS9560K/noresm3/cases'
 obasedir      = '/scratch/$USER/cmorout'
 griddata      = '/nird/datalake/NS16000B/CMOR/cmor4cmip7/griddata'
 tabledir      = '/nird/datalake/NS16000B/CMOR/cmor4cmip7/cmor/cmip7-cmor-tables/tables'
 createsubdirs = .false.
 forcefilescan = .true.
 verbose       = .false.
/
```

For a first test run, it is often enough to change `obasedir` to a writable directory under your scratch or home space.

### 3.2 `model.nml`

This file defines the model identity and model-specific configuration.

Key entries:

- `source_id`: the CMIP7 model/source identifier, for example `NorESM3-LM`
- `institute_id`: institution acronym
- `ocngrid_label`: grid label such as `g143`
- `ocngrid_resolution`: nominal model resolution
- auxiliary file names for the native ocean grid and masks

### 3.3 `experiment.nml`

This file defines the experiment metadata and the branch/variant information. It is important for CMIP7 compliance.

Key entries:

- `casename`: modeal case name
- `osubdir`: output subfolder name as `source_id`/`experiment_id`/`data_version`.
- `experiment_id`: the experiment label (`piControl`, `historical`, etc.)
- `activity_id`: activity acronym (`CMIP`)
- `mip_era`: CMIP era (`CMIP7`)
- `realization_index`, `initialization_index`, `physics_index`, `forcing_index`
- parent experiment metadata if this is a branched simulation
- time coverage (`year1`, `yearn`, `month1`, `monthn`)

Example:

```fortran
&experiment
 casename               = 'n1850GHGGaxg.LM.nor30b27.002.20261016',
 osubdir                = 'NorESM3-LM/piControl/v20261028',
 experiment_id          = 'piControl',
 parent_experiment_id   = 'piControl-spinup',
 parent_experiment_rip  = 'r1i1p1',
 parent_time_units      = 'days since 0001-01-01 00:00:00',
 history                = '',
 realization_index      = 'r1',
 initialization_index   = 'i1',
 physics_index          = 'p1',
 forcing_index          = 'f1',
 branch_time            = 0.,
 year1                  = 0001,
 yearn                  = 0050,
 month1                 = 1,
 monthn                 = 12,
 parent_activity_id     = 'CMIP',
 parent_variant_label   = 'r1i1p1f1',
 parent_mip_era         = 'CMIP7',
 mip_era                = 'CMIP7',
 branch_time_in_child   = 0.0D0,
 branch_time_in_parent  = 620500.0D0,
 scanallfiles           = .false.
/
```
See more on how to set the information on the parent experiment if exists, for example [branch_time_in_parent](https://wcrp-cmip.github.io/cmip7-guidance/docs/CMIP7/Global_Attributes/#table-3-conditionally-required-global-attributes)

:::{important}
**Code and dataset versions:**
The processed dataset version should match the [code release tag](https://github.com/NorESMhub/cmor4cmip7/tags). This keeps the output traceable and reproducable. It will be easiber to identify errors in the CMORized and published datasets, and facilitate the [data errata record and retract processes](https://errata.esgf.io/static/index.html).
:::

### 3.4 `variables.nml`

This file lists the CMIP7 branded variables to be CMORized. Each entry is a variable compound name, and inactive entries can be commented out with `!`.

Example:

```fortran
mapfile = '/nird/datalake/NS16000B/CMOR/cmor4cmip7/recipes/template/mapping.json',
&variables
  compound_names =
    'ocean.agessc.tavg-ol-hxy-sea.mon.glb',
    'ocean.zos.tavg-u-hxy-sea.mon.glb',
    'ocnBgchem.chl.tavg-ols-hxy-sea.mon.glb'
/
```

Use `!` to skip any variable you do not want to process in the current run.

:::{note}
These are Fortran namelist files, so standard Fortran rules apply. Keep the syntax valid, avoid missing commas, and check that each entry is quoted properly.
:::

(clone-build)=
## 4. Build the program

Build (by default) with Intel compiler as a serial program, see more with `./build.sh -h`

```bash
cd build
./build.sh
```
:::{seealso}
See [Installation/cmor4cmip7](install/cmor4cmip7.md) for build options and compiler-specific instructions.
:::

## 5. Run the CMORization

Once the namelists are correct, run the program from the executable directory, with the helper wrapper script `runcmor.sh`.

Set the path to the namelist `pnml` and the names of the required namelist files; cholse the comipler and run type (serial or parallel, and the number of threads if running in parallel).

```bash
cd bin
./runcmor.sh
```

which basically invokes the program as command line:
```bash
./cmor4cmip7 ${pnml}/system.nml ${pnml}/model.nml ${pnml}/experiment.nml ${pnml}/variables.nml
```

The program will read the namelists, identify the target inputs, and generate CMIP7-style output files in the configured output directory.

## 6. Inspect the output

After the run, check the output directory you set in `obasedir`, for example:

```bash
ls -l /scratch/$USER/cmorout
```

The generated data should follow the CMIP7 directory structure and naming conventions implied by the CMIP7 data request and the configured experiment metadata.

## 7. Validate the generated files

A technical validation step is strongly recommended before publishing or distributing the data. The project provides a separate validation tool for this purpose.

**Clone the validation tool**
```bash
cd ~
git clone git@github.com:NorESMhub/cmip7validate.git
```

**Update the validation configuration**
The configuration needs to match your experiment, for example in `params.yml`:

```yaml
cmorout         : /scratch/yanchun/cmorout
source_id       : NorESM3-LM
experiment_id   : piControl
variant_label   : r1i1p1f1
version         : v20261027
```
:::{note}
The data version number in the `params.yml` needs to be updated as the same as in the `experiment.nml`.
:::

**Repack CMIP7 netCDF-4 datasets**
Using the [cmip7repack tool](https://github.com/NCAS-CMS/cmip7_repack) to repack file contents to have a different chunk and internal file metadata layout, in such as way as to improve their read-performance over the lifetime of the CMIP7 archive.

```bash
cd ~/cmip7validate
./cmip7repack.sh
```

**Build and execute the validation**
Then run the validation and check the generated report.
```bash
cd ~/cmip7validate
./build.sh
```
**Check the result**
Find the generated book/webpage by default at:
```
https://ns9560k.web.sigma2.no/datalake/diagnostics/cmip7validate
```
## 8. Workflow checklist

Before a full production run, confirm the following:

- the input directory and data are avaialble
- the output directory is writable
- the `casename`, `experiment_id` and `osubdir` are correct
- the branch and parent experiment metadata are consistent
- the output files are repacked and validated before publication

This is the standard pattern for a minimal but realistic `cmor4cmip7` workflow: prepare the recipe, fill in the model and experiment metadata, run the program, and validate the output against the CMIP7 rules.
