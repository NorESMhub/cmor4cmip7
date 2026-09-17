# `cmor4cmip7`

## Clone and build cmor4cmip7

:::{note}
If you will run `cmor4cmip7` tool on NIRD, you don't need build the other depencies and they are already linked in the `Makefile`. If you will run the program on other mainces, please install the `PCMDI CMOR`, `GSW-Fortran` and `json-fortran` libraries first.
:::

Assume that you have gone through the [Tutorial](#clone-build) and have cloned the right version of source code (including its submodules), you will be able to build/rebuild the program with different options of compilers of serial or parallel version.

The helper script `build.sh` helps to wrap the building options:
```bash
$ cd cmor4cmip4/build
$ ./build.sh -h
Usage:
./build.sh
  -p --ifmpi=false|true
  -c --compiler=gnu|intel
./build.sh --ifmpi=true|false --compiler=intel|gnu
./build.sh -p true|false -c intel|gnu
Example:
./build.sh --ifmpi=false --compiler=intel
```

So for example:
* `./build.sh -p false -c gnu` will build with the GNU compiler as a serial program `cmor4cmip7` as the exectuable (as default for `./build.sh` without options).
* `./build.sh -p true -c gnu` will build a parallel version of the program with executable as `cmor4cmip4_mpi`.
* `./build.sh -p false -c intel`, the same but with Intel compiler.
* `./build.sh -p true -c intel`, the same but with MPI enabled.

:::{caution}
As of Thu 17 Sept. 2026, the MPI version with Intel compiler does not work properly.
:::

:::{tip}
Modify the corresponding flags of `Makefile` under `cmor4cmip7/build` to change the build options, e.g. with debug `-g` and optimization level `-O2`.
:::
