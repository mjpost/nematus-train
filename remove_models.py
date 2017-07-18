#!/usr/bin/env python
"""
Removes old Nematus models (dumped at iterations) according to passed parameters.

Usage:

Remove all but the last saved model:

  remove_models.py MODEL_DIR

Keep only the last five models:

  remove_models.py MODEL_DIR

"""
import os, re
import sys
import argparse

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Clean up old Nematus models.')
    parser.add_argument('-b', '--best', dest='best', type=int, default=1, 
                        help='Keep the best BEST models (default 1)')
    parser.add_argument('-l', '--last', dest='last', type=int, default=5,
                        help='Keep last KEEP models before each BEST model')
    parser.add_argument('-m', dest='modulo', type=int, default=0,
                        help='Keep all models from iterations divisible by m (default 0)')
    parser.add_argument('--exec', dest='dry_run', default=True, action='store_false',
                        help='Actually do the deletions.')
    parser.add_argument('model_dir', help='The model directory')
    args = parser.parse_args()

    def model_file_to_number(file):
        m = re.match(r'.*model.iter(\d+).npz$', file)
        if m is not None:
            return int(m.group(1))

        return None

    found = []
    bleu_scores_file = os.path.join(args.model_dir, 'bleu_scores.txt')
    if os.path.exists(bleu_scores_file):
        sys.stderr.write('Found bleu_scores.txt file, only considering scored models for deletion\n')

        for line in open(bleu_scores_file):
            model_file, _, _, score, _ = line.replace('\t', ' ').split(' ', 4)
            itno = model_file_to_number(model_file)
            score = float(score.replace(',',''))
            if itno and score > 0.0:
                found.append((itno,model_file,score))
    else:

        for file in os.listdir(args.model_dir):
            itno = model_file_to_number(file)
            if itno:
                # Use the iteration as the score
                found.append((itno,model_file,itno))

    def delete_if_exists(filename):
        if os.path.exists(filename):
            if args.dry_run:
                sys.stderr.write('* would delete %s\n' % (filename))
            else:
                sys.stderr.write('* deleting %s\n' % (filename))
                os.unlink(filename)

    # Walk through by BLEU, descending, find best 
    found.sort(key=lambda x: x[2], reverse = True)
    keep = []
    for i,(iter,filename,score) in enumerate(found):
        # Find the best models to keep
        if i < args.best or (args.modulo != 0 and iter % args.modulo == 0):
            sys.stderr.write('* keeping %s\n' % (filename))
            keep.append(filename)

    print 'BEST MODELS =', ' '.join(keep)

    # Walk through in iteration order
    found.sort(key=lambda x: x[0], reverse = False)
    window = []
    for i,(iter,filename,_) in enumerate(found):
        if filename in keep:
            keep += window
            window = []
        else:
            # Keep all the args.last models behind each best one
            window.append(filename)
            if len(window) > args.last:
                window = window[1:]

    for i,(iter,filename,_) in enumerate(found):
        if filename in keep:
           sys.stderr.write('* keeping {}\n'.format(filename)) 
        else:
            delete_if_exists(filename)
            delete_if_exists(filename + '.json')
            delete_if_exists(filename + '.progress.json')
            delete_if_exists(filename + '.gradinfo.npz')
