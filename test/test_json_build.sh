#/usr/bin/env bash

gfortran -c ../source/json_value_module.F90 -I/cluster/software/json-c/0.17-GCCcore-13.2.0/include -L/cluster/software/json-c/0.17-GCCcore-13.2.0/lib -ljson-c
gfortran -c ../source/json_string_utilities.F90 -I/cluster/software/json-c/0.17-GCCcore-13.2.0/include -L/cluster/software/json-c/0.17-GCCcore-13.2.0/lib -ljson-c
gfortran -c ../source/json_value_module.F90 -I/cluster/software/json-c/0.17-GCCcore-13.2.0/include -L/cluster/software/json-c/0.17-GCCcore-13.2.0/lib -ljson-c
gfortran -c ../source/json_module.F90 -I/cluster/software/json-c/0.17-GCCcore-13.2.0/include -L/cluster/software/json-c/0.17-GCCcore-13.2.0/lib -ljson-c
gfortran -c ../source/json_file_module.F90 -I/cluster/software/json-c/0.17-GCCcore-13.2.0/include -L/cluster/software/json-c/0.17-GCCcore-13.2.0/lib -ljson-c
gfortran -c ../source/json_module.F90 -I/cluster/software/json-c/0.17-GCCcore-13.2.0/include -L/cluster/software/json-c/0.17-GCCcore-13.2.0/lib -ljson-c

gfortran -c test_json1.F90 -I/cluster/software/json-c/0.17-GCCcore-13.2.0/include -L/cluster/software/json-c/0.17-GCCcore-13.2.0/lib -ljson-c

#gfortran -o test_json json_file_module.o json_value_module.o -I/cluster/software/json-c/0.17-GCCcore-13.2.0/include -L/cluster/software/json-c/0.17-GCCcore-13.2.0/lib -ljson-c
gfortran -o test_json1 test_json1.F90 -I./ -L/cluster/software/json-c/0.17-GCCcore-13.2.0/lib -ljson-c


