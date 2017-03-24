#!/bin/sh

. ./params.txt

# Load the GPU-specific commands if necessary
[[ $device = "gpu" ]] && . ./gpu.sh

THEANO_FLAGS=mode=FAST_RUN,floatX=float32,device=$device,on_unused_input=warn python $nematus/nematus/translate.py \
     -m model/model.npz \
     -i data/validate.bpe.$SRC \
     -o data/validate.output \
     -k 12 -n -p 1
