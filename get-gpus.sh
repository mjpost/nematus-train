#!/bin/bash

# Returns the GPU to use. It first tries to read it from the environment variable
# SGE_HGR_gpu or SGE_HGR_gpu_card, which can be set by the Univa grid manager as
# described here:
#
# http://ernst.bablick.de/blog_files/how_to_schedule_gpu_resources.html
#
# If that's not found, it hackily queries "nvidia-smi" to find the first GPU with
# no running process.

card=-1
if [[ ! -z $SGE_HGR_gpu ]]; then
    card=$(echo $SGE_HGR_gpu | perl -pe 's/gpu//')
elif [[ ! -z $SGE_HGR_gpu_card ]]; then
    card=$(echo $SGE_HGR_gpu_card | perl -pe 's/gpu//')
elif [[ ! -z $(which nvidia-smi 2> /dev/null) ]]; then
    export n_gpus=$(nvidia-smi -L | wc -l)
    card=$(nvidia-smi | sed -e '1,/Processes/d' | tail -n+3 | head -n-1 | perl -ne 'next unless /^\|\s+(\d)\s+\d+/; $a{$1}++; for(my $i=0;$i<$ENV{"n_gpus"};$i++) { if (!defined($a{$i})) { print $i."\n"; last; }}' | tail -n 1)
fi

echo $card
