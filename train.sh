#!/bin/bash

#$ -S /bin/bash -V -cwd -j y
#$ -l h_rt=500:00:00
#$ -q all.q

set -u

QSUB_PARAMS=""
. ./params.txt

NUMGPUS=4

# Create the qsub file
cat > nmt-$SRC-$TRG.sh <<EOF
#!/bin/bash

. ./params.txt

# Load the GPU-specific commands if necessary
if [[ "\$device" = "gpu" ]]; then
    . $TRAIN/gpu.sh
fi

hostname=\$(hostname)
echo "SGE_HGR_gpu=\$SGE_HGR_gpu"

devno=\$(\$TRAIN/free-gpu)
echo "Using device(s) \$devno on \$hostname"

# Adjust path to training data
BPE_OR_FACTOR=bpe
if [[ \$FACTORS -gt 1 ]]; then
  BPE_OR_FACTOR=factors
fi

# Build dictionary list for factored or unfactored models
DICTS="data/train.bpe.\$SRC.json"
if [[ \$FACTORS -gt 1 ]]; then
  for num in \$(seq 1 \$FACTORS); do
    DICTS+=" data/train.factors.\$num.\$SRC.json"
  done
fi
DICTS+=" data/train.bpe.\$TRG.json"

# Set dimensions for factored training
if [[ \$FACTORS -gt 1 ]]; then
  # DIMS should have been set
  if [[ -z \$DIMS ]]; then
    echo "You need to specify \$DIMS for factored training"
    exit
  fi
  DIMS="--dim_per_factor \$DIMS"
fi

[[ ! -d model ]] && mkdir model
[[ ! -d validate ]] && mkdir validate

if [[ -z \$MARIAN ]]; then
  THEANO_FLAGS=device=\$device\$devno python \$nematus/nematus/nmt.py \\
    --reload \\
    --saveFreq 10000 \\
    --dim_word 500 \\
    --dim 1000 \\
    --model model/model.npz \\
    --datasets data/train.\$BPE_OR_FACTOR.\$SRC data/train.bpe.\$TRG \
    --dictionaries \$DICTS \\
    --n_words \$VOCAB_SIZE \\
    --n_words_src \$VOCAB_SIZE \\
    --runtime \$RUNTIME \\
    --maxlen 50 \\
    --optimizer adam \\
    --batch_size \$BATCHSIZE \\
    --valid_datasets data/validate.\$BPE_OR_FACTOR.\$SRC data/validate.bpe.\$TRG \\
    --validFreq 20000 \\
    --patience 10 \\
    --external_validation_script \$TRAIN/validate-qsub.sh \\
    --dispFreq 1000 \\
    --sampleFreq 10000 \\
    --factors \$FACTORS \\
    \$DIMS
else
  \$MARIAN/build/marian \\
    --model model/model.npz \\
    -T \$TMPDIR \\
    --devices \$devno --seed 0 \\
    --train-sets data/train.bpe.{\$SRC,\$TRG} \\
    --vocabs data/train.bpe.{\$SRC,\$TRG}.json \\
    --dim-vocabs \$VOCAB_SIZE \$VOCAB_SIZE \\
    --dynamic-batching -w 3000 \\
    --layer-normalization --dropout-rnn 0.2 --dropout-src 0.1 --dropout-trg 0.1 \\
    --early-stopping 5 --moving-average \\
    --valid-freq 20000 --save-freq 20000 --disp-freq 10000 \\
    --valid-sets data/validate.bpe.{\$SRC,\$TRG} \\
    --valid-metrics cross-entropy \\
    --valid-log validate/validate.log
fi
EOF

# Run
qsub -sync y -cwd -S /bin/bash -V -j y -o nmt-$SRC-$TRG.log $QSUB_PARAMS ./nmt-$SRC-$TRG.sh

qsub ./scripts/validate-all.sh
