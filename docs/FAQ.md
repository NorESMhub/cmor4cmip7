# FAQ

## How about if program hangs?

If the program stalls or appears to stop without producing output, try the following:

- Rebuild with the Intel toolchain instead of GNU when possible. In practice, the Intel build is often more reliable for this workflow: `./build.sh -p false -c intel`.
- Load the matching environment before running the executable:

```bash
source load_modules_intel.sh
```

- Enable detailed logging in `system.nml`:

```fortran
verbose = .true.
```

- Check that the paths in `system.nml` and the model file list are valid and that the raw input files exist.
- If needed, reduce the task scope to a small subset of variables to isolate the problem.

## How to specify the time length of CMORized file?

The number of records in the cmorized files are determined by:

- the selected time period in `experiment.nml` (`year1`, `yearn`, `month1`, `monthn`)
- the output frequency implied by the variable name and CMIP7 data request
- the native time axis of the raw model output

The CMORized output will contain the number of records (depending on the raw model output frequency, i.e., daily, monthly, or yearly) between `year1`, `month1` and `yearn`, `monthn`. Adjust the temporal settings in `experiment.nml` to specify the number of records in the CMORized files.

:::{important}
When the length of the records is more than 10 years, the `cmor4cmip7` program by default automatically close the NetCDF file and start a new NetCDF file.
:::

For example, if the `experiment.nml` is prescribed as:
```fortran
 ...
 year1                  = 1346,
 yearn                  = 1395,
 month1                 = 1,
 monthn                 = 12,
 ...
 ```
The first file will have the time stamp as `*_134601..-135512.nc`, and then another file from `*_135601-136512.nc` and so on.

If one would like to have first file as `*_134601-134912.nc` and the second one `*_135001-135912.nc` and so on, one can modify the `experiment.nml`, launch the `cmor4cmip7`, and when it finishes the first 5 years, update the `year1` and `yearn` and launch the program again.

## How do I add or customize a dataset?

There are three standard ways to do this:

1. Add or remove entries in `variables.nml`.
   - Each line in `compound_names` is a CMIP7 branded variable.
   - Comment out a variable with `!` to skip it.

```fortran
&variables
    compound_names =
        'ocean.zos.tavg-u-hxy-sea.mon.glb',
        'ocean.agessc.tavg-ol-hxy-sea.mon.glb'
/
```

2. Update the mapping information in `mapping.json` if the variable or metadata needs a custom translation from the model output to the CMIP7 variable definition.

3. Adjust the model/experiment metadata in `model.nml` and `experiment.nml` if the source ID, experiment label, grid label, or branch information needs to be changed.

4. If the variable/dataset is not a standard CMIP7 dataset, you need to hack the corresponding CMIP7 json table file, e.g., `CMIP7_ocean.json` to make a dataset entry as the same compound name in the `variables.nml` and `mapping.json`.

A good workflow is:

- add the variable to `variables.nml`.
- confirm the metadata in `model.nml` and `experiment.nml`.
- check the mapping in `mapping.json`.
- hack the CMIP7 CV json file (`CMIP7_*.json`), if necessary.
- rerun the program with `verbose = .true.` to inspect the generated CMIP7 metadata and output structure.
