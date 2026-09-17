# `PCMDI CMOR`

Download the code and build with the compiler toolchains.

## Download the code

```bash

# locate source code under `cmor4cmip7`
cd path/to/cmor4cmip7cmor/cmor
# check cmor version
git branch -a
* 3.15.3

# assume it is 3.15.3. therefore, set TAG as 3.15.3
TAG=3.15.3
```
## Build library
You will decide to build the `CMOR` library with the GNU or Intel toolchain.

### Build with GNU toolchain

Load GNU toolchain:
```bash
module purge
module load GCCcore/13.2.0
module load intel-compilers/2023.2.1
module load HDF5/1.14.3-iompi-2023b
module load UDUNITS/2.2.28-GCCcore-13.2.0
module load expat/2.5.0-GCCcore-13.2.0
module load json-c/0.17-GCCcore-13.2.0
module load netCDF-Fortran/4.6.1-iompi-2023b
module load netCDF/4.9.2-iompi-2023b
module load util-linux/2.39-GCCcore-13.2.0
module load zlib/1.2.13-GCCcore-13.2.0
```
Build with GNU:
```bash
prefix=/path/to/CMOR/cmorlib/$TAG/gnu
[ ! -d $prefix ] && mkdir -p $prefix
make clean
./configure CC=gcc CFLAGS=-O2 FC=gfortran FCFLAGS=-O2\
  --prefix=$prefix \
  --enable-fortran \
  --with-json-c \
  --with-uuid \
  --with-udunits2 \
  --with-netcdf \
  --without-python

make
make install
```
:::{note}
You need to update the root path `/path/to/CMOR` of `prefix=...` to where you want to install the library.
:::

### Build with Intel toolchain

Load Intel toolchain:
```bash
module purge
module load GCCcore/13.2.0
module load intel-compilers/2023.2.1
module load HDF5/1.14.3-iompi-2023b
module load UDUNITS/2.2.28-GCCcore-13.2.0
module load expat/2.5.0-GCCcore-13.2.0
module load json-c/0.17-GCCcore-13.2.0
module load netCDF-Fortran/4.6.1-iompi-2023b
module load netCDF/4.9.2-iompi-2023b
module load util-linux/2.39-GCCcore-13.2.0
module load zlib/1.2.13-GCCcore-13.2.0
```

Build with Intel:
```bash
prefix=/path/to/CMOR/cmorlib/$TAG/intel
[ ! -d $prefix ] && mkdir -p $prefix
make clean
./configure CC=icc FC=ifx CFLAGS=-O2 FCFLAGS=-O2 \
  --prefix=$prefix \
  --enable-fortran \
  --with-json-c \
  --with-uuid \
  --with-udunits2 \
  --with-netcdf \
  --without-python

make
#make install
```

:::{note}
You need to update the root path `/path/to/CMOR` of `prefix=...` to where you want to install the library.
:::
