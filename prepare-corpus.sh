#!/bin/sh

#$ -cwd -S /bin/bash -V 
#$ -j y -o preprocess.log 
#$ -q all.q -l h_rt=24:00:00,num_proc=2

# This script preprocesses a sample corpus, including tokenization,
# truecasing, and subword segmentation. 


# for application to a different language pair,
# change source and target prefix, optionally the number of BPE operations,
# and the file names (currently, data/corpus and data/newsdev2016 are being processed)

# in the tokenization step, you will want to remove Romanian-specific normalization / diacritic removal,
# and you may want to add your own.
# also, you may want to learn BPE segmentations separately for each language,
# especially if they differ in their alphabet

set -eu

PREFIX=$1
SRC=$2
TRG=$3
TARGET=$4

SCRIPTDIR=$(dirname $0)
NAME=$(basename $PREFIX)

[[ ! -d $TARGET ]] && mkdir -p $TARGET
# tokenize
for ext in $SRC $TRG; do
    cat $PREFIX.$ext \
        | $SCRIPTDIR/moses-scripts/tokenizer/normalize-punctuation.perl -q -l $ext \
        | $SCRIPTDIR/moses-scripts/tokenizer/tokenizer.perl -no-escape -protected $SCRIPTDIR/moses-scripts/tokenizer/basic-protected-patterns -a -q -l $ext \
        | tee $TARGET/$NAME.tok.$ext \
        | $SCRIPTDIR/moses-scripts/recaser/truecase.perl -model model/truecase-model.$ext \
        | tee $TARGET/$NAME.tc.$ext \
        | ~/code/subword-nmt/apply_bpe.py -c model/$SRC$TRG.bpe \
        > $TARGET/$NAME.bpe.$ext &
done

wait
