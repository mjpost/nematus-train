#/bin/sh

. ./params.txt

sed 's/\@\@ //g' | \
$TRAIN/moses-scripts/recaser/detruecase.perl
