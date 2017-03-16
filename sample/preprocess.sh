#!/bin/sh

# this sample script preprocesses a sample corpus, including tokenization,
# truecasing, and subword segmentation. 
# for application to a different language pair,
# change source and target prefix, optionally the number of BPE operations,
# and the file names (currently, data/corpus and data/newsdev2016 are being processed)

# in the tokenization step, you will want to remove Romanian-specific normalization / diacritic removal,
# and you may want to add your own.
# also, you may want to learn BPE segmentations separately for each language,
# especially if they differ in their alphabet

. params.txt

# copy data over
[[ ! -d data ]] && mkdir data
(for source in $TRAINING_SOURCES; do cat $source.$SRC; done) > data/train.$SRC
(for source in $TRAINING_SOURCES; do cat $source.$TRG; done) > data/train.$TRG

(for source in $VALIDATION_SOURCES; do cat $source.$SRC; done) > data/validate.$SRC
(for source in $VALIDATION_SOURCES; do cat $source.$TRG; done) > data/validate.$TRG

# tokenize
for prefix in train validate
 do
   cat data/$prefix.$SRC | \
   $mosesdecoder/scripts/tokenizer/normalize-punctuation.perl -l $SRC | \
   $mosesdecoder/scripts/tokenizer/tokenizer.perl -a -l $SRC > data/$prefix.tok.$SRC

   cat data/$prefix.$TRG | \
   $mosesdecoder/scripts/tokenizer/normalize-punctuation.perl -l $TRG | \
   $mosesdecoder/scripts/tokenizer/tokenizer.perl -a -l $TRG > data/$prefix.tok.$TRG

 done

# clean empty and long sentences, and sentences with high source-target ratio (training corpus only)
$mosesdecoder/scripts/training/clean-corpus-n.perl data/train.tok $SRC $TRG data/train.tok.clean 1 80

# train truecaser
[[ ! -d "model" ]] && mkdir model
$mosesdecoder/scripts/recaser/train-truecaser.perl -corpus data/train.tok.clean.$SRC -model model/truecase-model.$SRC
$mosesdecoder/scripts/recaser/train-truecaser.perl -corpus data/train.tok.clean.$TRG -model model/truecase-model.$TRG

# apply truecaser (cleaned training corpus)
for prefix in train
 do
  $mosesdecoder/scripts/recaser/truecase.perl -model model/truecase-model.$SRC < data/$prefix.tok.clean.$SRC > data/$prefix.tc.$SRC
  $mosesdecoder/scripts/recaser/truecase.perl -model model/truecase-model.$TRG < data/$prefix.tok.clean.$TRG > data/$prefix.tc.$TRG
 done

# apply truecaser (dev/test files)
for prefix in validate
 do
  $mosesdecoder/scripts/recaser/truecase.perl -model model/truecase-model.$SRC < data/$prefix.tok.$SRC > data/$prefix.tc.$SRC
  $mosesdecoder/scripts/recaser/truecase.perl -model model/truecase-model.$TRG < data/$prefix.tok.$TRG > data/$prefix.tc.$TRG
 done

# train BPE
let bpe_operations=$VOCAB_SIZE-500
cat data/train.tc.$SRC data/train.tc.$TRG | $subword_nmt/learn_bpe.py -s $bpe_operations > model/$SRC$TRG.bpe

# apply BPE
for prefix in train validate
 do
  $subword_nmt/apply_bpe.py -c model/$SRC$TRG.bpe < data/$prefix.tc.$SRC > data/$prefix.bpe.$SRC
  $subword_nmt/apply_bpe.py -c model/$SRC$TRG.bpe < data/$prefix.tc.$TRG > data/$prefix.bpe.$TRG
 done

# build network dictionary
$nematus/data/build_dictionary.py data/train.bpe.$SRC data/train.bpe.$TRG
