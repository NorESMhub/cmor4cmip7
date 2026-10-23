#!/usr/bin/env bash

# ------------------ USER INPUT SECTION ------------------------------------
pnml=../recipes/NorESM3-LM/piControl/v20261022

sysnml=${pnml}/system.nml
modnml=${pnml}/model.nml
expnml=${pnml}/experiment.nml
varnml=${pnml}/variables.nml
#varnml=${pnml}/variables_miss.nml

compiler=gnu            # gnu or intel
runtype=parallel        # serial, parallel or debug

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
#     if [ $compiler == "intel" ]; then
        ##export PATH=/usr/lib64/openmpi/bin:$PATH
        #mpirun=/cluster/software/impi/2021.10.0-intel-compilers-2023.2.1/mpi/2021.10.0/bin/mpirun
        #mpirun=/cluster/software/OpenMPI/4.1.6-intel-compilers-2023.2.1/bin/mpirun
        #mpirun --mca oob_tcp_if_include eth0 --mca pml ^ucx --mca osc ^ucx --mca btl tcp,vader,self --mca coll_hcoll_enable 0 --bind-to none \
            #-n 4 ./cmor4cmip7_mpi $sysnml $modnml $expnml $varnml
#     fi

      export PATH=/usr/lib64/openmpi/bin:$PATH
      mpirun --mca oob_tcp_if_include eth0 --mca pml ^ucx --mca osc ^ucx --mca btl tcp,vader,self -mca coll_hcoll_enable 0 \
          -n 8 ./cmor4cmip7_mpi $sysnml $modnml $expnml $varnml
      ;;
    "debug")
      export LD_LIBRARY_PATH=/cluster/software/GCCcore/13.2.0/lib64:$LD_LIBRARY_PATH
      gdb --args ./cmor4cmip7 $sysnml $modnml $expnml $varnml
esac

echo "-------------------------------"
echo "CMOR ends:"
date
echo "-------------------------------"


