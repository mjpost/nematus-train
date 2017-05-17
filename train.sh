#!/bin/bash

#$ -S /bin/bash -V -cwd -j y
#$ -l h_rt=168:00:00
#$ -q all.q

set -u

QSUB_PARAMS=""
. ./params.txt

maxiters=50
echo "Running for at most $maxiters iterations..."

# Create the qsub file
cat > train-$SRC-$TRG.sh <<EOF
#!/bin/bash

. ./params.txt

# Load the GPU-specific commands if necessary
if [[ "\$device" = "gpu" ]]; then
    . $TRAIN/gpu.sh
fi

devno=\$(\$TRAIN/get-gpus.sh)
echo "Using device gpu\$devno"

# Adjust path to training data
BPE_OR_FACTOR=bpe
if [[ \$FACTORS -gt 1 ]]; then
  BPE_OR_FACTOR=factors
fi

# Build dictionary list for factored or unfactored models
DICTS="train.bpe.\$SRC.json"
if [[ \$FACTORS -gt 1 ]]; then
  for num in \$(seq 1 \$FACTORS); do
    DICTS+=" train.factors.\$num.\$SRC.json"
  done
fi
DICTS+=" train.bpe.\$TRG.json"

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
  --validFreq 10000 \\
  --patience 10 \\
  --external_validation_script \$TRAIN/validate-qsub.sh \\
  --dispFreq 1000 \\
  --sampleFreq 10000 \\
  --factors \$FACTORS \\
  \$DIMS
EOF

[[ ! -d logs ]] && mkdir logs
for iter in $(seq 1 $maxiters); do
    echo "ITERATION $iter / $maxiters"

    # Run an iteration of training lasting at most two hours. Make sure that
    # saveFreq is set low enough in config.py to save within that amount of time
    # (1000 should be sufficient though it is relatively often)
    qsub -sync y -cwd -S /bin/bash -V -l mem_free=16g,gpu=1,h_rt=$RUNTIME -j y -o logs/ $QSUB_PARAMS ./train-$SRC-$TRG.sh

    if [[ $iter -ge $maxiters ]]; then
        echo "Quitting."
        break
    fi

    let iter=iter+1
done
