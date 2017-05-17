#!/usr/bin/env python
"""
Reads bleu_scores files from one or more model runs and summarizes them in a table.
"""

import os
import sys
import argparse

parser = argparse.ArgumentParser(description='Tabularize BLEU scores during training.')
parser.add_argument('-vocab-size', type=int, default=50000, help='Size of the vocabulary')
parser.add_argument('-source', type=str, required=True, help='Source language')
parser.add_argument('-target', type=str, required=True, help='Source language')
parser.add_argument('-runtime', type=int, default=0, help='How long to run for (in seconds)')
parser.add_argument('-data-dir', type=str, default='data', help='Where to find the data')
parser.add_argument('-validate-script', type=str, default='./validate.sh', help='The validation script to run')
parser.add_argument('-batch-size', type=int, default=80, help='The batch size')
