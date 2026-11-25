#!/usr/bin/env bash
#
# Run the cmor4cmip7 diagnostic for one recipe.
#
#   runtype=serial     ./cmor4cmip7
#   runtype=parallel   mpirun -n $nprocs ./cmor4cmip7_mpi
#   runtype=debug      ./cmor4cmip7 under gdb
#
# The script returns the exit status of the diagnostic.

set -uo pipefail

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

nprocs=32           # number of MPI ranks, only used by runtype=parallel
# --------------------------------------------------------------------------

die() {
  echo "ERROR: $*" >&2
  exit 1
}

# The module scripts and the executables are resolved relative to this script,
# so the run also works from cron or from any other working directory.
cd "$(dirname "$0")" || die "cannot change directory to '$(dirname "$0")'"

# --- sanity checks -----------------------------------------------------------
# A typo here used to load the modules, start CMOR and let it die with
# "cannot find namelist file" (or, for a misspelt runtype, do nothing at all).
case "$compiler" in
  intel) modules=load_modules_intel.sh ;;
  gnu)   modules=load_modules_gnu.sh ;;
  *) die "compiler must be 'intel' or 'gnu' (got '$compiler')" ;;
esac

case "$runtype" in
  serial|parallel|debug) ;;
  *) die "runtype must be 'serial', 'parallel' or 'debug' (got '$runtype')" ;;
esac

for f in "$sysnml" "$modnml" "$expnml" "$varnml"; do
  [[ -f $f ]] || die "namelist file not found: $f"
done

if [[ $runtype == parallel ]]; then
  [[ $nprocs =~ ^[0-9]+$ ]] || die "nprocs must be a positive integer (got '$nprocs')"
  (( nprocs > 0 )) || die "nprocs must be a positive integer (got '$nprocs')"
fi

# --- signal handling ---------------------------------------------------------
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
    # Signal the whole process group started by setsid, but only if the child
    # really is its leader: setsid forks when the caller already leads a group,
    # in which case "$child_pid" is not a process group id.
    if [[ $(ps -o pgid= -p "$child_pid" 2>/dev/null | tr -d ' ') == "$child_pid" ]]; then
      kill -s "$signal" -- "-$child_pid" 2>/dev/null || true
      sleep 2
      kill -KILL -- "-$child_pid" 2>/dev/null || true
    else
      kill -s "$signal" "$child_pid" 2>/dev/null || true
      sleep 2
      kill -KILL "$child_pid" 2>/dev/null || true
    fi
    wait "$child_pid" 2>/dev/null || true
    child_pid=
  fi
  exit "$exit_status"
}

trap 'handle_signal INT 130' INT
trap 'handle_signal TERM 143' TERM
trap 'handle_signal HUP 129' HUP

# --- run ---------------------------------------------------------------------
echo "-------------------------------"
echo "CMOR starts:"
date
echo "-------------------------------"

source "$modules"

case "$runtype" in
  serial)
    exe=./cmor4cmip7
    cmd=("$exe" "$sysnml" "$modnml" "$expnml" "$varnml")
    ;;
  parallel)
    exe=./cmor4cmip7_mpi
    cmd=(mpirun -n "$nprocs" "$exe" "$sysnml" "$modnml" "$expnml" "$varnml")
    ;;
  debug)
    exe=./cmor4cmip7
    ;;
esac

[[ -x $exe ]] || die "executable not found: $PWD/${exe#./}  (build it with ../build/build.sh)"

if [[ $runtype == debug ]]; then
  # gdb needs the terminal, so the debuggee is not started detached
  export LD_LIBRARY_PATH="/cluster/software/GCCcore/13.2.0/lib64:${LD_LIBRARY_PATH:-}"
  gdb --args "$exe" "$sysnml" "$modnml" "$expnml" "$varnml"
  status=$?
else
  run_command "${cmd[@]}"
  status=$?
fi

echo "-------------------------------"
echo "CMOR ends:"
date
echo "-------------------------------"

if (( status != 0 )); then
  echo "CMOR exited with status $status" >&2
fi

# propagate the result, so that a batch system or a wrapper script can tell a
# successful run from a failed one
exit "$status"


