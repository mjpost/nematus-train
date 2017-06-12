#!/usr/bin/env python

import re
import os
from os.path import basename, dirname
import sys
import argparse

parser = argparse.ArgumentParser(description='Find best models.')
parser.add_argument('-n', type=int, default=4, help='Return n-best models, sorted best to worst')
parser.add_argument('-v', default=False, action='store_true', help='Verbose (print model scores, too)')
parser.add_argument('model_dir', type=str, help='Model directory')

if __name__ == '__main__':
    args = parser.parse_args()

    scores = []
    for line in open('{}/bleu_scores.txt'.format(args.model_dir)):
        model, bleu_str = re.split(r'\s+', line.rstrip(), 1)

        try:
            _, _, score, _ = bleu_str.split(' ', 3)
            score = float(score.replace(',', ''))
        except ValueError:
            continue

        scores.append( (score, os.path.join(dirname(args.model_dir), basename(model))) )

    for i, model in enumerate(sorted(scores, cmp=lambda x,y: cmp(x[0], y[0]), reverse=True)):
        if i >= args.n:
            break

        if args.v:
            print model[0], model[1]
        else:
            print model[1]
    
    

