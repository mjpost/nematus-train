#/bin/sh

. ./params.txt

sed 's/\@\@ //g' | \
$TRAIN/moses-scripts/recaser/detruecase.perl | \
$TRAIN/moses-scripts/tokenizer/detokenizer.perl -l $TRG
