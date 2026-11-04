#usage: source load_modules_gnu.sh

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


export OMPI_MCA_oob_tcp_if_include=eth0
export OMPI_MCA_pml=^ucx
export OMPI_MCA_osc=^ucx
export OMPI_MCA_btl=tcp,vader,self
export OMPI_MCA_coll_hcoll_enable=0
export OMPI_MCA_hwloc_base_binding_policy=none
