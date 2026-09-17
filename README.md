# cmor4cmip7

*************************************************************************************

**This version is now under development for CMIP7, and the following documentation is prilemiary**

*************************************************************************************

`cmor4cmip7` is a program to process NorESM3 output for CMIP7 with the Climate Model Output Rewriter ([CMOR](https://github.com/PCMDI/cmor)) interface.


---
Example steps to run cmorization for a `piControl` simulation by NorESM3-LM

## 1. Clone and build
```bash
cd ~/                                             # Install under home as default
tag=v20260914-beta                                # Chose [the latest release](https://github.com/NorESMhub/cmor4cmip7/tags)
git clone git@github.com:NorESMhub/cmor4cmip7.git # Clone the source code
cd cmor4cmip7
git checkout -b $tag tags/$tag                    # Checout the tag
git switch -c $tag                                # Make it as a branch
git submodule update --init --recursive           # Get the submodules
cd build                                          # Build direcotry
./build.sh                                        # Build by default without parallel with Intel compiler, see more with `./build.sh -h`
```

## 2. Update recipes
The receipe templates are found under `cmor4cmip7/recipes/template`:
```bash
cmor4cmip7/recipes/template
├── experiment.nml
├── mapping.json
├── model.nml
├── system.nml
└── variables.nml
```

Update these Fortran namelist files, where find necessary:
* `experiment.nml`
    Configuration for the experiment.
    - **casesname**     : the case name
    - **osubdir**       : the output directory, the version number needs to be the same as the [release tag of the program](https://github.com/NorESMhub/cmor4cmip7/tags).
* `model.nml`
    Configuration for the model.
* `system.nml`
    Configuratoin for the data storage and processing data input and output.
    - **ibasedir**      : root directory where the case is stored
    - **obasedir**      : root directory when the cmorized data is stored
* `variables.nml`
    List of variables (as [CMIP7 compound name](https://wcrp-cmip.github.io/cmip7-guidance/docs/CMIP7/Branded_Variables/#variable-names)) to be cmorized.
    Use `!` as a Fortran comment mark to skip the line (thus variable(s)).

As for a test, you will only need to replace `obasedir` in the `system.nml` with a directory you intent to store the CMOR output, e.g., `/scracht/<your_user_name>/cmorout`.

Note, these are Fortran namelist files, so general Fortran rule applies when modifying these namelists.

## 3. Run the cmorization
```bash
cd ~/cmor4cmip7/bin
source load_modules_intel.sh
pnml=$HOME/cmor4cmip7/recipes/template
./cmor ${pnml}/system.nml ${pnml}/model.nml ${pnml}/experiment.nml ${pnml}/variables.nml
```

## 4. Check the data 
The cmorized data will be located under e.g., `/scratch/$USER/cmorout`

## 5. Technically validate the data
(refer: cmip7validate [README](https://github.com/NorESMhub/cmip7validate#technically-validate-the-cmip7-data-by-noresm3))

### 5.1 Checkout 'cmip7validate'
```bash
cd ~
git clone git@github.com:NorESMhub/cmip7validate.git
```
### 5.2 Update the configuration of the experiment
update the value correspondingly to the cmorized experiment, in `params.yml`. Note tte version number is updated accordingly.

### 5.3 Build and execute the validation
```bash
cd ~/cmip7validate
./build.sh
```
### 5.4 Check the result
find the generated book/webpage by default at:
```
https://ns9560k.web.sigma2.no/datalake/diagnostics/cmip7validate
```

