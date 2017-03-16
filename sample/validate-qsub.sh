#!/bin/bash

if [[ -z $1 ]]; then
    echo "Usage: validate-qsub.sh MODEL"
    exit 1
fi

basedir=$(dirname $0)

# Calls validate.sh with qsub. Adjust flags to your needs.
qsub -S /bin/bash -V -cwd -q gpu.q -l gpu=1,h_rt=4:00:00 -j y -o data/ $basedir/validate.sh $1
