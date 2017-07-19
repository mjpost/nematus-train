#!/bin/bash

if [[ -z $2 ]]; then
    echo "Usage: test.sh MODEL CORPUS_PREFIX"
    exit 1
fi

MODEL=$1
PREFIX=$2
SCRIPTDIR=$(dirname $0)

. ./params.txt

# Use this to link the best model
# $TRAIN/best_models.py -n1 -l model -v

# Load the GPU-specific settings
. $TRAIN/gpu.sh

set -eu

[[ ! -d test ]] && mkdir test

NAME=$(basename $PREFIX)
MODELNAME=$(basename $MODEL .npz)

# prepare the corpus
in=test/$NAME.bpe.$SRC
ref=test/$NAME.bpe.$TRG
$SCRIPTDIR/prepare-corpus.sh $PREFIX $SRC $TRG test

out=test/$NAME.$MODELNAME.output
log=test/$NAME.$MODELNAME.log
bleu=$out.bleu

# quit if it's already been done
if [[ -s $out ]]; then
    wanted=$(cat $ref | wc -l)
    found=$(cat $out | wc -l)
    if [[ $wanted -eq $found ]]; then
        BLEU=`cat $bleu | cut -f 3 -d ' ' | cut -f 1 -d ','`
        echo "BLEU = $BLEU"
        exit
    fi
fi

hostname=$(hostname)
devno=$($TRAIN/free-gpu)
echo "Using device $devno on $hostname" 

VOCAB=../data/train.bpe.$SRC.json
cat > test/config.$MODELNAME.yml <<EOF
# Paths are relative to config file location
relative-paths: yes

# performance settings
beam-size: 12
normalize: yes

# scorer configuration
scorers:
  F0:
    path: ../$MODEL
    type: Nematus

# scorer weights
weights:
  F0: 1.0

# vocabularies
source-vocab: $VOCAB
target-vocab: ../data/train.bpe.$TRG.json

debpe: false
EOF

echo "Running $MARIAN/build/amun -c test/config.$MODELNAME.yml -d $devno -i $in > $out..."
$MARIAN/build/amun -c test/config.$MODELNAME.yml -d $devno -i $in --mini-batch 10 --maxi-batch 10 > $out 2> $log

lineswanted=$(cat $in | wc -l)
linesfound=$(cat $out | wc -l)
if [[ $lineswanted -ne $linesfound ]]; then
  echo "* ERROR: output file $out has only $linesfound lines (needed $lineswanted)"
  echo "* something must have gone wrong, quitting"
  exit
fi

$TRAIN/postprocess-dev.sh < $out > $out.postprocessed

## get BLEU
BEST=`cat model/best_bleu.txt 2> /dev/null || echo 0`
bleu_output=$($TRAIN/moses-scripts/generic/multi-bleu.perl -lc $ref < $out.postprocessed)
BLEU=`echo $bleu_output | cut -f 3 -d ' ' | cut -f 1 -d ','`

echo $bleu_output > $bleu
echo "BLEU = $BLEU"
