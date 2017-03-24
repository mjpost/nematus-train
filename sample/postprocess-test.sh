#/bin/sh

. ./params.txt

sed 's/\@\@ //g' | \
$mosesdecoder/scripts/recaser/detruecase.perl | \
$mosesdecoder/scripts/tokenizer/detokenizer.perl -l $TRG
