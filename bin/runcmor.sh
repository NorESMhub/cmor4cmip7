#!/usr/bin/env bash

# ------------------ USER INPUT SECTION ------------------------------------
pnml=../recipes/NorESM3-LM/piControl/r1i1p1f1/v20261028

sysnml=${pnml}/system.nml
modnml=${pnml}/model.nml
expnml=${pnml}/experiment.nml
varnml=${pnml}/variables.nml
#varnml=${pnml}/variables_dev.nml
#varnml=${pnml}/variables_miss.nml

# gnu or intel
compiler=intel
# serial, parallel or debug
runtype=serial

num_threads=8       # number of threads, only for parallel run type
# --------------------------------------------------------------------------

echo "-------------------------------"
echo "CMOR starts:"
date
echo "-------------------------------"

case $compiler in
  "intel")
    source load_modules_intel.sh;;
  "gnu")
    source load_modules_gnu.sh;;
esac

case $runtype in
    "serial")
      ./cmor4cmip7 $sysnml $modnml $expnml $varnml
      ;;
    "parallel")
      mpirun -n $num_threads ./cmor4cmip7_mpi $sysnml $modnml $expnml $varnml
      ;;
    "debug")
      export LD_LIBRARY_PATH=/cluster/software/GCCcore/13.2.0/lib64:$LD_LIBRARY_PATH
      gdb --args ./cmor4cmip7 $sysnml $modnml $expnml $varnml
esac

echo "-------------------------------"
echo "CMOR ends:"
date
echo "-------------------------------"


