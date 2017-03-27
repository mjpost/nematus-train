#!/bin/bash

#$ -S /bin/bash -V -cwd -j y
#$ -l h_rt=168:00:00

. params.txt

maxiters=50
if [[ ! -z $1 ]]; then
    maxiters=$1
fi

echo "Running for at most $maxiters iterations..."

# Create the qsub file
cat > train-$SRC-$TRG.sh <<EOF
#!/bin/bash

. ./params.txt

# Load the GPU-specific commands if necessary
if [[ $device = "gpu" ]]; then
    . ./gpu.sh
fi

devno=\$(\$TRAIN/get-gpus.sh)
echo "Using device gpu\$devno"

THEANO_FLAGS=device=$device\$devno python config.py -runtime \$RUNTIME -vocab-size \$VOCAB_SIZE -source \$SRC -target \$TRG
EOF

iter=1
[[ ! -d logs ]] && mkdir logs
while true; do
    echo "ITERATION $iter / $maxiters"

    # Run an iteration of training lasting at most two hours. Make sure that
    # saveFreq is set low enough in config.py to save within that amount of time
    # (1000 should be sufficient though it is relatively often)
    qsub -sync y -cwd -S /bin/bash -V -l gpu=1,h_rt=$RUNTIME -j y -o logs/ ./train-$SRC-$TRG.sh

    if [[ $iter -ge $maxiters ]]; then
        echo "Quitting."
        break
    fi

    let iter=iter+1
done
