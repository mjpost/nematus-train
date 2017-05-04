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

[[ ! -d model ]] && mkdir model
THEANO_FLAGS=device=\$device\$devno python \$TRAIN/config.py -runtime \$RUNTIME -vocab-size \$VOCAB_SIZE -source \$SRC -target \$TRG -validate-script \$TRAIN/validate-qsub.sh -batch-size \$BATCHSIZE -factors \$FACTORS \$DIMS
EOF

iter=1
[[ ! -d logs ]] && mkdir logs
while true; do
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
