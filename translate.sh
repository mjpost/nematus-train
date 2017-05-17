#!/bin/sh

if [[ -e ./params.txt ]]; then
    . ./params.txt
fi

in=data/validate.bpe.$SRC
out=data/validate.output
model=model/model.npz
if [[ -z $1 ]]; then
  in=$1
fi
if [[ -z $2 ]]; then
  out=$2
fi
if [[ -z $3 ]]; then
  model=$3
fi

# Load the GPU-specific commands if necessary
[[ $device = "gpu" ]] && . ./gpu.sh

THEANO_FLAGS=mode=FAST_RUN,floatX=float32,device=$device,on_unused_input=warn python $NEMATUS/nematus/translate.py \
     -m $model \
     -i $in \
     -o $out \
     -k 12 -n -p 1
