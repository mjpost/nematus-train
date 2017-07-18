#!/usr/bin/env python

import re
import os
from os.path import basename, dirname
import sys
import argparse

parser = argparse.ArgumentParser(description='Find best models.')
parser.add_argument('-n', type=int, default=4, help='Return n-best models, sorted best to worst')
parser.add_argument('-v', default=False, action='store_true', help='Verbose (print model scores, too)')
parser.add_argument('-a', default=False, action='store_true', help='All models listed, not just the ones that exist')
parser.add_argument('-l', default=False, action='store_true', help='Symlink model.best.npz to the best model')
parser.add_argument('model_dir', type=str, help='Model directory')

if __name__ == '__main__':
    args = parser.parse_args()

    scores = []
    for line in open('{}/bleu_scores.txt'.format(args.model_dir)):
        model, bleu_str = re.split(r'\s+', line.rstrip(), 1)
        path = os.path.join(args.model_dir, basename(model))

        try:
            _, _, score, _ = bleu_str.split(' ', 3)
            score = float(score.replace(',', ''))
        except ValueError:
            continue

        if args.a or os.path.exists(path):
            scores.append( (score, path) )

    for i, (score,model) in enumerate(sorted(scores, cmp=lambda x,y: cmp(x[0], y[0]), reverse=True)):
        if i == 0 and args.l:
            if os.path.lexists(os.path.join(args.model_dir, 'model.best.npz')):
                os.unlink(os.path.join(args.model_dir, 'model.best.npz'))
            os.symlink(os.path.basename(model), os.path.join(args.model_dir, 'model.best.npz'))

        if i >= args.n:
            break

        if args.v:
            print score, model
        else:
            print model
    
    

