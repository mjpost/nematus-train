#!/bin/bash

# Calls validate.sh with qsub. Adjust flags to your needs.
qsub -S /bin/bash -V -cwd -q gpu.q -l gpu=1,h_rt=4:00:00 -j y -o data/ validate.sh
