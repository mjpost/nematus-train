#!/usr/bin/env python
# -*- coding: utf-8 -*-
# Author: Rico Sennrich
# Distributed under MIT license

# take conll file, and bpe-segmented text, and produce factored output

import codecs
import sys
import re

from collections import namedtuple

reload(sys)
sys.setdefaultencoding('utf-8')
sys.stdin = codecs.getreader('utf-8')(sys.stdin)
sys.stdout = codecs.getwriter('utf-8')(sys.stdout)
sys.stdout.encoding = 'utf-8'

Word = namedtuple(
    'Word',
    ['number', 'word', 'factors'])

def escape_special_chars(line):
    line = line.replace('\'', '&apos;')  # xml
    line = line.replace('"', '&quot;')  # xml
    line = line.replace('[', '&#91;')  # syntax non-terminal
    line = line.replace(']', '&#93;')  # syntax non-terminal
    line = line.replace('|', '&#124;')

    return line

def read_sentences(fobj):
    sentence = []

    for line in fobj:

        line = line.replace('|', '-PIPE-')

        if line == "\n":
            yield sentence
            sentence = []
            continue

        pos,word,rest = line.split('\t', 2)
        tokens = rest.split()

        word = escape_special_chars(word)

        sentence.append(
            Word(int(pos), word, tokens))


def get_factors(sentence, idx):
    word = sentence[idx]
    return word.factors

#text file that has been preprocessed and split with BPE
bpe_file = codecs.open(sys.argv[1], 'r', 'utf-8')

#conll file with annotation of original corpus; mapping is done by index, so number of sentences and words (before BPE) must match
conll_file = open(sys.argv[2])
conll_sentences = read_sentences(conll_file)

for lineno, line in enumerate(bpe_file, 1):
  line = line.replace(u'\u200B', '')
  state = "O"
  i = 0
  sentence = conll_sentences.next()
  for word in line.split():
    try:
        factors = get_factors(sentence, i)
    except IndexError:
        sys.stderr.write('BAD LINE {}'.format(lineno))
        sys.exit(1)
    if word.endswith('@@'):
      if state == "O" or state == "E":
        state = "B"
      elif state == "B" or state == "I":
        state = "I"
    else:
      i += 1
      if state == "B" or state == "I":
        state = "E"
      else:
        state = "O"
    sys.stdout.write('|'.join([word, state] + factors) + ' ')
  sys.stdout.write('\n')
