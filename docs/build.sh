#!/usr/bin/env bash

source /cluster/software/Miniforge3/24.1.2-0/etc/profile.d/conda.sh
conda activate rtd-env

# build with jupyter-book
#jupyter-book build .

# build with sphinx
READTHEDOCS_OUTPUT='_build'
jupyter-book config sphinx ./
python -m sphinx -E -a -T -b html -d _build/doctrees -D language=en . $READTHEDOCS_OUTPUT/html
#python -m sphinx -T -b latex -d _build/doctrees -D language=en . $READTHEDOCS_OUTPUT/pdf 

# sync to ns2345k
rsync -vazu --delete _build/html/ /nird/datapeak/NS2345K/www/people/yanchun/cmor4cmip7/
