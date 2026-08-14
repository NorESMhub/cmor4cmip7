# cmor4cmip7

*************************************************************************************

**This version is now under development for CMIP7, and the following documentation is prilemiary**

*************************************************************************************

`cmor4cmip7` is a program to process NorESM3 output for CMIP7 with the Climate Model Output Rewriter ([CMOR](https://github.com/PCMDI/cmor)) interface.


---
Example steps to run cmorization for a `piControl` simulation by NorESM3-LM

## 1. Clone and build
```bash
cd ~/
tag=v20260814-beta
git clone git@github.com:NorESMhub/cmor4cmip7.git
cd cmor4cmip7
git checkout -b $tag tags/$tag
git switch -c $tag
git submodule update --init --recursive
cd build
./build.sh
```

hack the CMOR CV (a temporary solution before CMOR CV officially updated)
```
cp /nird/datalake/NS16000B/CMOR/cmor4cmip7/cmor/cmip7-cmor-tables/tables-cvs/cmor-cvs.json ~/cmor4cmip7/cmor/cmip7-cmor-tables/tables-cvs/cmor-cvs.json
```


## 2. Update recipes
update the information under `cmor4cmip7/recipes/test`, where find necessary
* experiment.nml    : about the experiment
* model.nml         : about the model
* system.nml        : about data input/output
* variables.nml     : activate/deactivate variables to be cmorized

As for a test, you will only need to replace `obasedir` in the `system.nml` with a directory you intent to store the CMOR output, e.g., `/scracht/<your_user_name>/cmorout`.

Note, these are Fortran namelist files, so general Fortran rule applies when modifying these namelists.

## 3. Run the cmorization
```bash
cd ~/cmor4cmip7/bin

pnml=$HOME/cmor4cmip7/recipes/test
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
update the value correspondingly to the cmorized experiment, in `params.yml`

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

