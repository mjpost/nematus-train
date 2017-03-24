#!/bin/bash

#$ -S /bin/bash -V -cwd -j y
#$ -l h_rt=168:00:00

. params.txt

# Load the GPU-specific commands if necessary
if [[ $device = "gpu" ]]; then
    . gpu.sh
fi

devno=$($TRAIN/get-gpus.sh)
echo "Using device gpu$devno"

THEANO_FLAGS=mode=FAST_RUN,floatX=float32,device=$device$devno,on_unused_input=warn python config.py
