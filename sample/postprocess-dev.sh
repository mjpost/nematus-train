#/bin/sh

. ./params.txt

sed 's/\@\@ //g' | \
$mosesdecoder/scripts/recaser/detruecase.perl
