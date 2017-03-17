#!/bin/bash

# Returns a space-separated list of available GPU ids, e.g., "0 1".
# If an argument is passed, it will return at most that number of GPUs,
# e.g.,
#
#     $ bash get-gpus.sh 1
#     0
#
# The default maximum is 1.

max=$1
if [[ -z $max ]]; then
    max=1
fi

let thresh=max-1
seq -s' ' 0 $thresh
