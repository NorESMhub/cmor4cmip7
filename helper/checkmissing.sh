#!/usr/bin/env bash

# ----------------------- Description --------------------------------
# Script to generate a subset of variables (e.g., $varfile_miss)
# by comparing the cmorized datasets with the full list $varfile_full

# ----------------------- USER EDIT ----------------------------------
# cmorized output
cmordir=/scratch/yanchun/cmorout/NorESM3-LM/piControl/v20261021

# full variable list
varfile_full=/diagnostics/CMOR/cmor4cmip7/recipes/NorESM3-LM/piControl/v20261021/variables.nml

# list of missing variables (to keep doing cmorization)
varfile_miss=/diagnostics/CMOR/cmor4cmip7/recipes/NorESM3-LM/piControl/v20261021/variables_miss.nml
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
