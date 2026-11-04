# cmor4cmip7

## Introduction
`cmor4cmip7` is a program to process [NorESM3](https://noresm-docs.readthedocs.io/en/main) output for [CMIP7](https://wcrp-cmip.org/cmip-phases/cmip7) with the Climate Model Output Rewriter ([CMOR](https://github.com/PCMDI/cmor)) interface.

Formats and metadata of scientific data genererated by different Earth System Models (ESM) can differs sustantially among each other. The [CMIP7 Data Request](https://wcrp-cmip.org/cmip-phases/cmip7/cmip7-data-request/) is developed to hamonise data analysis for climate studies with different model output. The [PCMDI CMOR library](https://cmor.llnl.gov) is provided as a software interface (with C, Fortran and Python languages) between the data request and the model output.

The `cmor4cmip7` is built with the CMOR Fortran interface, the *PCMDI CMOR library* to process the NorESM3 model output acoording to the *CMIP7 Data Request protocol*. It is, however, possible to adapt to process other ESM output of similar model architecure, e.g., the NCAR/CESM model families.

The program runs as a command line tool:
```bash
$ ./cmor4cmip7 system.nml model.nml experiment.nml variables
```

The full documentaion is at [https://cmor4cmip7.readthedocs.io](https://cmor4cmip7.readthedocs.io/en/stable/index.html).

## Table of contents:
* [Tutorial](https://cmor4cmip7.readthedocs.io/en/stable/tutorial.html)
* [Installation](https://cmor4cmip7.readthedocs.io/en/stable/install/intro.html)
* [Receipes](https://cmor4cmip7.readthedocs.io/en/stable/recipes/intro.html)
* [Developer’s Guide](https://cmor4cmip7.readthedocs.io/en/stable/develop/intro.html)
* [FAQ](https://cmor4cmip7.readthedocs.io/en/stable/FAQ.html)

## License

This project is licensed under the [MIT License](LICENSE).
