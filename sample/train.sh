#!/bin/bash

. params.txt

# Load the GPU-specific commands if necessary
[[ $device = "gpu" ]] && . gpu.sh

THEANO_FLAGS=mode=FAST_RUN,floatX=float32,device=$device,on_unused_input=warn python config.py
