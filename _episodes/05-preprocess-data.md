---
title: "Pre-processing data into HDF5 format"
teaching: 15
exercises: 10
questions:
- ""
objectives:
- ""
keypoints:
- ""
---

## Pre-process the data into HDF5 format

Next we can tokenise and convert the data to the format 
expected by ModelZoo.

This process uses the ModelZoo tools and is configured via 
a `.yaml` file.

Let's create `data_preprocess.yaml`, replacing 
`<your-home-dir>` with your home directory path:

```yaml
# data_preprocess.yaml file
setup:
  data:
    type: "local"
    source: "<your-home-dir>/finetuning_llama2/gsm8k_raw/train"
  mode: "finetuning"
  output_dir: "<your-home-dir>/finetuning_llama2/train_data"
  processes: 4

processing:
  huggingface_tokenizer: "meta-llama/Llama-2-7b-hf"
  max_seq_length: 1024

  read_hook: "cerebras.modelzoo.data_preparation.data_preprocessing.hooks:prompt_completion_text_read_hook"
  read_hook_kwargs:
    prompt_key: "prompt"
    completion_key: "completion"
```

Above we point it to the training data, specify a tokeniser 
(this time from hugging face, but I believe we could also 
point it to the local tokeniser configuration we 
downloaded?), and the data reading 'hook' which picks up 
the data we organised into prompt/completion pairs and 
saves them in the way the fine tuning code expects.
You can see the available hooks and what the one we chose 
does in `modelzoo/src/cerebras/modelzoo/data_preparation/data_preprocessing/hooks.py`.

To find a reasonable number for the maximum sequence length 
we need to look at the dataset itself.
If you followed the previous tutorials that use this 
dataset you could check the maximum length of the tokenised 
question/answers and choose a safe number, but another 
useful tool here is the `gsm8k` page on hugging face, where 
it shows the distribution of lengths of q's and a's.

We have specified only the training source and output 
directory, so we'll need to run it **again** for the 
validation data, changing those values for the second run.

```bash
cszoo data_preprocess run --config data_preprocess.yaml

# Edit the yaml file changing  source: "...train->valid" 
# and output_dir: "...train_data->valid_data" then:

cszoo data_preprocess run --config data_preprocess.yaml
```

To explore the generated h5 files we can use `h5py`, we can 
check the format, data shape, etc:

```python
import h5py, glob
# this will pick up only one of the .h5 files, if there's 
# other chunks you can specify the exact path to explore 
# those.

import h5py, glob, pathlib

home_dir = pathlib.Path.home()
f = sorted(glob.glob(f'{home_dir}/finetuning_llama2/train_data/*.h5'))[0]
with h5py.File(f,'r') as h:
    print('keys:', list(h.keys()))
    print('attrs:', dict(h.attrs))
    print('chunk data shape:', h['data'].shape)
```

The `cszoo` tool also generates a 
`finetuning_llama2/train_data/data_params.json` file with a 
lot of these parameters that will be useful for setup later.

{% include links.md %}
