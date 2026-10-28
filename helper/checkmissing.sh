#!/usr/bin/env bash
set -e

# ----------------------- Description --------------------------------
# Script to generate a subset of variables (e.g., $varfile_miss)
# by comparing the cmorized datasets with the full list $varfile_full

# ----------------------- USER EDIT ----------------------------------
# set the path where cmorized output is stored
cmordir=/scratch/yanchun/cmorout/NorESM3-LM/piControl/r1i1p1f1/v20261028

# set the full variable name list which was used for the CMORization
varfile_full=/diagnostics/CMOR/cmor4cmip7/recipes/NorESM3-LM/piControl/r1i1p1f1/v20261028/variables.nml

# set the name of list for missing variables after CMORization. This list  will be generated, and will be used for an incremental CMORisation.
varfile_miss=/diagnostics/CMOR/cmor4cmip7/recipes/NorESM3-LM/piControl/r1i1p1f1/v20261028/variables_miss.nml
# ----------------------- --------- ---------------------------

# Create list of missing variables
if [ -f ${varfile_miss} ]; then
    while true; do
      echo "${varfile_miss} already exist"
      read -r -p "Overwrite? (y/n) " answer
        case "${answer,,}" in
            y|yes)
              rm -f ${varfile_miss} && touch ${varfile_miss}
              break ;;
            n|no)
              echo "aborted; you can edit the file manually"; exit 1 ;;
            *)
              echo "Please answer y or n." ;;
        esac
    done
  else
    touch ${varfile_miss}
fi

# Find missing files
pattern="^[[:space:]]*'(ocean|ocnBgchem)"
while IFS= read -r str || [[ -n $str ]]
do
    if [[ $str =~ $pattern ]]; then
        brand_name=$(echo $str |tr -d "'" |cut -d. -f2-5 |tr '.' '_')
        if [[ -n $(find $cmordir -maxdepth 1 -type f -name "${brand_name}_*_r*i*p*f[0-9.][_.]*nc" -print -quit) ]]; then
          echo "${str/#?/!}" >>${varfile_miss}
        else
          echo "${str}" >>${varfile_miss}
        fi
    else
      echo "$str" >> ${varfile_miss}
    fi
done < ${varfile_full}


echo "-----------------------------------------------------"
echo "List of variables that are missing are generated in:"
echo ${varfile_miss}
echo "-----------------------------------------------------"
