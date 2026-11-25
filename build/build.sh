#!/usr/bin/env bash
#
# Configure the environment and build the cmor4cmip7 diagnostic.
#
# Usage: ./build.sh [-p|--ifmpi true|false] [-c|--compiler gnu|intel]

# Fail on unset variables and on broken pipelines. The individual steps are
# checked explicitly below so that the message names the step that failed.
set -uo pipefail

# Defaults. Only one machine is supported so far; the makefiles are named
# Makefile.<machine>_<compiler>[_mpi].
mach=nird
mpi_flag=false
compiler=intel

usage() {
  cat <<'EOF'
Usage: ./build.sh [options]

Options:
  -p, --ifmpi true|false      build the MPI executable (default: false)
  -c, --compiler gnu|intel    compiler toolchain to use (default: intel)
  -h, --help                  show this message and exit

Examples:
  ./build.sh
  ./build.sh -p true -c gnu
  ./build.sh --ifmpi=false --compiler=intel
EOF
}

die() {
  echo "ERROR: $*" >&2
  echo "*** EXITING THE SCRIPT" >&2
  exit 1
}

# --- option parsing ----------------------------------------------------------
# Both spellings are handled here and validated further down: previously only
# the --key=value form was checked, so '-p truee' was accepted and later used
# as a shell command ('if ${mpi_flag}'), silently building the serial version.
while (( $# > 0 )); do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    -p|--ifmpi)
      (( $# >= 2 )) || die "no value given for $1 (true|false)"
      mpi_flag=$2
      shift 2
      ;;
    --ifmpi=*)
      mpi_flag=${1#*=}
      shift
      ;;
    -c|--compiler)
      (( $# >= 2 )) || die "no value given for $1 (gnu|intel)"
      compiler=$2
      shift 2
      ;;
    --compiler=*)
      compiler=${1#*=}
      shift
      ;;
    *)
      usage >&2
      die "option '$1' not recognised"
      ;;
  esac
done

case "$mpi_flag" in
  true|false) ;;
  *) die "'ifmpi' must be either 'true' or 'false' (got '$mpi_flag')" ;;
esac

case "$compiler" in
  intel|gnu) ;;
  *) die "'compiler' must be either 'intel' or 'gnu' (got '$compiler')" ;;
esac

# --- select and verify the makefile ------------------------------------------
# The makefiles reference ../source and ../bin, so always build from this
# directory, whatever the caller's working directory is.
cd "$(dirname "$0")" || die "cannot change directory to '$(dirname "$0")'"

if [[ $mpi_flag == true ]]; then
  Makefile=Makefile.${mach}_${compiler}_mpi
  target=cmor4cmip7_mpi
else
  Makefile=Makefile.${mach}_${compiler}
  target=cmor4cmip7
fi

######################################################
#           ** DONT MODIFY BELOW **
######################################################

[[ -f $Makefile ]] || die "makefile '$PWD/$Makefile' not found"

load_module_intel(){
  module purge
  module load GCCcore/13.2.0
  module load intel/2023b               # intel chain w   mpi
  #module load intel-compilers/2023.2.1 # intel chain w/o mpi
  module load HDF5/1.14.3-iompi-2023b
  module load UDUNITS/2.2.28-GCCcore-13.2.0
  module load expat/2.5.0-GCCcore-13.2.0
  module load json-c/0.17-GCCcore-13.2.0
  module load netCDF-Fortran/4.6.1-iompi-2023b
  module load netCDF/4.9.2-iompi-2023b
  module load util-linux/2.39-GCCcore-13.2.0
  module load zlib/1.2.13-GCCcore-13.2.0
}

load_module_gnu(){
  module purge
  module load GCCcore/13.2.0
  module load OpenMPI/4.1.6-GCC-13.2.0  # MPI chain for gfortran
  module load HDF5/1.14.3-gompi-2023b
  module load UDUNITS/2.2.28-GCCcore-13.2.0
  module load expat/2.5.0-GCCcore-13.2.0
  module load json-c/0.17-GCCcore-13.2.0
  module load netCDF-Fortran/4.6.1-gompi-2023b
  module load netCDF/4.9.2-gompi-2023b
  module load util-linux/2.39-GCCcore-13.2.0
  module load zlib/1.2.13-GCCcore-13.2.0
}

# --- toolchain ---------------------------------------------------------------
# bin/load_modules_<compiler>.sh sets up the same environment for running the
# diagnostic; keep the module versions in the two places in sync.
echo "Loading the $compiler modules ..."
load_module_${compiler}

# Fail here with a clear message instead of deep inside the compile step if the
# toolchain did not load (the makefiles take the include path from the module).
fc=$(sed -n 's/^FC *= *//p' "$Makefile" | head -n 1)
[[ -n $fc ]] || die "cannot read FC from $Makefile"
command -v "$fc" >/dev/null 2>&1 || \
  die "compiler '$fc' not found after loading the $compiler modules"
[[ -n ${EBROOTNETCDFMINFORTRAN:-} ]] || \
  die "netCDF-Fortran is not loaded (EBROOTNETCDFMINFORTRAN is unset)"

# --- build -------------------------------------------------------------------
echo "Building $target from $Makefile ..."
make clean -f "$Makefile" || die "'make clean' failed"
make -f "$Makefile" || die "build failed"

[[ -x ../bin/$target ]] || die "build finished but ../bin/$target was not created"
echo "Build finished: $(cd ../bin && pwd)/$target"
