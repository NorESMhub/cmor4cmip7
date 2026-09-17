# Installation

The section describles how to install the dependencies and eventually build the `cmor4cmip7` Fortran program.

If you are goint to run the program on [NIRD](https://documentation.sigma2.no/files_storage/nird_lmd.html), you can use the already built following libraries which are sepecified in the `Makefile` in the `cmor4cmip/build`. If you want to run the program on other machines, you need to build the following depencies:

- [PCMDI CMOR library](libcmor.md)
- [TOES-10/GSW-Fortran](libgsw.md)
- [json-fortran](libjson.md)
