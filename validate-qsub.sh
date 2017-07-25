#!/bin/bash

. ./params.txt

if [[ -z $1 ]]; then
    echo "Usage: validate-qsub.sh MODEL"
    exit 1
fi

# Calls validate.sh with qsub. Adjust flags to your needs.
[[ ! -d logs ]] && mkdir logs
qsub -S /bin/bash -V -cwd -j y -o logs/ $QSUB_PARAMS -l h_rt=4:00:00 $TRAIN/validate.sh $1
