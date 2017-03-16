#!/bin/bash

. params.txt

# Load the GPU-specific commands if necessary
if [[ $device = "gpu" ]]; then
  echo "Loading GPU"
  . gpu.sh
fi

#model prefix
prefix=model/model.npz

dev=data/validate.bpe.$SRC
ref=data/validate.tok.$TRG

# decode
if [[ -z $AMUNMT ]] || [[ ! -x $AMUNMT/build/bin/amun ]]; then
    echo "\$AMUNMT apparently not installed, too bad --- this is going to take a while!"
    THEANO_FLAGS=mode=FAST_RUN,floatX=float32,device=$device,on_unused_input=warn python $nematus/nematus/translate.py \
        -m $prefix.dev.npz \
        -i $dev \
        -o $dev.output.dev \
        -k 12 -n -p 1
else
cat > config.yml <<EOF
# Paths are relative to config file location
relative-paths: yes

# performance settings
beam-size: 12
devices: [0]
normalize: yes
gpu-threads: 1

# scorer configuration
scorers:
  F0:
    path: model/model.npz
    type: Nematus

# scorer weights
weights:
  F0: 1.0

# vocabularies
source-vocab: data/train.bpe.$SRC.json
target-vocab: data/train.bpe.$TRG.json

bpe: model/$SRC$TRG.bpe
debpe: false
EOF

cat $dev | $AMUNMT/build/bin/amun -c config.yml > $dev.output.dev
fi

./postprocess-dev.sh < $dev.output.dev > $dev.output.postprocessed.dev

## get BLEU
BEST=`cat ${prefix}_best_bleu || echo 0`
$mosesdecoder/scripts/generic/multi-bleu.perl $ref < $dev.output.postprocessed.dev >> ${prefix}_bleu_scores
BLEU=`$mosesdecoder/scripts/generic/multi-bleu.perl $ref < $dev.output.postprocessed.dev | cut -f 3 -d ' ' | cut -f 1 -d ','`
BETTER=`echo "$BLEU > $BEST" | bc`

echo "BLEU = $BLEU"

# save model with highest BLEU
if [ "$BETTER" = "1" ]; then
  echo "new best; saving"
  echo $BLEU > ${prefix}_best_bleu
  cp ${prefix}.dev.npz ${prefix}.npz.best_bleu
fi
