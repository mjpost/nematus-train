export CUSTOM_GCC=/home/hltcoe/kduh/opt/gcc-4.9.3
export PATH=$CUSTOM_GCC/bin:$PATH
export LD_LIBRARY_PATH=$CUSTOM_GCC/lib64:$LD_LIBRARY_PATH

source activate nematus
module load cuda80 cudnn cuda80/blas
