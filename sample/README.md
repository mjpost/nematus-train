INSTRUCTIONS
------------

Choose a run directory and create a file named "params.txt". This is loaded by all the files in this
directory. A sample one has been provided for you. This will set top-level parameters such as the
language pair and data sets being used.

Put GPU specific commands in a file named "gpu.sh". These are shell commands that are run
prior to any GPU job (assuming "device" has been set to "gpu" in params.txt). For example,
you might need to load a Python environment or CuDNN.

The script "get-gpus.sh" should be modified to return a list of available GPUs. This is used
for NMT. For example, if you are using the Univa grid manager, you can configure it to 
make the GPU devices available as resources which are then reported in the shell:

    http://ernst.bablick.de/blog_files/how_to_schedule_gpu_resources.html

All scripts contain variables that you will need to set to run the scripts.
For processing the sample data, only paths to different toolkits need to be set.
For processing new data, more changes will be necessary.

Then, preprocess the training, dev and test data:

  ./preprocess.sh

Then, start training: on normal-size data sets, this will take about 1-2 weeks to converge.
Models are saved regularly, and you may want to interrupt this process without waiting for it to finish.

  ./train.sh

Given a model, preprocessed text can be translated thusly:

  ./translate.sh

Finally, you may want to post-process the translation output, namely merge BPE segments,
detruecase and detokenize:

  ./postprocess-test.sh < data/newsdev2016.output > data/newsdev2016.postprocessed
