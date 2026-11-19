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

child_pid=

run_command() {
  setsid "$@" &
  child_pid=$!
  wait "$child_pid"
  local status=$?
  child_pid=
  return "$status"
}

handle_signal() {
  local signal=$1
  local exit_status=$2

  trap - INT TERM HUP
  if [[ -n $child_pid ]]; then
    kill -s "$signal" -- "-$child_pid" 2>/dev/null || true
    sleep 2
    kill -KILL -- "-$child_pid" 2>/dev/null || true
    wait "$child_pid" 2>/dev/null || true
    child_pid=
  fi
  exit "$exit_status"
}

trap 'handle_signal INT 130' INT
trap 'handle_signal TERM 143' TERM
trap 'handle_signal HUP 129' HUP

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
      run_command ./cmor4cmip7 "$sysnml" "$modnml" "$expnml" "$varnml"
      ;;
    "parallel")
      run_command mpirun -n "$num_threads" ./cmor4cmip7_mpi "$sysnml" "$modnml" "$expnml" "$varnml"
      ;;
    "debug")
      export LD_LIBRARY_PATH=/cluster/software/GCCcore/13.2.0/lib64:$LD_LIBRARY_PATH
      run_command gdb --args ./cmor4cmip7 "$sysnml" "$modnml" "$expnml" "$varnml"
esac

echo "-------------------------------"
echo "CMOR ends:"
date
echo "-------------------------------"


