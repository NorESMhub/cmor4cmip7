# Introduction

`cmor4cmip7` is a program to process [NorESM3](https://noresm-docs.readthedocs.io/en/main) output for [CMIP7](https://wcrp-cmip.org/cmip-phases/cmip7) with the Climate Model Output Rewriter ([CMOR](https://github.com/PCMDI/cmor)) interface.

Formats and metadata of scientific data genererated by different Earth System Models (ESM) can differs sustantially among each other. The [CMIP7 Data Request](https://wcrp-cmip.org/cmip-phases/cmip7/cmip7-data-request/) is developed to hamonise data analysis for climate studies with different model output. The [PCMDI CMOR library](https://cmor.llnl.gov) is provided as a software interface (with C, Fortran and Python languages) between the data request and the model output.

The `cmor4cmip7` is built with the CMOR Fortran interface, the *PCMDI CMOR library* to process the NorESM3 model output acoording to the *CMIP7 Data Request protocol*. It is, however, possible to adapt to process other ESM output of similar model architecure, e.g., the NCAR/CESM model families.

```{tableofcontents}
```
