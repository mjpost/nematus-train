#!/bin/bash

# Returns a space-separated list of available GPU ids, e.g., "0 1".
# If an argument is passed, it will return at most that number of GPUs,
# e.g.,
#
#     $ bash get-gpus.sh 1
#     0
#
# The default maximum is 1.

# currently ignores request for > 1
max=1

which nvidia-smi > /dev/null 2>&1
if [[ $? -ne 0 ]]; then
    echo -1
    exit
fi

export n_gpus=$(nvidia-smi -L | wc -l)
free=$(nvidia-smi | sed -e '1,/Processes/d' | tail -n+3 | head -n-1 | perl -ne 'next unless /^\|\s+(\d)\s+\d+/; $a{$1}++; for(my $i=0;$i<$ENV{"n_gpus"};$i++) { if (!defined($a{$i})) { print $i."\n"; last; }}' | tail -n 1)
if [[ -z $free ]]; then
    free=0
fi
echo $free
