#!/bin/bash

if [[ -z $1 ]]; then
    echo "Usage: validate-qsub.sh MODEL"
    exit 1
fi

prefix=$1

. ./params.txt

# Load the GPU-specific commands if necessary
if [[ $device = "gpu" ]]; then
  echo "Loading GPU"
  . $TRAIN/gpu.sh
fi

dev=data/validate.bpe.$SRC
ref=data/validate.tok.$TRG
modelname=$(basename $prefix .npz)
out=$dev.$modelname.output

devno=$($TRAIN/get-gpus.sh)
echo "Using device $devno" 

# decode
if [[ -z $AMUNMT ]] || [[ ! -x $AMUNMT/build/bin/amun ]]; then
    echo "\$AMUNMT apparently not installed, too bad --- this is going to take a while!"
    THEANO_FLAGS=mode=FAST_RUN,floatX=float32,device=$device$devno,on_unused_input=warn python $nematus/nematus/translate.py \
        -m $prefix \
        -i $dev \
        -o $out \
        -k 12 -n -p 1
else
cat > config.$modelname.yml <<EOF
# Paths are relative to config file location
relative-paths: yes

# performance settings
beam-size: 12
normalize: yes

# scorer configuration
scorers:
  F0:
    path: $prefix
    type: Nematus

# scorer weights
weights:
  F0: 1.0

# vocabularies
source-vocab: data/train.bpe.$SRC.json
target-vocab: data/train.bpe.$TRG.json

# don't apply BPE because that has already been done
#bpe: model/$SRC$TRG.bpe
debpe: false
EOF

$AMUNMT/build/bin/amun -c config.$modelname.yml -d "$devno" --gpu-threads 1 --i $dev > $out
fi

$TRAIN/postprocess-dev.sh < $out > $out.postprocessed

## get BLEU
BEST=`cat model/model.npz_best_bleu || echo 0`
bleu_output=$($mosesdecoder/scripts/generic/multi-bleu.perl $ref < $out.postprocessed)
echo -e "$prefix\t$bleu_output" >> model/model.npz_bleu_scores
BLEU=`echo $bleu_output | cut -f 3 -d ' ' | cut -f 1 -d ','`
BETTER=`echo "$BLEU > $BEST" | bc`

echo "BLEU = $BLEU"

# save model with highest BLEU
if [ "$BETTER" = "1" ]; then
  echo "new best; saving"
  echo $BLEU > model/model.npz_best_bleu
  ln -sf $(basename $prefix) model/model.npz_best_bleu
fi
