import numpy
import os
import sys
import argparse

parser = argparse.ArgumentParser(description='Run Nematus training.')
parser.add_argument('-vocab-size', type=int, default=50000, help='Size of the vocabulary')
parser.add_argument('-source', type=str, required=True, help='Source language')
parser.add_argument('-target', type=str, required=True, help='Source language')
parser.add_argument('-runtime', type=int, default=0, help='How long to run for (in seconds)')
parser.add_argument('-data-dir', type=str, default='data', help='Where to find the data')
parser.add_argument('-validate-script', type=str, default='./validate.sh', help='The validation script to run')

from nematus.nmt import train

if __name__ == '__main__':
    args = parser.parse_args()

    VOCAB_SIZE = args.vocab_size
    SRC = args.source
    TRG = args.target
    DATA_DIR = args.data_dir

    validerr = train(saveto='model/model.npz',
                    reload_=True,
                    dim_word=500,
                    dim=1024,
                    n_words=VOCAB_SIZE,
                    n_words_src=VOCAB_SIZE,
                    decay_c=0.,
                    clip_c=1.,
                    lrate=0.0001,
                    optimizer='adadelta',
                    maxlen=50,
                    batch_size=80,
                    valid_batch_size=80,
                    datasets=[DATA_DIR + '/train.bpe.' + SRC, DATA_DIR + '/train.bpe.' + TRG],
                    valid_datasets=[DATA_DIR + '/validate.bpe.' + SRC, DATA_DIR + '/validate.bpe.' + TRG],
                    dictionaries=[DATA_DIR + '/train.bpe.' + SRC + '.json',DATA_DIR + '/train.bpe.' + TRG + '.json'],
                    validFreq=10000,
                    dispFreq=1000,
                    saveFreq=10000,
                    sampleFreq=10000,
                    runTime=args.runtime,
                    use_dropout=False,
                    dropout_embedding=0.2, # dropout for input embeddings (0: no dropout)
                    dropout_hidden=0.2, # dropout for hidden layers (0: no dropout)
                    dropout_source=0.1, # dropout source words (0: no dropout)
                    dropout_target=0.1, # dropout target words (0: no dropout)
                    overwrite=False,
                    external_validation_script=args.validate_script)
    print validerr
