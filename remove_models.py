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
    parser.add_argument('-k', dest='keep', type=int, default=3, 
                        help='Keep last KEEP models (default 3)')
    parser.add_argument('-m', dest='modulo', type=int, default=10000,
                        help='Keep models of iterations divisible by m (default 10000)')
    parser.add_argument('--exec', dest='dry_run', default=True, action='store_false',
                        help='Actually do the deletions.')
    parser.add_argument('model_dir', help='The model directory')
    args = parser.parse_args()

    found = []
    for file in os.listdir(args.model_dir):
        m = re.match(r'model.iter(\d+).npz$', file)
        if m is not None:
            found.append(int(m.group(1)))

    def delete_if_exists(filename):
        if os.path.exists(filename):
            if args.dry_run:
                sys.stderr.write('* would delete %s\n' % (filename))
            else:
                sys.stderr.write('* deleting %s\n' % (filename))
                os.unlink(filename)

    found.sort(reverse = True)
    for i,iter in enumerate(found):
        filename = os.path.join(args.model_dir, 'model.iter{}.npz'.format(iter))
        if i < args.keep or (args.modulo != 0 and iter % args.modulo == 0):
            sys.stderr.write('* keeping %s\n' % (filename))
        else:
            delete_if_exists(filename)
            delete_if_exists(filename + '.json')
            delete_if_exists(filename + '.progress.json')
                
    
