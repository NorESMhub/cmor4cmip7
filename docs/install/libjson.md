# `json-fortran`

Download the code and build with the compiler toolchains.

## Download the code

```bash

# locate source code under `cmor4cmip7`
cd path/to/cmor4cmip7cmor/json-fortran
# check cmor version
git branch -a

# assume it is 9.2.1. therefore, set TAG as 9.2.1
JFV=9.2.1
```
## Build library
You will decide to build the `json-fortran` library with the GNU or Intel toolchain.

### Build with GNU toolchain

Load GNU toolchain:
```bash
module purge
module load GCCcore/13.2.0
```
Build with GNU:
```bash
cmake clean
cmake .. -DCMAKE_C_COMPILER=gcc \
       -DCMAKE_Fortran_COMPILER=gfortran \
       -DCMAKE_Fortran_FLAGS="-O2" \
       -DCMAKE_INSTALL_PREFIX="/path/to/CMOR/json-fortran"
make
make install
mv /path/to/CMOR/json-fortran/jsonfortran-gnu-$JFV/ /path/to/CMOR/json-fortran/$JFV-gnu
mkdir -p /path/to/CMOR/json-fortran/$JFV-gnu/include
mv json_*.mod /path/to/CMOR/json-fortran/$JFV-gnu
```
:::{note}
You need to update the root path `/path/to/CMOR` of `-DCMAKE_INSTALL_PREFIX=...` to where you want to install the library.
:::

### Build with Intel toolchain

Load Intel toolchain:
```bash
module purge
module load GCCcore/13.2.0
module load intel-compilers/2023.2.1
```

Build with Intel:
```bash
cmake clean
cmake .. -DCMAKE_C_COMPILER=icc \
       -DCMAKE_Fortran_COMPILER=ifx \
       -DCMAKE_Fortran_FLAGS="-O2" \
       -DCMAKE_INSTALL_PREFIX="/path/to/CMOR/json-fortran"
make
make install
mv  /path/to/CMOR/json-fortran/jsonfortran-intelllvm-$JFV  //path/to/CMOR/json-fortran/${JFV}-intelllvm
mkdir -p //path/to/CMOR/json-fortran/${JFV}-intelllvm/include
mv json_*.mod //path/to/CMOR/json-fortran/${JFV}-intelllvm/include
```

:::{note}
You need to update the root path `/path/to/CMOR` of `-DCMAKE_INSTALL_PREFIX=...` to where you want to install the library.
:::
