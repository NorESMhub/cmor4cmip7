# Receipes

Configurations of a particular experiment to be CMORized are provided as the following Fortran namelists, which are regarded as a **recipe** to instruct the `cmor4cmip7` program to CMORize the experiment.

These Fortran namelists are provided as command line options to the `cmor4cmip7` executabel:
```bash
$ bin/cmor4cmip7 -h
 Usage: cmor4cmip7 <system.nml> <model.nml><experiment.nml> <variables.nml>
```

For example,
```bash
pnml=/diagnostics/CMOR/cmor4cmip7/recipes/template
./cmor4cmip7 ${pnml}/system.nml ${pnml}/model.nml ${pnml}/experiment.nml ${pnml}/variables.nml
```

The following subsections explain how to update the namelists accordingly for different model versions and experiments.

