# cmor4cmip7

*************************************************************************************

**This version is now under development for CMIP7, and the following documentation is prilemiary**

*************************************************************************************

`cmor4cmip7` is a program to process NorESM3 output for CMIP7 with the Climate Model Output Rewriter ([CMOR](https://github.com/PCMDI/cmor)) interface.


---
Example steps to run cmorization for a `piControl` simulation by NorESM3-LM

## Clone and build
```bash
cd ~/
tag=v20260612-alpha
git clone git@github.com:NorESMhub/cmor4cmip7.git
git checkout tags/v20260612-alpha
git switch -c v20260612-alpha
cd ~/cmor4cmip7/build
./build.sh
```

## Update recipes
update the information under `cmor4cmip7/recipes/test`, where find necessary
* experiment.nml    : about the experiment
* model.nml         : about the model
* system.nml        : about data input/output
* variables.nml     : activate/deactivate variables to be cmorized

One particular part is to update the `obasedir` in the `system.nml` to a directory you will store the cmorized data, either temporarilly or permanentally. That is, replace the value of `obasedir` with e.g., `/scracht/<your_user_name>/cmorout`.

Note, these are Fortran namelist files, so general Fortran rule applies when modifying these namelists.

## Run the cmorization
```bash
cd ~/cmor4cmip7/bin

pnml=$HOME/cmor4cmip7/recipes/test
./cmor ${pnml}/system.nml ${pnml}/model.nml ${pnml}/experiment.nml ${pnml}/variables.nml
```

## Check the data 
The cmorized data will be located under e.g., `/scratch/$USER/cmorout`

## Technically validate the data
### Checkout 'cmip7validate'
```bash
cd ~
git clone git@github.com:NorESMhub/cmip7validate.git
```
### Update the configuration of the experiment
update the value correspondingly to the cmorized experiment, in `params.yml`

### Build and execute the validation
```bash
cd ~/cmip7validate
./build.sh
```
### Check the result
find the generated book/webpage by default at:
```
https://ns9560k.web.sigma2.no/datalake/diagnostics/cmip7validate
```

