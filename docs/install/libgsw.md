# `GSW-Fortran`

Download the code and build with the compiler toolchains.

## Download the code

```bash

# locate source code under `cmor4cmip7`
cd path/to/cmor4cmip7cmor/GSW-Fortran
# check cmor version
git branch -a   # * v3.05-7

# assume it is v3.05-7. therefore, set TAG as v3.05-7
TAG=v3.05-7
```
## Build library
You will decide to build the `GSW-Fortran` library with the GNU or Intel toolchain.

### Build with GNU toolchain

Load GNU toolchain:
```bash
module purge
module load GCCcore/13.2.0
```
Build with GNU:
```bash
cmake .. -DCMAKE_Fortran_COMPILER=gfortran \
       -DCMAKE_Fortran_FLAGS="-O2" \
       -DCMAKE_INSTALL_PREFIX="/path/to/CMOR/GSW-Fortran/${GSWV}-gnu"
make
make install
cd /path/to/CMOR/GSW-Fortran/${GSWV}-gnu
mv include/gsw/* include/
mv share/gsw/* share/
rmdir include/gsw share/gsw
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
cmake .. -DCMAKE_Fortran_COMPILER=ifx \
       -DCMAKE_Fortran_FLAGS="-O2" \
       -DCMAKE_INSTALL_PREFIX="/path/to/CMOR/GSW-Fortran/${GSWV}-intel"
make
make install
cd /path/to/CMOR/GSW-Fortran/${GSWV}-intel
mv include/gsw/* include/
mv share/gsw/* share/
rmdir include/gsw share/gsw
```

:::{note}
You need to update the root path `/path/to/CMOR` of `-DCMAKE_INSTALL_PREFIX=...` to where you want to install the library.
:::
