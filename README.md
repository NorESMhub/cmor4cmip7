# cmor4cmip7

*************************************************************************************

**This version is now under development for CMIP7, and the following documentation is prilemiary**

*************************************************************************************

`cmor4cmip7` is a program to process NorESM3 output for CMIP7 with the Climate Model Output Rewriter ([CMOR](https://github.com/PCMDI/cmor)) interface.


---
The example below assumes a `piControl` experiment for the `UKESM-3-LL` model, but the workflow is the same for other experiments and model configurations.

## 1. Clone the source and build the program

```bash
cd ~/                                             # Install under home as default
tag=v20260917-beta                                # Chose [the latest release](https://github.com/NorESMhub/cmor4cmip7/tags)
git clone git@github.com:NorESMhub/cmor4cmip7.git # Clone the source code
cd cmor4cmip7
git checkout -b $tag tags/$tag                    # Checout the tag
git switch -c $tag                                # Make it as a branch
git submodule update --init --recursive           # Get the submodules
cd build                                          # Build direcotry
./build.sh                                        # Build (by default) with Intel compiler as a serial program, see more with `./build.sh -h`
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
mkdir -p UKESM-3-LL/piControl
cp -r template/* UKESM-3-LL/piControl/
```

This keeps the default templates intact and gives you a clean experiment-specific recipe set.

## 3. Edit the namelist files

The core CMOR configuration is defined in four Fortran namelist files. They are not YAML or JSON files; they follow Fortran namelist syntax and must be edited carefully.

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
 mapfile       = '../recipes/template/mapping.json'
 createsubdirs = .false.
 forcefilescan = .true.
 verbose       = .false.
/
```

For a first test run, it is often enough to change `obasedir` to a writable directory under your scratch or home space.

### 3.2 `model.nml`

This file defines the model identity and model-specific configuration.

Key entries:

- `source_id`: the CMIP7 model/source identifier, for example `UKESM-3-LL`
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
 casename               = 'n1850.ne16pg3_tn14.noresm3_0_beta22.bdmc2_1p2.20260811',
 osubdir                = 'UKESM-3-LL/piControl/v20260917',
 experiment_id          = 'piControl',
 activity_id            = 'CMIP',
 mip_era                = 'CMIP7',
 realization_index      = 'r1',
 initialization_index   = 'i1',
 physics_index          = 'p1',
 forcing_index          = 'f1',
 year1                  = 1346,
 yearn                  = 1395,
 month1                 = 1,
 monthn                 = 12,
/
```
:::{important}
**Code and dataset versions:**
The processed dataset version should match the [code release tag](https://github.com/NorESMhub/cmor4cmip7/tags). This keeps the output traceable and reproducable. It will be easiber to identify errors in the CMORized and published datasets, and facilitate the [data errata record and retract processes](https://errata.esgf.io/static/index.html).
:::

### 3.4 `variables.nml`

This file lists the CMIP7 branded variables to be CMORized. Each entry is a variable compound name, and inactive entries can be commented out with `!`.

Example:

```fortran
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

## 4. Run the CMORization

Once the namelists are correct, run the program from the executable directory:

```bash
cd ~/cmor4cmip7/bin
source load_modules_intel.sh

pnml=$HOME/cmor4cmip7/recipes/UKESM-3-LL/piControl
./cmor ${pnml}/system.nml ${pnml}/model.nml ${pnml}/experiment.nml ${pnml}/variables.nml
```

If the project was built with GNU Fortran, use the GNU module script instead:

```bash
source load_modules_gnu.sh
```

The program will read the namelists, identify the target inputs, and generate CMIP7-style output files in the configured output directory.

## 5. Inspect the output

After the run, check the output directory you set in `obasedir`, for example:

```bash
ls -l /scratch/$USER/cmorout
```

The generated data should follow the CMIP7 directory structure and naming conventions implied by the CMIP7 data request and the configured experiment metadata.

## 6. Validate the generated files

A technical validation step is strongly recommended before publishing or distributing the data. The project provides a separate validation tool for this purpose.

**Clone the code**
```bash
cd ~
git clone git@github.com:NorESMhub/cmip7validate.git
```

**Update the validation configuration**
The configuration needs to match your experiment, for example in `params.yml`:

```yaml
cmorout         : /scratch/yanchun/cmorout
source_id       : UKESM-3-LL
experiment_id   : piControl
variant_label   : r1i1p1f1
grid_label      : g143
version         : v20260917
```
The data version number in the `params.yml` needs to be updated as the same as in the `experiment.nml`.

Then run the validation and check the generated report.
**Build and execute the validation**
```bash
cd ~/cmip7validate
./build.sh
```
**Check the result**
Find the generated book/webpage by default at:
```
https://ns9560k.web.sigma2.no/datalake/diagnostics/cmip7validate
```
## 7. Workflow checklist

Before a full production run, confirm the following:

- the input directory and data are avaialble
- the output directory is writable
- the `casename`, `experiment_id` and `osubdir` are correct
- the branch and parent experiment metadata are consistent
- the output files are validated before publication

This is the standard pattern for a minimal but realistic `cmor4cmip7` workflow: prepare the recipe, fill in the model and experiment metadata, run the program, and validate the output against the CMIP7 rules.
