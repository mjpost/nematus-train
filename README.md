NEMATUS TRAINING SCRIPTS
========================
Matt Post
May 2017

The scripts in this directory were cloned from
https://github.com/rsennrich/wmt16-scripts and contain many changes and
improvements, including:

- Extraction of runtime parameters into a "params.txt" file that is loaded
  everwhere
- Integration with the "qsub" command for running in cluster environments
- Integration with AMUNMT (https://amunmt.github.io) for fast validation
  decoding (no training support for Marian yet)
- Merging the factored and unfactored scripts
- An improved format for storing the results of validation runs
- Other scripts for keeping and deleting the best models
- Works directly with nmt.py, removing config.py

INSTRUCTIONS
------------

Choose a run directory and create a file named "params.txt". This is loaded by
all the files in this directory. A sample one has been provided for you. This
will set top-level parameters such as the language pair and data sets being
used. You can customize the operations for different jobs by also copying over
all the scripts and setting the value of $TRAIN in params.txt, but these scripts
are designed to be able to be run from a shared location.

Put GPU specific commands in a file named "gpu.sh". These are shell commands
that are run prior to any GPU job (assuming "device" has been set to "gpu" in
params.txt). For example, you might need to load a Python environment or CuDNN.

The script "get-gpus.sh" should be modified to return a list of available
GPUs. This is used for NMT. For example, if you are using the Univa grid
manager, you can configure it to make the GPU devices available as resources
which are then reported in the shell:

    http://ernst.bablick.de/blog_files/how_to_schedule_gpu_resources.html

All scripts contain variables that you will need to set to run the scripts.  For
processing the sample data, only paths to different toolkits need to be set.
For processing new data, more changes will be necessary.

Then, preprocess the training, dev and test data:

  preprocess.sh

You might want to run this via qsub:

  qsub -S /bin/bash -cwd -j y -o preprocess.log -lh_rt=24:00:00,num_proc=2 scripts/preprocess.sh

Then, start training: on normal-size data sets, this will take about 1-2 weeks
to converge. Models are saved regularly, and you may want to interrupt this
process without waiting for it to finish.

  train.sh

The "train.sh" script creates a language-pair specific script train-SRC-TRG.sh
and runs that repeatedly via qsub. You can set the variable RUNTIME in
params.txt if you need this training to give up the GPU every once in a while to
give your colleagues a chance to get the GPU.

Given a model, preprocessed text can be translated thusly:

  translate.sh

Finally, you may want to post-process the translation output, namely merge BPE segments,
detruecase and detokenize:

  postprocess-test.sh < data/newsdev2016.output > data/newsdev2016.postprocessed

LICENSE
-------

The scripts are available under the MIT License.

PUBLICATIONS
------------

The Edinburgh Neural MT submission to WMT 2016 is described in:

Rico Sennrich, Barry Haddow, Alexandra Birch (2016):
    Edinburgh Neural Machine Translation Systems for WMT 16, Proc. of the First Conference on Machine Translation (WMT16). Berlin, Germany

It is based on work described in the following publications:

Dzmitry Bahdanau, Kyunghyun Cho, Yoshua Bengio (2015):
    Neural Machine Translation by Jointly Learning to Align and Translate, Proceedings of the International Conference on Learning Representations (ICLR).

Rico Sennrich, Barry Haddow, Alexandra Birch (2016):
    Neural Machine Translation of Rare Words with Subword Units. Proceedings of the 54th Annual Meeting of the Association for Computational Linguistics (ACL 2016). Berlin, Germany.

Rico Sennrich, Barry Haddow, Alexandra Birch (2016):
    Improving Neural Machine Translation Models with Monolingual Data. Proceedings of the 54th Annual Meeting of the Association for Computational Linguistics (ACL 2016). Berlin, Germany.

The use of linguistic input features (factored_sample) is described in:

Rico Sennrich, Barry Haddow (2016):
    Linguistic Input Features Improve Neural Machine Translation, Proc. of the First Conference on Machine Translation (WMT16). Berlin, Germany
